#!/usr/bin/env bash
#########################################################################
# Onboard and manage application on cloud infrastructure.
# Usage: devops.sh [COMMAND]
# Globals:
#   JUMPBOX_USERNAME            (Optional) Username for jumpbox VM
#   JUMPBOX_PASSWORD            (Optional) Password for jumpbox VM
# Commands
#   provision_core_connectivity  Provision core connectivity resources.
#   provision_common             Provision common resources.
#   deploy                       Prepare the app and deploy to cloud.
#   delete                       Delete the app from cloud.
# General Params
#    -m, --message          Deployment message
#    -h, --help             Show this message and get help for a command.
#    -l, --location         Resource location. Default westus3
#    -s, --seed             Random variable to use in resource names.
#    -j                     Deploy jumpbox (Default no jumpbox)
# Params for provision common services
#    --admin-username       (optional) Admin username for jumpbox VM. Default is random name.
#    --admin-password       (optional) Admin password for jumpbox VM. Default is random password.
#########################################################################

# Stop on errors
set -e

show_help() {
    echo "$0 : Onboard and manage application on cloud infrastructure." >&2
    echo "Usage: devops.sh [COMMAND]"
    echo "Globals"
    echo "   JUMPBOX_USERNAME            (Optional) Username for jumpbox VM"
    echo "   JUMPBOX_PASSWORD            (Optional) Password for jumpbox VM"
    echo "Commands"
    echo "   provision_connectivity  Provision connectivity resources."
    echo "   provision_common        Provision common resources."
    echo "   deploy                  Prepare the app and deploy to cloud."
    echo "General Params"
    echo "   -m, --message          Deployment message"
    echo "   -l, --location         Resource location. Default westus3"
    echo "   -s, --seed             Random variable to use in resource names."
    echo "   -h, --help             Show this message and get help for a command."
    echo "   -j                     Deploy jumpbox (Default no jumpbox)"
    echo "Params for provision common services"
    echo "   --admin-username       (optional) Admin username for jumpbox VM. Default is random name."
    echo "   --admin-password       (optional) Admin password for jumpbox VM. Default is random password."
    echo
}
# show_help() {
#     echo "$0 : Create core infrastructure common to all azure deployments." >&2
#     echo "Usage: $0 [options]" >&2
#     echo "Global variables:" >&2
#     echo "  JUMPBOX_USERNAME" >&2
#     echo "  JUMPBOX_PASSWORD" >&2
#     echo
#     echo "Options:" >&2
#     echo "  -l, --location   Resource group location. Default westus3" >&2
#     echo "  -h, --help       Show help" >&2
#     echo
# }

validate_parameters(){
    # Check command
    if [ -z "$1" ]
    then
        echo "COMMAND is required" >&2
        show_help
        exit 1
    fi

    # # Check GLOBALS
    # if [ -z "$JUMPBOX_USERNAME" ]
    # then
    #     echo "JUMPBOX_USERNAME is required" >&2
    #     show_help
    #     exit 1
    # fi

    # if [ -z "$JUMPBOX_PASSWORD" ]
    # then
    #     echo "JUMPBOX_PASSWORD is required" >&2
    #     show_help
    #     exit 1
    # fi
}

provision_core_connectivity(){
    # Provision core connectivity resources.
    local deployment_name="core_connectivity.Provisioning-${run_date}"
    local location="$1"
    local jumpbox="$2"
    local rg_connectivity="rg_connectivity_${location}"
    
    additional_parameters=("message=$message")
    additional_parameters+=("rg_name=$rg_connectivity")
    additional_parameters+=("location=$location")
    if [ "$jumpbox" = "true" ]
    then
        additional_parameters+=("jumpbox=$jumpbox")
    fi

    echo "Deploying ${deployment_name} with ${additional_parameters[*]}"
 
    # shellcheck source=../iac/connectivity_core_deployment.sh
    source "${INFRA_DIRECTORY}/connectivity_core_deployment.sh" --parameters "${additional_parameters[@]}"
}

