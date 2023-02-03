#!/bin/bash

set -e

echo Deploying storage account...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file storage-account.bicep \
  --parameters \
    storageAccountName=$STORAGE_ACCOUNT_NAME \
    sku=$STORAGE_ACCOUNT_SKU \
    kind=$STORAGE_ACCOUNT_KIND \
    accessTier=$STORAGE_ACCOUNT_ACCESS_TIER \
    containerName=$STORAGE_ACCOUNT_CONTAINER_NAME \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_SUBNET_NAME
