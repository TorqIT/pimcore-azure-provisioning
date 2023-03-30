#!/bin/bash

set -e

echo Setting up scheduled task to purge all but the latest 10 containers...

CONTAINER_REGISTRY_NAME=$(jq '.parameters.containerRegistryName.value' parameters.json)
PHP_FPM_IMAGE_NAME=$(jq '.parameters.phpFpmImageName.value' parameters.json)
SUPERVISORD_IMAGE_NAME=$(jq '.parameters.supervisordImageName.value' parameters.json)
REDIS_IMAGE_NAME=$(jq '.parameters.redisImageName.value' parameters.json)

CONTAINER_REGISTRY_REPOSITORIES=($PHP_FPM_IMAGE_NAME $SUPERVISORD_IMAGE_NAME $REDIS_IMAGE_NAME)

PURGE_CMD="acr purge "
for repository in ${CONTAINER_REGISTRY_REPOSITORIES[@]}
do
  PURGE_CMD="$PURGE_CMD --filter '$repository:.*'"
done
PURGE_CMD="$PURGE_CMD --ago 0d --keep 10 --untagged"
az acr task create \
  --resource-group $RESOURCE_GROUP \
  --name purgeTask \
  --cmd "$PURGE_CMD" \
  --schedule "0 0 * * *" \
  --registry $CONTAINER_REGISTRY_NAME \
  --context /dev/null