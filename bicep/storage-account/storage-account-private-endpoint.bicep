param location string = resourceGroup().location

param storageAccountName string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubnetName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${storageAccountName}.blob.core.windows.net'
  location: 'global'

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'vnet-link'
    location: 'global' // Azure complains if this is not present, which is odd because it's not necessary for the database's VNet integration
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${storageAccountName}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-private-endpoint'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }

  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: '${storageAccountName}-blob-core-windows-net'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}
