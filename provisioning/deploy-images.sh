#!/bin/bash

set -e

if $DEPLOY_IMAGES_TO_CONTAINER_REGISTRY
then
  # Container Apps require images to actually be present in the Container Registry in order to complete provisioning,
  # therefore we tag and push them here. Note that this assumes the images are already built and available, and depends
  # on the image names being defined as environment variables (see README).
  # 
  # In practice, it likely makes sense to push these images on inital environment creation, but likely not on updates.
  #
  echo Pushing images to Container Registry...
  docker login --username $SERVICE_PRINCIPAL_ID --password $SERVICE_PRINCIPAL_PASSWORD $CONTAINER_REGISTRY_NAME.azurecr.io
  declare -A IMAGES=( [$LOCAL_PHP_FPM_IMAGE]=$PHP_FPM_IMAGE_NAME [$LOCAL_SUPERVISORD_IMAGE]=$SUPERVISORD_IMAGE_NAME [$LOCAL_REDIS_IMAGE]=$REDIS_IMAGE_NAME )
  for image in "${!IMAGES[@]}"
  do
    docker tag $image $CONTAINER_REGISTRY_NAME.azurecr.io/${IMAGES[$image]}:latest
    docker push $CONTAINER_REGISTRY_NAME.azurecr.io/${IMAGES[$image]}:latest
  done
  docker logout $CONTAINER_REGISTRY_NAME.azurecr.io
fi