#!/bin/bash

RESOURCE_GROUP=$(jq '.parameters.resourceGroup.value' parameters.json)
PHP_FPM_CONTAINER_APP_NAME=$(jq '.parameters.phpFpmConatinerAppName.value' parameters.json)

az containerapp exec --resource-group $RESOURCE_GROUP --name $PHP_FPM_CONTAINER_APP_NAME --command bash
