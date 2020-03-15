# Azure - move2vnet

This script "moves" Azure resources to a VNet.
See below to understand the rules applied to such an operation.

## Why?

This script answers to many real life needs.
It happens that the development of a project starts and security is not considered (whatever will be the reason). Security can take many forms.
When possible, VNet is a simple and effective way to add security.

Adding that kind of security afterwords can be tedious work.
So, why not to try to find some helpers or accelerators?

So, this is the why.

## How does it work?

The script lists all the Azure resources in a given resource group.
The scripts checks if the targeted VNet exists. If it does not exist, it is created with 3 subnets:
 - front, mainly for web sites
 - middle, mainly for APIs, Azure Functions, Service Bus, etc
 - back, mainly for storage services

The script manages a limite amount of service types.
The appropriate and required service endpoints for each subnet are created by the script.

> Note:
> Not all Azure resources can be configured with a VNet.
> Furthermore, VNet is only available for certain SKUs.
> These constraints have be to be taken into account by yourself (not managed by the script for now).

The resource types covered for now are:
 - Microsoft.Web/sites 
 - Microsoft.Storage/storageAccounts
 - Microsoft.KeyVault/vaults

The Azure resources are spread in the different subnets, according to their service type.

### Examples

``` ./move2cloud.sh -s "ec91c862-9472-4bb7-9c61-64727c764999" -g "move2vnettest" -n "vnetmove2vnet"