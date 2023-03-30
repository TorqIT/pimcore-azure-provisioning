param location string = resourceGroup().location

// These parameters are not used by the Bicep templates themselves, but by supplemental scripts
// They must be included here, however, in order for them to be allowed in parameters.json files
param subscriptionId string = subscription().id
param resourceGroupName string = resourceGroup().name
param tenantId string = tenant().tenantId

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
