#!/bin/bash

set -e

echo "Creating Resource Group..."
resourceGroup=$(jq -r ".parameters.resourceGroupName.value" parameters.json)
location=$(jq -r ".parameters.location.value" parameters.json)
az group create --name $resourceGroup --location $location

echo "Creating Key Vault..."
./provisioning-scripts/provision-key-vault.sh parameters.json

echo "Setting required Pimcore secrets in Key Vault..."
keyVaultName=$(jq -r ".parameters.keyVaultName.value" parameters.json)
keyVaultResourceGroupName=$(jq -r --arg RESOURCE_GROUP "$resourceGroup" ".parameters.keyVaultResourceGroupName.value // \$RESOURCE_GROUP" parameters.json)
az keyvault network-rule add \
    --name $keyVaultName \
    --resource-group $keyVaultResourceGroupName \
    --ip-address $(curl ipinfo.io/ip)
az keyvault secret set \
    --vault-name $keyVaultName \
    --name "pimcore-encryption-secret" \
    --value "${{ secrets.PIMCORE_ENCRYPTION_SECRET }}"
az keyvault secret set \
    --vault-name $keyVaultName \
    --name "pimcore-product-key" \
    --value "${{ secrets.PIMCORE_PRODUCT_KEY }}"
az keyvault secret set \
    --vault-name $keyVaultName \
    --name "pimcore-instance-identifier" \
    --value "${{ secrets.PIMCORE_INSTANCE_IDENTIFIER }}"
az keyvault network-rule remove \
    --name $keyVaultName \
    --resource-group $keyVaultResourceGroupName \
    --ip-address $(curl ipinfo.io/ip)

./provision.sh parameters.json