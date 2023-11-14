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
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  dependsOn: [privateEndpoint]

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

  resource aRecord 'A' = {
    name: storageAccountName
    properties: {
      aRecords: [
        {
          ipv4Address: privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
        }
      ]
    }
  }
}
// This DNS Zone is used by other Storage Accounts, so we output the ID
output privateDnsZoneId string = privateDnsZone.id

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

  // resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
  //   name: 'default'
  //   properties: {
  //     privateDnsZoneConfigs: [
  //       {
  //         name: 'privatelink-blob-core-windows-net'
  //         properties: {
  //           privateDnsZoneId: privateDnsZone.id
  //         }
  //       }
  //     ]
  //   }
  // }
}
