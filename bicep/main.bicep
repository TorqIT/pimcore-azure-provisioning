param location string = resourceGroup().location

param containerRegistryName string

// Key Vault (assumed to have been created prior to this)
param keyVaultName string
param keyVaultResourceGroupName string = resourceGroup().name
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

// Virtual Network
param virtualNetworkName string
param virtualNetworkAddressSpace string
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkContainerAppsSubnetName string
param virtualNetworkContainerAppsSubnetAddressSpace string
param virtualNetworkDatabaseSubnetName string
param virtualNetworkDatabaseSubnetAddressSpace string
module virtualNetwork 'virtual-network/virtual-network.bicep' = if (virtualNetworkResourceGroupName == resourceGroup().name) {
  name: 'virtual-network'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    containerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    containerAppsSubnetAddressSpace:  virtualNetworkContainerAppsSubnetAddressSpace
    databaseSubnetAddressSpace: virtualNetworkDatabaseSubnetAddressSpace
    databaseSubnetName: virtualNetworkDatabaseSubnetName
  }
}

// Storage Account
param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param storageAccountAccessTier string
param storageAccountContainerName string
param storageAccountAssetsContainerName string
param storageAccountCdnAccess bool
param storageAccountBackupRetentionDays int
module storageAccount 'storage-account/storage-account.bicep' = {
  name: 'storage-account'
  dependsOn: [virtualNetwork]
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
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    shortTermBackupRetentionDays: storageAccountBackupRetentionDays
  }
}

// Database
param databaseServerName string
param databaseAdminUsername string
param databasePasswordSecretName string
param databaseSkuName string
param databaseSkuTier string
param databaseStorageSizeGB int
param databaseName string
param databaseBackupRetentionDays int
param databaseGeoRedundantBackup bool
param databaseBackupsStorageAccountName string = '${databaseServerName}-backups-storage-account'
param databaseBackupsStorageAccountContainerName string = 'database-backups'
param databaseBackupsStorageAccountSku string = 'Standard_LRS'
module database 'database/database.bicep' = {
  name: 'database'
  dependsOn: [virtualNetwork]
  params: {
    location: location
    administratorLogin: databaseAdminUsername
    administratorPassword: keyVault.getSecret(databasePasswordSecretName)
    databaseName: databaseName
    serverName: databaseServerName
    skuName: databaseSkuName
    skuTier: databaseSkuTier
    storageSizeGB: databaseStorageSizeGB
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkDatabaseSubnetName: virtualNetworkDatabaseSubnetName
    virtualNetworkContainerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    backupRetentionDays: databaseBackupRetentionDays
    geoRedundantBackup: databaseGeoRedundantBackup
    databaseBackupsStorageAccountName: databaseBackupsStorageAccountName
    databaseBackupStorageAccountContainerName: databaseBackupsStorageAccountContainerName
    databaseBackupsStorageAccountSku: databaseBackupsStorageAccountSku
    storageAccountPrivateDnsZoneId: storageAccount.outputs.privateDnsZoneId
  }
}

// Container Apps
param containerAppsEnvironmentName string
param phpFpmContainerAppExternal bool = true
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool = false
param phpFpmContainerAppCustomDomains array = []
param phpFpmCpuCores string = '1.0'
param phpFpmMemory string = '2Gi'
param phpFpmScaleToZero bool = false
param supervisordContainerAppName string
param supervisordImageName string
param supervisordCpuCores string = '0.25'
param supervisordMemory string = '250Mi'
param redisContainerAppName string
param redisImageName string
param redisCpuCores string = '0.25'
param redisMemory string = '1Gi'
@allowed(['0', '1'])
param appDebug string
param appEnv string
@allowed(['0', '1'])
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisSessionDb string
param additionalEnvVars array = []
param provisionForPortalEngine bool = false
param elasticsearchContainerAppName string = ''
param elasticsearchCpuCores string = ''
param elasticsearchMemory string = ''
param elasticsearchNodeName string = ''
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  dependsOn: [virtualNetwork, storageAccount, containerRegistry, database]
  params: {
    location: location
    additionalEnvVars: additionalEnvVars
    appDebug: appDebug
    appEnv: appEnv
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    databaseName: databaseName
    databasePassword: keyVault.getSecret(databasePasswordSecretName)
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    phpFpmContainerAppName: phpFpmContainerAppName
    phpFpmContainerAppCustomDomains: phpFpmContainerAppCustomDomains
    phpFpmImageName: phpFpmImageName
    phpFpmCpuCores: phpFpmCpuCores
    phpFpmMemory: phpFpmMemory
    phpFpmContainerAppExternal: phpFpmContainerAppExternal
    phpFpmContainerAppUseProbes: phpFpmContainerAppUseProbes
    phpFpmScaleToZero: phpFpmScaleToZero
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisContainerAppName: redisContainerAppName
    redisDb: redisDb
    redisImageName: redisImageName
    redisSessionDb: redisSessionDb
    redisCpuCores: redisCpuCores
    redisMemory: redisMemory
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    databaseBackupsStorageAccountName: databaseBackupsStorageAccountName
    databaseBackupsStorageAccountContainerName: databaseBackupsStorageAccountContainerName
    supervisordContainerAppName: supervisordContainerAppName
    supervisordImageName: supervisordImageName
    supervisordCpuCores: supervisordCpuCores
    supervisordMemory: supervisordMemory
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
    provisionForPortalEngine: provisionForPortalEngine
    elasticsearchContainerAppName: elasticsearchContainerAppName
    elasticsearchCpuCores: elasticsearchCpuCores
    elasticsearchMemory: elasticsearchMemory
    elasticsearchNodeName: elasticsearchNodeName
  }
}

// We use a single parameters.json file for multiple Bicep files and scripts, but Bicep
// will complain if we use it on a file that doesn't actually use all of the parameters.
// Therefore, we declare the extra params here.  If https://github.com/Azure/bicep/issues/5771 
// is ever fixed, these can be removed.
param subscriptionId string = ''
param resourceGroupName string = ''
param tenantName string = ''
param servicePrincipalName string = ''
param deployImagesToContainerRegistry bool = false
param additionalSecrets object = {}
param containerRegistrySku string = ''
