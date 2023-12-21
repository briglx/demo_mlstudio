#!/bin/bash
#######################################################
# Common Services Deployment Script
# Provision common services resources including:
# - Resource group
# - Keyvault
# Params
#    --parameters  string Key-value pairs of parameters
#######################################################
CHAR_ALPHA_UPPER='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
CHAR_ALPHA_LOWER='abcdefghijklmnopqrstuvwxyz'
CHAR_NUMERIC='0123456789'
CHAR_SPECIAL='!@#$%^\&_-+'
CHAR_ALPHA_ALL="${CHAR_ALPHA_UPPER}${CHAR_ALPHA_LOWER}"
CHAR_ALPHA_NUMERIC="${CHAR_ALPHA_ALL}${CHAR_NUMERIC}"
CHAR_ALPHA_NUMERIC_SPECIAL="${CHAR_ALPHA_NUMERIC}${CHAR_SPECIAL}"

choose() { echo "${1:RANDOM%${#1}:1}" $RANDOM; }
generate_alpha(){
    choose "$CHAR_ALPHA_ALL" | sort -R | awk '{printf "%s",$1}'
}
generate_password(){
    # Generate a random password with at least one of each type of character
    # lower, upper, number, special
    # between 9 and 13 characters
    # https://stackoverflow.com/questions/26665389/random-password-generator-bash
    {
        choose "$CHAR_SPECIAL"
        choose "$CHAR_NUMERIC"
        choose "$CHAR_ALPHA_LOWER"
        choose "$CHAR_ALPHA_UPPER"
        for _i in $( seq 1 $(( 4 + RANDOM % 6 )) )
        do
            choose "$CHAR_ALPHA_NUMERIC_SPECIAL"
        done

    } | sort -R | awk '{printf "%s",$1}' | echo "$(generate_alpha)$(cat -)"
    echo ""
}
generate_username() {
    {
        for _i in $( seq 1 $(( 8 + RANDOM % 4 )) )
        do
            choose "$CHAR_ALPHA_NUMERIC"
        done

    } | sort -R | awk '{printf "%s",$1}' | echo "$(generate_alpha)$(cat -)"
    echo ""
}

main(){
  # Use $1 as randomIdentifier if passed. Otherwise generate one.
  # --parameters will override default variable value.
  echo "Provisioning common services resources"
  # variables
  iso_date_utc=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  randomIdentifier=${1:-$(( RANDOM * RANDOM ))}
  name="management"
  location="westus3"
  rg_name="rg_${name}_${location}"
  kv_name="kv-common-$randomIdentifier"
  log_name="log-common-$randomIdentifier"
  # Jumpbox values
  jumpbox=false
  vm_username=$(generate_username)
  vm_password=$(generate_password)
  vm_jumpbox_name="vm-jumpbox"
  nsg_jumpbox="nsg-${name}-jumpbox-$randomIdentifier"
  subnet=""

  # Parse arguments
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
          echo "Seed: $1"
          shift
          ;;
    esac
  done

  # Resource Group
  echo create_resource_group "$rg_name" "$location"

  # Keyvault
  echo az keyvault create --name "$kv_name" --resource-group "$rg_name" --location "$location"

#   # Log Analytics Workspace
  echo az monitor log-analytics workspace create --workspace-name "$log_name" --resource-group "$rg_name"

  # Jumpbox
   if [ "$jumpbox" = "true" ]; then
        echo Creating jumpbox
        
        if result=$(az vm create \
            --resource-group "$rg_name" \
            --name "$vm_jumpbox_name" \
            --enable-agent true \
            --enable-auto-update true \
            --enable-hibernation false \
            --enable-hotpatching false \
            --image MicrosoftWindowsDesktop:windows-11:win11-23h2-ent:22631.2861.231204  \
            --license-type Windows_Client \
            --location "$location" \
            --patch-mode AutomaticByOS \
            --size Standard_DS1_v2 \
            --zone 1 \
            --admin-password "$vm_password" \
            --admin-username "$vm_username" \
            --accelerated-networking true \
            --nsg "$nsg_jumpbox" \
            --nic-delete-option Delete \
            --public-ip-address '""' \
            --subnet "$subnet" \
            --os-disk-delete-option Delete \
            --storage-sku Premium_LRS); then

            vm_jumpbox_id=$(echo "$result" | jq -r '.id')
            echo "Created $vm_jumpbox_name with id $vm_jumpbox_id"

            # Enable auto shutdown of vm
            if result=$(az vm auto-shutdown --resource-group "$rg_name" --name "$vm_jumpbox_name" --time 0500); then
                echo "Auto shutdown enabled for $vm_jumpbox_name"
            else
                echo "Failed to enable auto shutdown for $vm_jumpbox_name"
                echo "$result"
            fi

        else
            echo "Failed to create $vm_jumpbox_name"
            echo "$result"
        fi

        # Save variables to .env
        echo "Save Azure variables to ${ENV_FILE}"
        {
            echo ""
            echo "# Script common_services_deployment output variables."
            echo "# Generated on ${iso_date_utc} for subscription ${AZURE_SUBSCRIPTION_ID}"
            echo "KEYVAULT_NAME=$kv_name"
            echo "LOG_ANALYTICS_WORKSPACE_NAME=$log_name"
            echo "JUMPBOX_NAME=$vm_jumpbox_name"
            echo "JUMPBOX_USERNAME=$vm_username"
            echo "JUMPBOX_PASSWORD=$vm_password"
        }>> "$ENV_FILE"
    fi

    # Differences between UI and AZ cli deployed VM
    # CLI
    # 	vm.storageProfile.osDisk.caching = "ReadWrite"
    # 	vm.securityProfile.SecurityType=TrustedLaunch
    # 	vm.securityProfile.uefiSettings.secureBootEnabled=true
    # 	vm.securityProfile.uefiSettings.vTpmEnabled=true
    # 	nsg.securityRules = RDP
    # UI
    # 	vm.storageProfile.osDisk.imageRefernce.version="latest"
    # 	vm.additionalCapabilities.hibernationEnabled=False

}

main "$@"