param location string = resourceGroup().location

param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param storageAccountAccessTier string

param fileShareName string
param fileShareAccessTier string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubnetName string

param containerAppsEnvironmentName string
param storageName string
@allowed(['ReadOnly', 'ReadWrite'])
param storageAccessMode string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource virtualNetworkSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    accessTier: storageAccountAccessTier
    networkAcls: {
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: virtualNetworkSubnet.id
        }
      ]
      defaultAction: 'Deny'
      bypass: 'None'
    }
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
  }

  resource fileServices 'fileServices' = {
    name: 'default'

    resource fileShare 'shares' = {
      name: fileShareName
      properties: {
        accessTier: fileShareAccessTier
      }
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}

resource storageMount 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: containerAppsEnvironment
  name: storageName
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: fileShareName
      accessMode: storageName
    }
  }
}
