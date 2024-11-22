#!/bin/bash

# This script is used to check that a user is Connected to Azure CLI
# and the correct Subscription before running a local platform build.
# (This prevents builds failing halfway through due to not being able to connect when AZ CLI scripts are run.)

set -e

export SUB

subscription=$SUB

echo $subscription
context=$(az account show --query 'name' -o tsv)

if [ -z "$context" ]
then
    echo "You are not Connected Azure CLI, use (az login) to continue (https://dev.azure.com.eu2.cas.ms/dwpgovuk/ch-hds/_wiki/wikis/docs-wiki/70/Development-workflow)"
    exit 1
elif [[ "$context" != "$subscription" ]]
then
    echo "You are not Connected to the $subscription Subscription with AZ CLI, use (az account set -s [SUBSCIPTION ID]) to continue (https://dev.azure.com.eu2.cas.ms/dwpgovuk/ch-hds/_wiki/wikis/docs-wiki/70/Development-workflow)"
    exit 1
else 
    echo "Subscription $subscription already connected with AZ CLI"
fi
