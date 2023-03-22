#!/bin/bash

set -e

echo Deploying database...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file database.bicep \
  --parameters \
    location=$DATABASE_LOCATION \
    serverName=$DATABASE_SERVER_NAME \
    administratorLogin=$DATABASE_ADMIN_USER \
    administratorLoginPassword=$DATABASE_ADMIN_PASSWORD \
    skuName=$DATABASE_SKU_NAME \
    skuTier=$DATABASE_SKU_TIER \
    storageSizeGB=$DATABASE_STORAGE_SIZE_GB \
    backupRetentionDays=$DATABASE_BACKUP_RETENTION_DAYS \
    geoRedundantBackup=$DATABASE_GEO_REDUNDANT_BACKUP \
    databaseName=$DATABASE_NAME \
    virtualNetworkResourceGroup=$VIRTUAL_NETWORK_RESOURCE_GROUP \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_DATABASE_SUBNET_NAME
