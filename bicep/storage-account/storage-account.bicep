param location string = resourceGroup().location

param storageAccountName string
param sku string
param kind string
param accessTier string
param containerName string
param assetsContainerName string
param cdnAssetAccess bool
param backupRetentionDays int

param virtualNetworkName string
param virtualNetworkResourceGroup string
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
    accessTier: accessTier
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
        days: backupRetentionDays + 1
      }
      changeFeed: {
        enabled: true
        retentionInDays: backupRetentionDays + 1
      }
      isVersioningEnabled: true
      restorePolicy: {
        enabled: true
        days: backupRetentionDays
      }
    }

    resource storageAccountContainer 'containers' = {
      name: containerName
    }

    resource storageAccountContainerAssets 'containers' = {
      name: assetsContainerName
      properties: {
        publicAccess: cdnAssetAccess ? 'Blob' : 'None'
      }
    }
  }
}

resource backupVault 'Microsoft.DataProtection/backupVaults@2023-05-01' = {
  name: '${storageAccountName}-backup-vault'
  dependsOn: [storageAccount]
  location: location
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: 'LocallyRedundant'
      }
    ]
  }

  resource policy 'backupPolicies' = {
    name: 'policy'
    properties: {
      objectType: 'BackupPolicy'
      datasourceTypes: [
          'Microsoft.Storage/storageAccounts/blobServices'
      ]
      policyRules: [
        {
          name: 'Default'
          objectType: 'AzureRetentionRule'
          isDefault: true
          lifecycles: [
            {
              deleteAfter: {
                  objectType: 'AbsoluteDeleteOption'
                  duration: 'P365D'
              }
              targetDataStoreCopySettings: []
              sourceDataStore: {
                  dataStoreType: 'VaultStore'
                  objectType: 'DataStoreInfoBase'
              }
            }
          ]
        }
        {
          backupParameters: {
            objectType: 'AzureBackupParams'
            backupType: 'Discrete'
          }
          trigger: {
            objectType: 'ScheduleBasedTriggerContext'
            schedule: {
              repeatingTimeIntervals: [
                  'R/2023-07-16T21:00:00+00:00/P1W'
              ]
              timeZone: 'UTC'
            }
            taggingCriteria: [
              {
                tagInfo: {
                    tagName: 'Default'
                }
                taggingPriority: 99
                isDefault: true
              }
            ]
          }
          dataStore: {
            dataStoreType: 'VaultStore'
            objectType: 'DataStoreInfoBase'
          }
          name: 'BackupWeekly'
          objectType: 'AzureBackupRule'
        }
      ]
    }
  }

  resource instance 'backupInstances' = {
    name: 'storage-account'
    properties: {
      dataSourceInfo: {
        resourceID: storageAccount.id
        objectType: 'Datasource'
        resourceLocation: location
        datasourceType: 'Microsoft.Storage/storageAccounts/blobServices'
      }
      objectType: 'BackupInstance'
      policyInfo: {
        policyId: policy.id
      }
    }
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
