param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkContainerAppsSubnetName string = 'container-apps-subnet'
param virutalNetworkDatabaseSubnetAddressSpace string = 'database-subnet'
param containerRegistryName string

// Storage Account
param storageAccountName string
param storageAccountSku string = 'Standard_LRS'
param storageAccountKind string = 'StorageV2'
param storageAccountAccessTier string = 'Hot'
param storageAccountContainerName string
param storageAccountAssetsContainerName string
param storageAccountCdnAccess bool = false
module storageAccount 'storage-account/storage-account.bicep' = {
  name: 'storage-account'
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: storageAccountContainerName
    assetsContainerName: storageAccountAssetsContainerName
    accessTier: storageAccountAccessTier
    kind: storageAccountKind
    sku: storageAccountSku
    cdnAssetAccess: storageAccountCdnAccess
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
  }
}

// Database
param databaseServerName string
param databaseAdminUsername string = 'adminuser'
@secure()
param databasePassword string
param databaseSkuName string = 'Standard_B1ms'
param databaseSkuTier string = 'Burstable'
param databaseStorageSizeGB int = 20
param databaseName string = 'pimcore'
module database 'database/database.bicep' = {
  name: 'database'
  params: {
    location: location
    administratorLogin: databaseAdminUsername
    administratorPassword: databasePassword 
    databaseName: databaseName
    serverName: databaseServerName
    skuName: databaseSkuName
    skuTier: databaseSkuTier
    storageSizeGB: databaseStorageSizeGB
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virutalNetworkDatabaseSubnetAddressSpace
  }
}

// Container Apps
param containerAppsEnvironmentName string
param phpFpmContainerAppExternal bool = true
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool = false
param supervisordContainerAppName string
param supervisordImageName string
param redisContainerAppName string
param redisImageName string
@allowed(['0', '1'])
param appDebug string = '0'
param appEnv string = 'dev'
@allowed(['0', '1'])
param pimcoreDev string = '1'
param pimcoreEnvironment string = 'dev'
param redisDb string = '12'
param redisSessionDb string = '14'
param additionalEnvVars array = []
@secure()
param additionalSecrets object = {array: []}
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    location: location
    additionalSecrets: additionalSecrets
    additionalEnvVars: additionalEnvVars
    appDebug: appDebug
    appEnv: appEnv
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    databaseName: databaseName
    databasePassword: databasePassword
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    phpFpmContainerAppName: phpFpmContainerAppName
    phpFpmImageName: phpFpmImageName
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisContainerAppName: redisContainerAppName
    redisDb: redisDb
    redisImageName: redisImageName
    redisSessionDb: redisSessionDb
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    supervisordContainerAppName: supervisordContainerAppName
    supervisordImageName: supervisordImageName
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    phpFpmContainerAppExternal: phpFpmContainerAppExternal
    phpFpmContainerAppUseProbes: phpFpmContainerAppUseProbes
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
  }
}

