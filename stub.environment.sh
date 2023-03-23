#!/bin/bash

# Global parameters
export TENANT_NAME=
export TENANT_ID=
export SUBSCRIPTION_ID=
export RESOURCE_GROUP=
export LOCATION=canadacentral
export SERVICE_PRINCIPAL_NAME=

# Virtual Network
export VIRTUAL_NETWORK_NAME=
# If the virtual network exists already in a separate resource group, set that resource group here. Otherwise, set it to the same resource group as above.
export VIRTUAL_NETWORK_RESOURCE_GROUP=$RESOURCE_GROUP
export VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NAME=container-apps
export VIRTUAL_NETWORK_ADDRESS_SPACE='11.0.0.0/16'
export VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_ADDRESS_SPACE='11.0.0.0/23'
export VIRTUAL_NETWORK_DATABASE_SUBNET_NAME=database
export VIRTUAL_NETWORK_DATABASE_SUBNET_ADDRESS_SPACE='11.0.2.0/29'

# Database
export DATABASE_SERVER_NAME=
export DATABASE_ADMIN_USER=adminuser
export DATABASE_SKU_NAME=Standard_B1ms
export DATABASE_SKU_TIER=Burstable
export DATABASE_STORAGE_SIZE_GB=20
export DATABASE_BACKUP_RETENTION_DAYS=7
export DATABASE_GEO_REDUNDANT_BACKUP=false
export DATABASE_NAME=pimcore
# MySQL flexible servers seem to have some limitations in regards to location, so it may be necessary to deploy them to a different location
# from the other resources. If necessary, define that location here - otherwise, set it to the same location as defined above.
export DATABASE_LOCATION=$LOCATION

# Container Registry
export CONTAINER_REGISTRY_NAME=
export CONTAINER_REGISTRY_SKU=Basic
export PHP_FPM_IMAGE_NAME=pimcore-php-fpm
export SUPERVISORD_IMAGE_NAME=pimcore-supervisord
export REDIS_IMAGE_NAME=pimcore-redis

# Storage Account
export STORAGE_ACCOUNT_NAME=
export STORAGE_ACCOUNT_SKU=Standard_LRS
export STORAGE_ACCOUNT_KIND=StorageV2
export STORAGE_ACCOUNT_ACCESS_TIER=Hot
export STORAGE_ACCOUNT_CONTAINER_NAME=pimcore
export STORAGE_ACCOUNT_ASSETS_CONTAINER_NAME=assets
export STORAGE_ACCOUNT_BACKUP_RETENTION_DAYS=7
export STORAGE_ACCOUNT_CDN_ASSET_ACCESS=false

# Container Apps
export DEPLOY_IMAGES_TO_REGISTRY=true
export CONTAINER_APPS_ENVIRONMENT_NAME=pimcore-dev
export PHP_FPM_CONTAINER_APP_EXTERNAL=true
export PHP_FPM_CONTAINER_APP_NAME=pimcore-php-fpm-dev
export PHP_FPM_CONTAINER_APP_USE_PROBES=false
export SUPERVISORD_CONTAINER_APP_NAME=pimcore-supervisord-dev
export REDIS_CONTAINER_APP_NAME=pimcore-redis-dev
# Environment variable values for the Container Apps. This list can be expanded if your app requires more variables - just be sure
# to also add the variables to container-apps.sh and container-apps.bicep.
export APP_DEBUG=1
export APP_ENV=dev
export PIMCORE_DEV=1
export PIMCORE_ENVIRONMENT=dev
export REDIS_DB=12
export REDIS_SESSION_DB=14
