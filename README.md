# Azure - move2vnet

`move2vnet` "moves" Azure resources to a VNet.

![General move2vnet diagram](./media/Diagram.png "move2vnet diagram")

## Why?

This script answers to many real life situations.
It happens that the development of a project starts and security is not considered as it should (whatever the reason). Sometimes we are confronted to the need of having to add security afterwards.

Security implementation can take many forms.
VNet integration is one of them: simple, effective and not too intrusive.

Adding that kind of security once the design of the application as been designed (or implemented, even worse) can be a tedious work.
Furthermore, many tasks can be repetitive and mechanical.
So, why not to try to find (or build) a way to go faster and take in charge part of that work?

Let's imagine for a minute that such a tool exists.
It could also offer the possibility to add VNet integration to already existing and running applications, fast and easily.

> So, adding VNet security seamlessly to an application is the why.

## How does it work?

The script lists all the Azure resources in a given resource group.
The scripts checks whether the targeted VNet exists. If it does not exist, it is created with 3 subnets:
 - front, mainly for web sites
 - middle, mainly for APIs, Azure Functions, Service Bus, etc
 - back, mainly for storage services

For now, `move2vnet` manages a limited amount of resource types:
 - Microsoft.Web/sites 
 - Microsoft.Storage/storageAccounts
 - Microsoft.KeyVault/vaults

The appropriate and required service endpoints for each subnet are created by the script:
 - Microsoft.Web
 - Microsoft.Storage
 - Microsoft.KeyVault

> Note:
> Not all the Azure resources can be configured with a VNet.
> In addition, VNet is only available for certain SKUs.
> These constraints have be to be taken into account by yourself (not managed by the script for now).

The Azure resources are spread in the different subnets, according to their type.

### How to use move2vnet?

The current version requires 3 parameters:
 - subscriptionId
 - resource group containing the Azure resources to add VNet security to
 - the name of the VNet

Example:

`./move2vnet.sh -s "ec91c862-9472-4bb7-9c61-64727c764999" -g "move2vnettest" -n "vnetmove2vnet"`

### Traces

`move2vnet` generates traces for the main steps of the process.


