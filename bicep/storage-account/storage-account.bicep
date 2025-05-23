param location string = resourceGroup().location

param fullProvision bool

param storageAccountName string
param sku string
param kind string
param accessTier string
param containerName string
param assetsContainerName string

@allowed(['public', 'partial', 'private'])
param assetsContainerAccessLevel string
param firewallIps array
param cdnAssetAccess bool

param shortTermBackupRetentionDays int

param privateDnsZoneId string
param privateEndpointName string
param privateEndpointNicName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkPrivateEndpointSubnetName string

param longTermBackups bool
param backupVaultName string
param longTermBackupRetentionPeriod string

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
    accessTier: accessTier
    allowBlobPublicAccess: assetsContainerAccessLevel == 'public' || assetsContainerAccessLevel == 'partial'
    publicNetworkAccess: assetsContainerAccessLevel == 'public' || assetsContainerAccessLevel == 'partial' ? 'Enabled' : 'Disabled'
    networkAcls: {
      ipRules: [for ip in firewallIps: {value: ip}]
      defaultAction: assetsContainerAccessLevel == 'public' ? 'Allow' : 'Deny'
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

  resource blobService 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: shortTermBackupRetentionDays + 1
      }
      changeFeed: {
        enabled: true
        retentionInDays: shortTermBackupRetentionDays + 1
      }
      isVersioningEnabled: true
      restorePolicy: {
        enabled: true
        days: shortTermBackupRetentionDays
      }
    }

    resource storageAccountContainer 'containers' = {
      name: containerName
    }

    resource storageAccountContainerAssets 'containers' = {
      name: assetsContainerName
      properties: {
        publicAccess: assetsContainerAccessLevel == 'public' || assetsContainerAccessLevel == 'partial' ? 'Blob' : 'None'
      }
    }
  }
}

// We use a Private Endpoint (and Private DNS Zone) to integrate with the Virtual Network
module storageAccountPrivateEndpoint './storage-account-private-endpoint.bicep' = {
  name: 'storage-account-private-endpoint'
  dependsOn: [storageAccount]
  params: {
    location: location
    storageAccountName: storageAccountName
    privateDnsZoneId: privateDnsZoneId
    privateEndpointName: privateEndpointName
    privateEndpointNicName: privateEndpointNicName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkPrivateEndpointSubnetName
  }
}

module storageAccountBackupVault './storage-account-backup-vault.bicep' = if (fullProvision && longTermBackups) {
  name: 'storage-account-backup-vault'
  dependsOn: [storageAccount]
  params: {
    location: location
    backupVaultName: backupVaultName
    storageAccountName: storageAccountName
    containerName: containerName
    assetsContainerName: assetsContainerName
    retentionPeriod: longTermBackupRetentionPeriod
  }
}

var storageAccountDomainName = split(storageAccount.properties.primaryEndpoints.blob, '/')[2]
resource cdn 'Microsoft.Cdn/profiles@2022-11-01-preview' = if (cdnAssetAccess) {
  location: location
  name: storageAccountName
  sku: {
    name: 'Standard_Microsoft'
  }

  resource endpoint 'endpoints' = {
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
