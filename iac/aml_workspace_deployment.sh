#!/bin/bash
# #######################################################
# Azure Machine Learning Workspace Deployment Script
# Provision Azure Machine Learning Workspace
# Params
#    --parameters  string Key-value pairs of parameters
# #######################################################

main(){
    echo "Provisioning Azure Machine Learning Workspace"
    # variables
    name="aml"
    location="westus3"
    rg_name="rg_${name}_${location}"
    # workspace_name="ws-${name}-${location}"
    # storage_name="st${name}${location}"


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

    # $schema: https://azuremlschemas.azureedge.net/latest/workspace.schema.json
    # name: "$workspace_name"
    # location: "$location"
    # display_name: Private Workspace example
    # description: This configuration specifies a workspace configuration with existing dependent resources and a private endpoint.
    # image_build_compute: cpu-compute
    # public_network_access: Disabled
    # storage_account: /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT>
    # container_registry: /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.ContainerRegistry/registries/<CONTAINER_REGISTRY>
    # key_vault: /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.KeyVault/vaults/<KEY_VAULT>
    # application_insights: /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.insights/components/<APP_INSIGHTS>
    # tags:
    #   purpose: demonstration

    # Workspace
    echo "creating workspace in $rg_name"
    az ml workspace create --resource-group "$rg_name" --file workspace.yml

    # Create private link endpoint
    # az network private-endpoint create --name <private-endpoint-name> --vnet-name <vnet-name> --subnet <subnet-name> --private-connection-resource-id "/subscriptions/<subscription>/resourceGroups/<resource-group-name>/providers/Microsoft.MachineLearningServices/workspaces/<workspace-name>" --group-id amlworkspace --connection-name workspace -l <location>

}

main "$@"
