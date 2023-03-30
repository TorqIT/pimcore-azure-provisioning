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
param virutalNetworkDatabaseSubnetAddressSpace string
module virtualNetwork 'virtual-network/virtual-network.bicep' = if (virtualNetworkResourceGroupName != resourceGroup().name) {
  name: 'virtual-network'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    containerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    containerAppsSubnetAddressSpace:  virtualNetworkContainerAppsSubnetAddressSpace
    databaseSubnetAddressSpace: virutalNetworkDatabaseSubnetAddressSpace
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
