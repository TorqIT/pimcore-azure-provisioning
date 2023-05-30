#!/bin/bash

STORAGE_ACCOUNT=$(jq -r '.parameters.storageAccountName' $1)
CONTAINER=$(jq -r '.parameters.storageAccountAssetsContainerName' $1)
KEY=$(az storage account keys list --acount-name $STORAGE_ACCOUNT | jq -r '.[0].value')

az storage blob directory download \
    --account-name $STORAGE_ACCOUNT \
    --acount-key $KEY \
    --container $CONTAINER \
    --source-path $2 \
    --destination-path $3 \
    --recursive