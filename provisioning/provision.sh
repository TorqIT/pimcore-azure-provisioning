#!/bin/bash

set -e

RESOURCE_GROUP=$(jq '.parameters.resourceGroup.value' $1)

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file part1.bicep \
  --parameters @$1

./deploy-images.sh $1
./purge-container-registry.sh $1

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file part2.bicep \
  --parameters @$1

./conatiner-apps-apply-secrets.sh $1