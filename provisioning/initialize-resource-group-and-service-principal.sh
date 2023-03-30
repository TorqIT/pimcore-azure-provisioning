#!/bin/bash

set -e

export SUBSCRIPTION_ID=$(jq '.parameters.subscriptionId.value' $1)
export RESOURCE_GROUP=$(jq '.parameters.resourceGroup.value' $1)
export LOCATION=$(jq '.parameters.location.value' $1)
export $SERVICE_PRINCIPAL_NAME=$(jq '.parameters.resourceGroup.value' $1)

echo Creating resource group $RESOURCE_GROUP in $LOCATION...
az group create --location $LOCATION --name $RESOURCE_GROUP

echo Creating service principal $SERVICE_PRINCIPAL_NAME...
az ad sp create-for-rbac \
    --role Contributor \
    --scopes subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --display-name $SERVICE_PRINCIPAL_NAME