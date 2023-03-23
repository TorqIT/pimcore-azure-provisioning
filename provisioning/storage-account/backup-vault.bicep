param location string = resourceGroup().location

@allowed([
  'LocallyRedundant'
  'GeoRedundant'
  'ZoneRedundant'
])
param vaultStorageRedundancy string = 'GeoRedundant'
param storageAccountName string

var vaultName = 'storage-account-vault-${uniqueString(resourceGroup().id)}'
var backupPolicyName = 'policy${uniqueString(resourceGroup().id)}'
var dataSourceType = 'Microsoft.Storage/storageAccounts/blobServices'
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', storageAccountName)

resource backupVault 'Microsoft.DataProtection/backupVaults@2021-01-01' = {
  name: vaultName
  location: location
  identity: {
    type: 'systemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: vaultStorageRedundancy
      }
    ]
  }

  resource backupPolicy 'backupPolicies' = {
    name: backupPolicyName
    properties: {
      policyRules: [
        {
          trigger: {
            objectType: 'ScheduleBasedTriggerContext'
            schedule: {
              repeatingTimeIntervals: [
                'P1M'
              ]
            }
            taggingCriteria: [
              {
                isDefault: true
                tagInfo: {
                  tagName: 'default'
                }
                taggingPriority: 0
              }
            ]
          }
          objectType: 'AzureBackupRule'
          dataStore: {
            dataStoreType: 'OperationalStore'
            objectType: 'AzureBackupRule' 
          }
          name: 'default'
        }
      ]
      objectType: 'BackupPolicy'
      datasourceTypes: [
        dataSourceType
      ]
    }
  }

  resource backupInstance 'backupInstances' = {
    name: storageAccountName
    properties: {
      objectType: 'BackupInstance'
      dataSourceInfo: {
        resourceID: storageAccountId
        resourceUri: storageAccountId
        resourceName: storageAccountName
        resourceLocation: location
        resourceType: 'Microsoft.Storage/storageAccounts'
        objectType: 'Datasource'
      }
      policyInfo: {
        policyId: backupPolicy.id
      }
    }
  }
}

