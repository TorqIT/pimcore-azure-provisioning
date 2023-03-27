param storageAccountName string
param location string = resourceGroup().location
param sku string = 'Standard_LRS'
param kind string = 'StorageV2'
param accessTier string = 'Cool'
param containerName string
param assetsContainerName string
param cdnAssetAccess bool = false

param virtualNetworkName string
param virtualNetworkResourceGroup string = resourceGroup().name
param virtualNetworkSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}
var subnetId = subnet.id

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: cdnAssetAccess
    publicNetworkAccess: cdnAssetAccess ? 'Enabled' : null
    networkAcls: {
      virtualNetworkRules: [
        {
          id: subnetId
          action: 'Allow'
        }
      ]
      defaultAction: cdnAssetAccess ? 'Allow' : 'Deny'
      bypass: 'None'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: accessTier
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: containerName
}

resource storageAccountContainerAssets 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: assetsContainerName
  properties: {
    publicAccess: cdnAssetAccess ? 'Blob' : 'None'
  }
}

var storageAccountDomainName = split(storageAccount.properties.primaryEndpoints.blob, '/')[2]
resource cdn 'Microsoft.Cdn/profiles@2022-11-01-preview' = if (cdnAssetAccess) {
  location: location
  name: storageAccountName
  sku: {
    name: 'Standard_Microsoft'
  }

  resource endpoint 'endpoints@2022-11-01-preview' = {
    location: location
    name: storageAccountName
    properties: {
      originHostHeader: storageAccountDomainName
      isHttpAllowed: false
      origins: [
        {
          name: storageAccount.name
          properties: {
            hostName: storageAccountDomainName
          } 
        }
      ]
    }
  }
}
