#!/bin/bash

TENANT_NAME=$(jq '.parameters.tenantName.value' parameters.json)

echo Logging in to Azure tenant $TENANT_NAME...
az login --tenant $TENANT_NAME