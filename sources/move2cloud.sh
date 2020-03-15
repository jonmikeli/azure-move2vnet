#!/bin/bash
function show_help {
    echo "Usage: ${0} -s [subscriptionId] -g [resource group name] -n [vnet name] -l [location]"
    echo ""
    echo "    -s: subscriptionId"
    echo "    -g: resource group name"
	echo "    -l: location"
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
			l) location=$OPTARG;;
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

#Settings reminder
	echo
	echo "Settings:"
	echo "  - Subscription id: $subscriptionId"
	echo "  - Resource group name: $resourceGroupName"
	echo "  - VNet: $vnet"
	echo "  - Tag: $tag"
    echo "  - Query: $query"
    echo "  - Verbose: $verbose"
	echo
}

#get script parameter values
get_parameter_values "$@"

#check inputs
if [ -z "${subscriptionId}" ];
then
	echo "No subscriptionId has been provided."
	exit 1
fi

if [ -z "${resourceGroupName}" ];
then
	echo "No resource group name has been provided."
	exit 1
fi

if [ -z "${vnet}" ];
then
	echo "No vnet name has been provided."
	exit 1
fi

#set the default subscription id
az account set --subscription $subscriptionId


#check for existing RG
az group show --name $resourceGroupName  1> /dev/null

if [ $? != 0 ];
then
	echo "Resource group with name" $resourceGroupName "could not be found."
	exit 1
fi

#check if the target vnet exists
az network vnet show --name $vnet -g $resourceGroupName 1> /dev/null

if [ $? != 0 ];
then
	echo "VNET with name" $vnet "could not be found in the resource group $resourceGroupName."

	echo "Creating a vnet named $vnet."

	set -e
	(
		set -x

		az network vnet create --name $vnet --resource-group $resourceGroupName 
		az network vnet subnet create --name ${vnet}subnet --vnet-name $vnet --resource-group $resourceGroupName --address-prefixes 10.0.0.0/24
	)
else
	echo "Vnet $vnet found in the $resourceGroupName."
	echo "TODO: Add tests for subnets."
fi


#Check for existing azure resources in the RG (different from the VNET)
echo
echo "Listing Azure resources to move to the vnet."
echo "  - Resource group: $resourceGroupName."
echo "  - VNet: $vnet"
echo "  - Tag: $tag"
echo "  - Query: $query"

set -e

echo
echo "Listing resources to move (raw data):"
az resource list --resource-group $resourceGroupName --query "[?name!='$vnet']"
	
if [ ! -z "${tag}" ] && [ ! -z "${query}" ]
then		
	rArray=$(az resource list --resource-group $resourceGroupName --query "[?name!='$vnet'].{Id:id,Name:name,Kind:kind,Type:type}" --out json)
elif [ ! -z "${tag}" ];
then
	rArray=$(az resource list --resource-group $resourceGroupName --query "[?name!='$vnet'].{Id:id,Name:name,Kind:kind,Type:type}" --out json)
elif [ ! -z "${query}" ];
then
	rArray=$(az resource list --resource-group $resourceGroupName --query "[?name!='$vnet'].{Id:id,Name:name,Kind:kind,Type:type}" --out json)
fi		

#https://azurecitadel.com/prereqs/cli/cli-4-bash/
echo
echo "Resources to move: ${#rArray[@]}"

#http://www.compciv.org/recipes/cli/jq-for-parsing-json/
echo
echo "Formated raw data:"
echo $rArray | jq '.'
echo
echo
echo "Formated raw data(items):"
echo $rArray | jq '.[]'
echo

#List of resource types to move to vnet
resourceTypes=(Microsoft.Web/sites Microsoft.Web/serverFarms Microsoft.Storage/storageAccounts Microsoft.KeyVault/vaults)

echo
echo "Resource types (${#resourceTypes[@]}):"
for t in ${resourceTypes[@]}
do
	echo "  - $t"
done
echo

#PROCESSING
for type in ${resourceTypes[@]}
do
	jsonArray=$(echo $rArray | jq -c --arg ty "$type" '[.[] | select( .Type == $ty )]')
	count=$(echo $jsonArray | jq length)
	tmpArray=$(echo $jsonArray | jq -c '.[]')

	echo
	echo
	echo "====================================== $type ($count) =========================================="
	echo "Count: $count"
	echo "Resources:"
	echo ${jsonArray[@]} | jq '.'
	echo

	if [ $count -gt 0 ];
	then
		
		echo "   *** MOVING RESOURCES OF TYPE $type TO VNET..."

		for tr in ${tmpArray[@]}
		do
			echo
			echo "   >>> Item:"
			echo $tr | jq '.'

			rName=$(jq -r '.Name' <<< $tr)
			echo "   >>> Name: $rName"

			rKind=$(jq -r '.Kind' <<< $tr)
			echo "   >>> Kind: $rKind"			

			case $type in
				${resourceTypes[0]})
				#Microsoft.Web/sites
					az webapp vnet-integration add -g $resourceGroupName -n $rName --vnet $vnet --subnet ${vnet}subnet
				;;
				${resourceTypes[1]})
				#Microsoft.Web/serverFarms
					echo "   >>> ==> TO BE DONE: $type"
					;;
				${resourceTypes[2]})
				#Microsoft.Storage/storageAccounts
					az storage account network-rule add -g $resourceGroupName --account-name $rName --vnet $vnet --subnet ${vnet}subnet
					;;
				${resourceTypes[3]})
				#Microsoft.KeyVault/vaults
					az keyvault network-rule add -g $resourceGroupName --name $rName --vnet-name $vnet --subnet ${vnet}subnet					
					;;
				*)
					echo "   >>> ==> TYPE NOT FOUND: $type"
					;;
			esac
			echo
		done
	else
		echo "No resources for the type $type."
	fi

	echo "====================================== -- $type -- =========================================="
done


: << 'SIMPLE_VERSION'
for r in $(echo $rArray | jq -c '.[]')
do
	echo "Item..."
	echo $r

	rName=$(jq -r '.Name' <<< $r)
	echo "Name: $rName"

	rKind=$(jq -r '.Kind' <<< $r)
	echo "Kind: $rKind"

	echo

	echo "Processing resource $rName of kind $rKind."
	case $type in
		$resourceTypes[0])
			#Microsoft.Web\sites
			echo "==========>    $resourceTypes[0]"
		;;
		$resourceTypes[1])
			#Microsoft.Web\serverFarms
			echo "==========>    $resourceTypes[1]"
		;;
		$resourceTypes[2])
			#Microsoft.Storage\storageAccounts
			echo "==========>    $resourceTypes[2]"
		;;			
	esac
	
	if [ $rKind == "StorageV2" ]
	then
		echo "Processing storage $rName"
		#az storage account network-rule add -g $resourceGroupName --account-name $rName --vnet $vnet --subnet ${vnet}subnet
	elif [ $rKind == "webapp" ]
	then
		echo "Processing webapp "
		#az webapp vnet-integration add -g gresourceGroupName -n $rName --vnet $vnet --subnet ${vnet}subnet
	else
		echo "Unnown type"
	fi
	
done
SIMPLE_VERSION



