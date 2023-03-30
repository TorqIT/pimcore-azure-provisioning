#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ../bicep/part-1.bicep \
  --parameters @$1

./deploy-images.sh $1
./purge-container-registry-task.sh $1

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ../bicep/part-2.bicep \
  --parameters @$1

./apply-container-apps-secrets.sh $1

echo "Done!"