provision_common_services(){
    # Provision resources for the application.
    local deployment_name="common_services.Provisioning-${run_date}"
    local location="$1"
    local jumpbox="$2"
    local vm_username="$3"
    local vm_password="$4"

    additional_parameters=("message=$message")
    additional_parameters+=("location=$location")
    if [ -n "$vm_username" ]
    then
        additional_parameters+=("vm_username=$vm_username")
    fi
    if [ -n "$vm_password" ]
    then
        additional_parameters+=("vm_password=$vm_password")
    fi
    if [ "$jumpbox" = "true" ]
    then
        additional_parameters+=("jumpbox=$jumpbox")

        # Get vnet parameters
        rg_connectivity="rg_connectivity_${location}"
        vnet_core_name="vnet-core-${location}"
        subnet_jumpbox_name=snet-jumpbox

        if result=$(az network vnet subnet show --resource-group "$rg_connectivity"  --vnet-name "$vnet_core_name" --name "$subnet_jumpbox_name" 2>/dev/null); then
            subnet_jumpox_id=$(echo "$result" | jq -r '.id')
            additional_parameters+=("subnet=$subnet_jumpox_id")
        else
            echo "Warning! $subnet_jumpbox_name not found for jumbox."
            # exit 1
        fi
    fi

    echo "Deploying ${deployment_name} with ${additional_parameters[*]}"

    # shellcheck source=/home/brlamore/src/azure_subscription_boilerplate/iac/common_services_deployment.sh
    source "${INFRA_DIRECTORY}/common_services_deployment.sh" "$seed" --parameters "${additional_parameters[@]}"
}

# Globals
PROJ_ROOT_PATH=$(cd "$(dirname "$0")"/..; pwd)
SCRIPT_DIRECTORY="${PROJ_ROOT_PATH}/script"
INFRA_DIRECTORY="${PROJ_ROOT_PATH}/iac"
ENV_FILE="${PROJ_ROOT_PATH}/.env"

# shellcheck source=common.sh
source "${SCRIPT_DIRECTORY}/common.sh"

# Argument/Options
LONGOPTS=message:,resource-group:,location:,seed:,admin-username:,admin-password:,help
OPTIONS=m:g:l:s:jh

# Variables
message=""
seed=$(( RANDOM * RANDOM ))
location="westus3"
jumpbox="false"
admin_username="${JUMPBOX_USERNAME}"
admin_password="${JUMPBOX_PASSWORD}"
run_date=$(date +%Y%m%dT%H%M%S)

# Parse arguments
TEMP=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
eval set -- "$TEMP"
unset TEMP
while true; do
    case "$1" in
        -h|--help)
            show_help
            exit
            ;;
        -m|--message)
            message="$2"
            shift 2
            ;;
        -l|--location)
            location="$2"
            shift 2
            ;;
        -s|--seed)
            seed="$2"
            shift 2
            ;;
        -j|--jumpbox)
            jumpbox="true"
            shift
            ;;
        --admin-username)
            admin_username="$2"
            shift 2
            ;;
        --admin-password)
            admin_password="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown parameters."
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$admin_username" ]
then
    echo "no admin-username" >&2
fi

validate_parameters "$@"
command=$1

case "$command" in
    create_sp)
        create_sp
        exit 0
        ;;
    provision_core_connectivity)
        provision_core_connectivity "$location" "$jumpbox"
        exit 0
        ;;
    provision_common_services)
        provision_common_services "$location" "$jumpbox" "$admin_username" "$admin_password"
        exit 0
        ;;
    delete)
        delete
        exit 0
        ;;
    deploy)
        deploy
        exit 0
        ;;
    update_env)
        update_environment_variables
        exit 0
        ;;
    *)
        echo "Unknown command."
        show_help
        exit 1
        ;;
esac
