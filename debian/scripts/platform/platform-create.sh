#!/bin/bash
set -e

# Get the directory that this script is in so the script will work regardless
# of where the user calls it from. If the scripts or its targets are moved,
# these relative paths will need to be updated.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export DIR
export PROJ
export ENV

# Login via Service Principal
echo "Logging in via Service Principal"
SPN_APP_ID=$(az keyvault secret show --vault-name "kv-dwp-cds-dev-ss" --name "prdSsDeploymentspnAppId" --query value | sed -e 's/^"//' -e 's/"$//')
SPN_CLIENT_SECRET=$(az keyvault secret show --vault-name "kv-dwp-cds-dev-ss" --name "prdSsDeploymentspnClientSecret"  --query value | sed -e 's/^"//' -e 's/"$//')
az login --service-principal -u $SPN_APP_ID -p $SPN_CLIENT_SECRET --tenant "96f1f6e9-1057-4117-ac28-80cdfe86f8c3" > /dev/null

# Set Terraform Environment Variables
export ARM_CLIENT_ID=$SPN_APP_ID
export ARM_CLIENT_SECRET=$SPN_CLIENT_SECRET
ARM_SUBSCRIPTION_ID="$(az account show --query id | sed -e 's/^"//' -e 's/"$//')"
export ARM_SUBSCRIPTION_ID
ARM_TENANT_ID="$(az account show --query tenantId | sed -e 's/^"//' -e 's/"$//')"
export ARM_TENANT_ID

# az account set --name $TF_VAR_subscription_name

# Change to the `terraform` folder 
# Benefits
# - tf state files in put in that folder since it is the working folder, avoiding conflicts with main tf state
# - the rest of the script can assume it's running in that folder
pushd "$DIR/../../terraform/$PROJ" > /dev/null

# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

#
# Argument parsing
#

function show_usage() {
    echo "platform-create.sh"
    echo
    echo "Deploy the platform"
    echo
    echo -e "\t--project\t(Optional) Select TF project to deploy'"
    echo -e "\t--subscription-name\t(Optional) The subscription name to use (defaults to devt)'"
    echo -e "\t--plan-only\t(Optional) Only perform terraform plan, not apply"
}

# Parameter defaults:
TF_VAR_subscription_name=$ENV
plan_only=false         # default to not forcing terraform apply
# Process switches:
while [[ $# -gt 0 ]]
do
    case "$1" in
        --project)
            shift 3
            ;;
        --subscription-name)
            TF_VAR_subscription_name=$2
            shift 2
            ;;
        --plan-only)
            plan_only=true
            shift 1
            ;;
        *)
            echo "Unexpected '$1'"
            show_usage
            exit 1
            ;;
    esac
done


# Pull in environment variables
# shellcheck disable=SC1091
# source "${DIR}"/local.env

figlet "Platform"

terraform init -upgrade --backend-config="./backend_config/$TF_VAR_subscription_name.conf"


workspace_exists=$(terraform workspace list | grep -qE "\s${TF_VAR_subscription_name}$"; echo $?)
if [[ "$workspace_exists" == "0" ]]; then
    terraform workspace select "${TF_VAR_subscription_name}"
else
    terraform workspace new "${TF_VAR_subscription_name}"
fi

echo "=== Performing terraform plan for $TF_VAR_subscription_name"
terraform plan -out ci_plan \
    -input=false

if [[ "$plan_only" == "true" ]]; then
    echo "=== --plan-only specified - skipping apply"
else
    echo "=== Performing terraform apply for $TF_VAR_subscription_name"
    terraform apply ci_plan
fi
