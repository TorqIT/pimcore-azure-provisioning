param location string = resourceGroup().location

param vaultName string
param storageAccountName string
param fileShareName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2024-10-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    redundancySettings: {
      crossRegionRestore: 'Disabled'
      standardTierStorageRedundancy: 'LocallyRedundant'
    }
  }
}

var monthsOfYear = [
  'January'
  'February'
  'March'
  'April'
  'May'
  'June'
  'July'
  'August'
  'September'
  'October'
  'November'
  'December'
]
param scheduleRunTime string = '05:30'
var scheduleRunTimes = [
  '2020-01-01T${scheduleRunTime}:00Z'
]
resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01' = {
  parent: recoveryServicesVault
  name: 'FileStorageBackupPolicy'
  properties: {
    backupManagementType: 'AzureStorage'
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 5
          durationType: 'Days'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: monthsOfYear
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 1
          durationType: 'Years'
        }
      }
    }
    workLoadType: 'AzureFileShare'
  }
}


var backupFabric = 'Azure'
var backupManagementType = 'AzureStorage'
resource protectionContainer 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2024-10-01' = {
  name: '${vaultName}/${backupFabric}/storagecontainer;Storage;${resourceGroup().name};${storageAccountName}'
  dependsOn: [
    recoveryServicesVault
    backupPolicy
  ]
  properties: {
    backupManagementType: backupManagementType
    containerType: 'StorageContainer'
    sourceResourceId: storageAccount.id
  }
  
  resource protectedItem 'protectedItems' = {
    name: 'AzureFileShare;${fileShareName}'
    properties: {
      protectedItemType: 'AzureFileShareProtectedItem'
      sourceResourceId: storageAccount.id
      policyId: backupPolicy.id
    }
  }
}
