#!/bin/bash

set -e

CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value // empty' $1)
INIT_IMAGE_NAME=$(jq -r '.parameters.initContainerAppJobImageName.value // "init"' $1)
PHP_IMAGE_NAME=$(jq -r '.parameters.phpContainerAppImageName.value // "php"' $1)
SUPERVISORD_IMAGE_NAME=$(jq -r '.parameters.supervisordContainerAppImageName.value // "supervisord"' $1)

IMAGES=($PHP_IMAGE_NAME $SUPERVISORD_IMAGE_NAME $INIT_IMAGE_NAME)

EXISTING_REPOSITORIES=$(az acr repository list --name $CONTAINER_REGISTRY_NAME --output tsv)
if [ -z "$EXISTING_REPOSITORIES" ];
then
  # If firewall is enabled, temporarily add local IP
  if [ "$CONTAINER_REGISTRY_SKU" == "Premium" ]; then
    az acr network-rule add -n $CONTAINER_REGISTRY_NAME --ip-address $(curl ipinfo.io/ip)
  fi

  # Container Apps require images to actually be present in the Container Registry,
  # therefore we tag and push some dummy Hello World ones here.
  echo Pushing Hello World images to Container Registry...
  docker pull hello-world
  for image in "${IMAGES[@]}"
  do
    docker tag hello-world:latest $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
    docker push $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
  done
  docker logout

  # If firewall is enabled, remove local IP
  if [ "$CONTAINER_REGISTRY_SKU" == "Premium" ]; then
    az acr network-rule remove -n $CONTAINER_REGISTRY_NAME --ip-address $(curl ipinfo.io/ip)
  fi
else
  echo "Container Registry repositories already exist ($EXISTING_REPOSITORIES), so no need to push anything"
fi
