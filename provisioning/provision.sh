#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroup.value' $1)

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ../bicep/part-1.bicep \
  --parameters @$1

./deploy-images.sh $1
./purge-container-registry.sh $1

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ../bicep/part-2.bicep \
  --parameters @$1

./conatiner-apps-apply-secrets.sh $1