#!/bin/bash

set -e

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file part1.bicep \
  --parameters @parameters.json

export DEPLOY_IMAGES_TO_CONTAINER_REGISTRY=$(jq '.parameters.deployImagesToContainerRegistry.value' parameters.json)
export CONTAINER_REGISTRY_NAME=$(jq '.parameters.containerRegistryName.value' parameters.json)
export PHP_FPM_IMAGE_NAME=$(jq '.parameters.phpFpmImageName.value' parameters.json)
export SUPERVISORD_IMAGE_NAME=$(jq '.parameters.supervisordImageName.value' parameters.json)
export REDIS_IMAGE_NAME=$(jq '.parameters.redisImageName.value' parameters.json)

./deploy-images.sh
./purge-container-registry.sh

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file part2.bicep \
  --parameters @parameters.json