#!/usr/bin/env pwsh

param
(
    [Alias("c", "Path")]
    [Parameter(Mandatory=$true, Position=0)]
    [string] $ConfigPath,
    [Alias("p")]
    [Parameter(Mandatory=$false, Position=1)]
    [string] $Prefix
)

$ErrorActionPreference = "Stop"

# Load support functions
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }
. "$($path)/../lib/include.ps1"
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

# Set azure subscription and login if needed
try {
    az account set -s $config.az_subscription
    
    if ($lastExitCode -eq 1) {
        throw "Cann't set account subscription"
    }
}
catch {
    # Make interactive az login
    az login

    az account set -s $config.az_subscription
}

# Create resource group if not exists
if (![System.Convert]::ToBoolean($(az group exists -n $config.az_resource_group))) {
    Write-Host "Resource group with name '$($config.az_resource_group)' could not be found. Creating new resource group..."
    $out = az group create --name $config.az_resource_group `
    --location $config.az_region | Out-String | ConvertFrom-Json | ConvertObjectToHashtable

    if ($out -eq $null) {
        Write-Host "Can't create resource group '$($config.az_resource_group)'"
        return
    } else {
        Write-Host "Resource group '$($config.az_resource_group)' created."
    }
} else {
    Write-Host "Using existing resource group '$($config.az_resource_group)'."
}

# Create management station virtual machine
Write-Host "Creating management station virtual machine..."

Build-EnvTemplate -InputPath "$($path)/../templates/az_vm_params.json" `
-OutputPath "$($path)/../temp/az_vm_params.json" -Params1 $config -Params2 $resources

$out = az group deployment create --name $config.mgmt_deployment_name `
--resource-group $config.az_resource_group `
--template-file "$($path)/../templates/az_vm_deploy.json" `
--parameters "$($path)/../temp/az_vm_params.json" | Out-String | ConvertFrom-Json | ConvertObjectToHashtable

if ($out -eq $null) {
    Write-Host "Can't deploy mgmt VM."
    return
} else {
    if ($LastExitCode -eq 0) {
        Write-Host "VM deployment '$($out.name)' has been successfully deployed."
    }
}

$out = az network public-ip show -g $config.az_resource_group `
-n "$($config.env_name)-mgmt-ip" | Out-String | ConvertFrom-Json | ConvertObjectToHashtable

$resources.mgmt_public_ip = $out.ipAddress

# Write resources
Write-EnvResources -Path $ConfigPath -Resources $resources

# Copy whole project to mgmt station
# Define os type by full path
if ($config.copy_project_to_mgmt_station) {
   if($IsMacOS)
    {
        # macos
        ssh "$($config.mgmt_username)@$($resources.mgmt_public_ip)" -i "$path/../config/$($config.mgmt_instance_keypair_name)" "mkdir -p /home/$($config.mgmt_username)"
        Write-Host "Copying pip-templates-envmgmt to mgmt station..."
        Set-Location "$($path)/.."
        $tmp = (Get-Item -Path ".\").FullName
        $null = scp -i "$path/../config/$($config.mgmt_instance_keypair_name)" -r $tmp "$($config.mgmt_username)@$($resources.mgmt_public_ip):/home/$($config.mgmt_username)"
        
        $tmp = "$($tmp)/config"
        $null = scp -i "$path/../config/$($config.mgmt_instance_keypair_name)" -r $tmp "$($config.mgmt_username)@$($resources.mgmt_public_ip):/home/$($config.mgmt_username)"
    }
    else {
        if ($path[0] -eq "/") {
            # ubuntu
            ssh "$($config.mgmt_username)@$($resources.mgmt_public_ip)" -i "$path/../config/$($config.mgmt_instance_keypair_name)" "mkdir -p /home/$($config.mgmt_username)"
            Write-Host "Copying pip-templates-envmgmt to mgmt station..."
            $null = scp -i "$path/../config/$($config.mgmt_instance_keypair_name)" -r "$path/.." "$($config.mgmt_username)@$($resources.mgmt_public_ip):/home/$($config.mgmt_username)"
        } else {
            # windows
            ssh "$($config.mgmt_username)@$($resources.mgmt_public_ip)" -i "$path/../config/$($config.mgmt_instance_keypair_name)" "mkdir -p /home/$($config.mgmt_username)/pip-templates-envmgmt"
            Write-Host "Copying pip-templates-envmgmt to mgmt station..."
            $null = scp -i "$path/../config/$($config.mgmt_instance_keypair_name)" -r "$path/../*" "$($config.mgmt_username)@$($resources.mgmt_public_ip):/home/$($config.mgmt_username)/pip-templates-envmgmt"
        }
    }

    # Copy this project to mgmt station with configs and resources
    Write-Host "Proceed the environment creation on mgmt station:"
    Write-Host "ssh $($config.mgmt_username)@$($resources.mgmt_public_ip) -i $path/../config/$($config.mgmt_instance_keypair_name)"
    Write-Host "cd ~/pip-templates-envmgmt" 
}
