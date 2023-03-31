#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroup.value' $1)
KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./key-vault.bicep \
  --parameters \
    name=$KEY_VAULT_NAME