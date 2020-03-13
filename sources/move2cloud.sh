#!/bin/bash
#function to get script parameter values
get_parameter_values ()
{
    echo "Azure-Move2VNet-Tool"

	while getopts "s:t:p:l:e:r:f:" option;
	do	
		case $option in
			s) subscriptionId=$OPTARG;;
			g) resourceGroupName=$OPTARG;;
			v) vnet=$OPTARG;;
			t) tags=$OPTARG;;
            q) query=$OPTARG;;
            v) verbose=$OPTARG;;
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

#Check for existing azure resources in the RG
resources = az resources list --gresource-group $resourceGroupName --tag $tag --query $query

for r in $resources
do
    echo "Processing resource $r ..."
done
