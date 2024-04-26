#!/bin/bash

set -e

az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
az account set -s "$ARM_SUBSCRIPTION_ID"
