# Overview

This is a template for management station hosted on azure cloud. Management station used to manage environment by envronment management project [pip-templates-env-master](https://github.com/pip-templates/pip-templates-env-master). 

# Usage

- Download this repository
- Copy *config.example.json* and create own config file
- Set the required values in own config file
- Run root scripts (*create_mgmt.ps1*/*destroy_mgmt.ps1*)

# Config parameters

Config variables description

| Variable | Default value | Description |
|----|----|---|
| az_region | eastus | Azure region where resources will be created |
| az_resource_group | piptemplates-stage-east-us | Azure resource group name |
| az_subscription | piptemplates-DI | Azure subscription name |
| env_name | pip-templates-stage | Name of environment |
| mgmt_deployment_name | piptemplates-mgmt-deployment | Azure management station deployment name |
| mgmt_username | piptemplatesadmin | Azure management station username. Use this for connect to instance |
| mgmt_vm_size | Standard_DS2_v2 | Azure management station virtual machine size |
| mgmt_vnet_subnet | default | Azure management station subnet name |
| mgmt_vnet_network | 10.3.0.0/29 | Azure management station virtual network ip address pool |
| mgmt_instance_keypair_name | piptemplates | MGMT station vm keypair |
| copy_project_to_mgmt_station | false | Indicate is required to copy project folder to mgmt station. Set to *true* if you have master template with all required components on your local machine"
