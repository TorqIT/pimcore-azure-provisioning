#!/bin/bash

TENANT_NAME=$(jq '.parameters.tenantName.value' $1)

echo Logging in to Azure tenant $TENANT_NAME...
az login --tenant $TENANT_NAME