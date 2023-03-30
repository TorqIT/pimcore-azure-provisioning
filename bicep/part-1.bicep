param location string = resourceGroup().location

// Key Vault
param keyVaultName string
param keyVaultResourceGroupName string = resourceGroup().name
module keyVaultModule 'key-vault/key-vault.bicep' = if (keyVaultResourceGroupName != resourceGroup().name) {
  name: 'key-vault'
  params: {
    location: location
    name: keyVaultName
  }
}

// Virtual Network
param virtualNetworkName string
param virtualNetworkAddressSpace string
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkContainerAppsSubnetName string = 'container-apps-subnet'
param virtualNetworkContainerAppsSubnetAddressSpace string
param virtualNetworkDatabaseSubnetName string = 'database-subnet'
param virtualNetworkDatabaseSubnetAddressSpace string
module virtualNetwork 'virtual-network/virtual-network.bicep' = if (virtualNetworkResourceGroupName != resourceGroup().name) {
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

// Container Registry
param containerRegistryName string
param containerRegistrySku string = 'Basic'
module containerRegistry 'container-registry/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    location: location
    containerRegistryName: containerRegistryName
    sku: containerRegistrySku
  }
}

// Since we use a single parameters file, but multiple Bicep files, we have to declare
// all parameters here to avoid Bicep errors, even those that aren't used. 
// If https://github.com/Azure/bicep/issues/5771 is ever fixed, this can be removed.
param subscriptionId string = ''
param resourceGroupName string = ''
param tenantName string = ''
param storageAccountName string = ''
param storageAccountSku string = ''
param storageAccountKind string = ''
param storageAccountAccessTier string = ''
param storageAccountContainerName string = ''
param storageAccountAssetsContainerName string = ''
param storageAccountCdnAccess bool = false
param databaseServerName string = ''
param databaseAdminUsername string = ''
param databasePasswordSecretName string = ''
param databaseSkuName string = ''
param databaseSkuTier string = ''
param databaseStorageSizeGB int = 0
param databaseName string = ''
param containerAppsEnvironmentName string = ''
param phpFpmContainerAppExternal bool = false
param phpFpmContainerAppName string = ''
param phpFpmImageName string = ''
param phpFpmContainerAppUseProbes bool = false
param supervisordContainerAppName string = ''
param supervisordImageName string = ''
param redisContainerAppName string = ''
param redisImageName string = ''
param appDebug string = ''
param appEnv string = ''
param pimcoreDev string = ''
param pimcoreEnvironment string = ''
param redisDb string = ''
param redisSessionDb string = ''
param additionalEnvVars array = []
