param privateDnsZonesSubscriptionId string
param privateDnsZonesResourceGroupName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

var privateDnsZoneForDatabaseName = 'privatelink.mysql.database.azure.com'
resource privateDNSzoneForDatabaseNew 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
  name: privateDnsZoneForDatabaseName
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'virtualNetworkLink'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }
}
resource privateDnsZoneForDatabaseExisting 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneForDatabaseName
  scope: resourceGroup(privateDnsZonesSubscriptionId, privateDnsZonesResourceGroupName)
}
output zoneIdForDatabase string = privateDnsZoneForDatabaseExisting.id

var privateDnsZoneForStorageAccountsName = 'privatelink.blob.${environment().suffixes.storage}'
resource privateDnsZoneForStorageAccountsNew 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
  name: privateDnsZoneForStorageAccountsName
  location: 'global'

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'vnet-link'
    location: 'global' 
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}
resource privateDnsZoneForStorageAccountsExisting 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (privateDnsZonesResourceGroupName != resourceGroup().name) {
  name: privateDnsZoneForStorageAccountsName
  scope: resourceGroup(privateDnsZonesSubscriptionId, privateDnsZonesResourceGroupName)
}
output zoneIdForStorageAccounts string = ((privateDnsZonesResourceGroupName == resourceGroup().name) ? privateDnsZoneForStorageAccountsNew.id : privateDnsZoneForStorageAccountsExisting.id)

var privateDnsZoneForContainerRegistryName = 'privatelink.azurecr.io'
resource privateDnsZoneForContainerRegistryNew 'Microsoft.Network/privateDnsZones@2020-06-01' = if (!empty(privateDnsZoneForContainerRegistryName) && privateDnsZonesResourceGroupName == resourceGroup().name) {
  name: privateDnsZoneForContainerRegistryName
  location: 'global'

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'vnet-link'
    location: 'global' 
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}
resource privateDnsZoneForContainerRegistryExisting 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(privateDnsZoneForContainerRegistryName)) {
  name: privateDnsZoneForContainerRegistryName
  scope: resourceGroup(privateDnsZonesSubscriptionId, privateDnsZonesResourceGroupName)
}
output zoneIdForContainerRegistry string = privateDnsZoneForContainerRegistryExisting.id
