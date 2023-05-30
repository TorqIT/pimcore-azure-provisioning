#!/bin/bash

# Usage: ./download-assets.sh <path to parameters.json file> <destination path>
# If you run this from within a container, you can copy the results to your host OS by exiting the container and running `docker cp -r <destination path on host OS> <container name>:<path inside container>`

STORAGE_ACCOUNT=$(jq -r '.parameters.storageAccountName' $1)
CONTAINER=$(jq -r '.parameters.storageAccountAssetsContainerName' $1)
KEY=$(az storage account keys list --acount-name $STORAGE_ACCOUNT | jq -r '.[0].value')

az storage blob directory download \
    --account-name $STORAGE_ACCOUNT \
    --acount-key $KEY \
    --container $CONTAINER \
    --source-path assets \
    --destination-path $2 \
    --recursive