#!/bin/bash
#######################################################
# Connectivity infrastructure Deployment Script
# Provision connectivity resources including:
# Core Hub:
# - Resource group, hub vnet, bastion subnet,
# - jumpbox subnet, management subnet
# - Network watcher
# Params
#    --parameters  string Key-value pairs of parameters
#######################################################

main(){
  iso_date_utc=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  echo "Provisioning connectivity resources"
  # variables
  name="core"
  location="westus3"
  jumpbox=false
  rg_name="rg_${name}_${location}"
  vnet_core_name="vnet-${name}-${location}"
  vnet_core_cidr='10.0.0.0/16'
  subnet_bastion_name=AzureBastionSubnet
  subnet_bastion_cidr='10.0.255.64/27'
  bastion_ip_name="pip-${name}-bastion"
  bastion_name="bas-${name}"
  subnet_jump_box_name=snet-jumpbox
  subnet_jump_box_cidr='10.0.0.0/29'
  subnet_firewall_name=snet-firewall
  subnet_firewall_cidr='10.0.0.8/29'
  subnet_management_name=snet-management
  subnet_management_cidr='10.0.0.64/26'

  # Parse arguments
  echo "Parsing arguments"
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --parameters)
          shift
          # Assume it's key-value pairs passed directly
          while [ -n "$1" ] && [ "${1:0:1}" != "-" ]; do
              key="${1%%=*}"
              value="${1#*=}"
              local "$key=$value"
              shift
          done
          ;;
      *)
          echo "Unknown option: $1"
          exit 1
          ;;
    esac
  done

  # Resource Group
  echo create_resource_group "$rg_name" "$location"

  # Network watcher
  echo "creating network watcher in $rg_name"
  az network watcher configure --resource-group "$rg_name" --locations "$location" --enabled

  # Core Vnet
  create_vnet "$vnet_core_name" "$rg_name" "$vnet_core_cidr"

  # Bastion
  create_subnet "$subnet_bastion_name" "$vnet_core_name" "$rg_name" "$subnet_bastion_cidr"
  echo "creating public ip $bastion_ip_name"
  az network public-ip create --resource-group "$rg_name" --name "$bastion_ip_name" --sku Standard --location "$location" --zone 1 2 3
  echo Y | az network bastion create --resource-group "$rg_name" --name "$bastion_name" --public-ip-address "$bastion_ip_name"  --vnet-name "$vnet_core_name" --location "$location"

  # Jumpbox
  if [ "$jumpbox" = "true" ]; then
    echo "Create Jumpbox subnet"
    create_subnet "$subnet_jump_box_name" "$vnet_core_name" "$rg_name" "$subnet_jump_box_cidr"
  fi

  # Firewall Subnet
  create_subnet "$subnet_firewall_name" "$vnet_core_name" "$rg_name" "$subnet_firewall_cidr"

  # Management Subnet
  create_subnet "$subnet_management_name" "$vnet_core_name" "$rg_name" "$subnet_management_cidr"

  # Save variables to .env
  echo "Save Azure variables to ${ENV_FILE}"
  {
      echo ""
      echo "# Script connectivity_core_deployment output variables."
      echo "# Generated on ${iso_date_utc} for subscription ${AZURE_SUBSCRIPTION_ID}"
      echo "BASTION_NAME=$bastion_name"
  }>> "$ENV_FILE"
}

# main --parameters location=westus3
main "$@"
