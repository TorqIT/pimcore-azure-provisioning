#!/bin/bash

set -e

RESOURCE_GROUP=$(jq '.parameters.resourceGroup.value' parameters.json)

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file part1.bicep \
  --parameters @parameters.json

./deploy-images.sh
./purge-container-registry.sh

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file part2.bicep \
  --parameters @parameters.json

./conatiner-apps-apply-secrets.sh