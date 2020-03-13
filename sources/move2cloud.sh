#!/bin/bash
function show_help {
    echo "Usage: ${0} -s [subscriptionId] -g [resource group name] -n [vnet name]"
    echo ""
    echo "    -s: subscriptionId"
    echo "    -g: resource group name"
    echo "    -n: vnet name"
	echo "    -t: tag (optional)"
    echo "    -q: query (optional)"
    echo "    -v: verbose (optional)"
    exit 0
}

#function to get script parameter values
get_parameter_values ()
{
    echo "Azure-Move2VNet-Tool"

	while getopts "s:g:n:t:q:v:" option;
	do	
		case $option in
			s) subscriptionId=$OPTARG;;
			g) resourceGroupName=$OPTARG;;
			n) vnet=$OPTARG;;
			t) tag=$OPTARG;;
            q) query=$OPTARG;;
            v) verbose=$OPTARG;;
			*)
				show_help
				exit 0
				;;
		esac
	done
	shift $((OPTIND -1))	

	echo "Subscription id: $subscriptionId"
	echo "Resource group name: $resourceGroupName"
	echo "VNet: $vnet"
	echo "Tag: $tag"
    echo "Query: $query"
    echo "Verbose: $verbose"
}

#get script parameter values
get_parameter_values "$@"

#set the default subscription id
az account set --subscription $subscriptionId

#check for existing RG
az group show --name $resourceGroupName 1> /dev/null

if [ $? != 0 ]; then
	echo "Resource group with name" $resourceGroupName "could not be found."
	exit 1

	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation --subscription $subscriptionId --tags ${tags[@]} environment=$environment 1> /dev/null
	)
	else
	echo "Using existing resource group..."
fi

#check if the target vnet exists
az network vnet show --name $vnet -g $resourceGroupName 1> /dev/null

if [ $? != 0 ]; then
	echo "VNET with name" $vnet "could not be found in the resource group $resourceGroupName."
	exit 1
fi


#Check for existing azure resources in the RG
if [-z "${resourceGroupName}" ]; then
resources = az resources list --resource-group $resourceGroupName --tag $tag --query $query
fi

if []; then
resources = az resources list --resource-group $resourceGroupName --tag $tag --query $query
fi

if []; then
resources = az resources list --resource-group $resourceGroupName --tag $tag --query $query
fi


for r in $resources
do

    echo "Processing resource $r ..."
done
