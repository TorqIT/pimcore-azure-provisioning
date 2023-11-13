// Azure currently does not provide an easy way to perform long-term backups of a MySQL database, so we
// use a custom bundle https://github.com/TorqIT/pimcore-database-backup-bundle to store backups in a Storage Account.

param location string = resourceGroup().location

param name string
param sku string
param containerName string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  kind: 'StorageV2'
  location: location
  name: name
  sku: {
    name: sku
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    publicNetworkAccess: null
    accessTier: 'Cool'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }

  resource blobService 'blobServices' = {
    name: 'default'
    resource container 'containers' = {
      name: containerName
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${name}.blob.core.windows.net'
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

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${name}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-private-endpoint'
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
          name: 'privatelink-blob-core-windows-net'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}
