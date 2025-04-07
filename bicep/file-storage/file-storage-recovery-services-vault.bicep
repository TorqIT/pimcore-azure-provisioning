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
  // properties object required even if empty
  properties: {
  }
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01' = {
  parent: recoveryServicesVault
  name: 'FileStorageBackupPolicy'
  properties: {
    backupManagementType: 'AzureStorage'
    vaultRetentionPolicy: {
      snapshotRetentionInDays: 30
      vaultRetention:  {
        retentionPolicyType: 'SimpleRetentionPolicy'
        retentionDuration: {
          count: 1
          durationType: 'Years'
        }
      }
    }
  }
}


var backupFabric = 'Azure'
var backupManagementType = 'AzureStorage'
resource protectionContainer 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2021-12-01' = {
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
}
resource protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-12-01'={
  name:'${split('${vaultName}/${backupFabric}/storagecontainer;Storage;${resourceGroup().name};${storageAccountName}', '/')[0]}/${split('${vaultName}/${backupFabric}/storagecontainer;Storage;${resourceGroup().name};${storageAccountName}', '/')[1]}/${split('${vaultName}/${backupFabric}/storagecontainer;Storage;${resourceGroup().name};${storageAccountName}', '/')[2]}/AzureFileShare;${fileShareName}'
  properties:{
    protectedItemType: 'AzureFileShareProtectedItem'
    sourceResourceId: storageAccount.id
    policyId: backupPolicy.id
  }
}
