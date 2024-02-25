param privateDnsZonesResourceGroupName string
param privateDnsZoneForDatabaseName string
param privateDnsZoneForStorageAccountsName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

resource privateDNSzoneForDatabase 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneForDatabaseName
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'virtualNetworkLink'
    location: 'global'
    properties: {
      registrationEnabled: true
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}
output zoneIdForDatabase string = privateDNSzoneForDatabase.id

resource privateDnsZoneForStorageAccounts 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
  name: privateDnsZoneForStorageAccountsName
  location: 'global'

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'virtualNetworkLink'
    location: 'global' 
    properties: {
      registrationEnabled: true
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}
output zoneIdForStorageAccounts string = privateDnsZoneForStorageAccounts.id
