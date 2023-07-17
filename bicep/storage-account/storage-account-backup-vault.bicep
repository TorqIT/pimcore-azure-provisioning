param storageAccountName string
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}

resource backupVault 'Microsoft.DataProtection/backupVaults@2023-05-01' = {
  name: '${storageAccountName}-backup-vault'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: 'LocallyRedundant'
      }
    ]
    securitySettings: {
      softDeleteSettings: {
        state: 'Off'
      }
    }
  }
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1' // Storage Account Backup Contributor
}

resource backupVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  dependsOn: [backupVault]
  name: guid(resourceGroup().id, roleDefinition.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: backupVault.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource policy 'Microsoft.DataProtection/backupVaults/backupPolicies@2023-05-01' = {
  parent: backupVault
  name: 'storage-account-backup-policy'
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
        name: 'BackupMonthly'
        objectType: 'AzureBackupRule'
        backupParameters: {
          objectType: 'AzureBackupParams'
          backupType: 'Discrete'
        }
        trigger: {
          objectType: 'ScheduleBasedTriggerContext'
          schedule: {
            repeatingTimeIntervals: [
                'R/2023-07-01T00:00:00+00:00/P1M'
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
      }
    ]
  }
}

resource instance 'Microsoft.DataProtection/backupVaults/backupInstances@2023-05-01' = {
  parent: backupVault
  name: 'storage-account-backup-instance'
  dependsOn: [backupVaultRoleAssignment]
  properties: {
    identityDetails: {
      useSystemAssignedIdentity: true
    }
    friendlyName: 'storage-account'
    objectType: 'BackupInstance'
    dataSourceInfo: {
      resourceName: storageAccount.name
      resourceID: storageAccount.id
      objectType: 'Datasource'
      resourceLocation: location
      datasourceType: 'Microsoft.Storage/storageAccounts/blobServices'
    }
    policyInfo: {
      policyId: policy.id
    }
  }
}
