#!/bin/bash

set -e

export SUBSCRIPTION_ID=$(jq '.parameters.subscriptionId.value' parameters.json)
export RESOURCE_GROUP=$(jq '.parameters.resourceGroup.value' parameters.json)
export LOCATION=$(jq '.parameters.location.value' parameters.json)
export $SERVICE_PRINCIPAL_NAME=$(jq '.parameters.resourceGroup.value' parameters.json)

echo Creating resource group $RESOURCE_GROUP in $LOCATION...
az group create --location $LOCATION --name $RESOURCE_GROUP

echo Creating service principal $SERVICE_PRINCIPAL_NAME...
az ad sp create-for-rbac \
    --role Contributor \
    --scopes subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --display-name $SERVICE_PRINCIPAL_NAME