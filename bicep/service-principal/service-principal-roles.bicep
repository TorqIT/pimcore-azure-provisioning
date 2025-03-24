param servicePrincipalId string
param databaseLongTermBackups bool = false
param databaseBackupsStorageAccountName string = ''
param keyVaultName string
param keyVaultResourceGroupName string = resourceGroup().name

resource databaseBackupsStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (databaseLongTermBackups) {
  name: databaseBackupsStorageAccountName
}

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}
resource managedIdentityContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'f1a07417-d97a-45cb-824c-7a7467783830'
}
resource storageBlobContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = if (databaseLongTermBackups) {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource resourceGroupContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(servicePrincipalId, resourceGroup().id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource managedIdentityContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(managedIdentityContributorRoleDefinition.id, servicePrincipalId, resourceGroup().id)
  properties: {
    roleDefinitionId: managedIdentityContributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

module keyVaultRoleAssignment './service-principal-key-vault-role-assignment.bicep' = {
  name: 'service-principal-key-vault-role-assignment'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    servicePrincipalId: servicePrincipalId
  }
}

resource databaseBackupsStorageAccountBlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (databaseLongTermBackups) {
  scope: databaseBackupsStorageAccount
  name: guid(databaseBackupsStorageAccount.id, servicePrincipalId, storageBlobContributorRoleDefinition.id)
  properties: {
    roleDefinitionId: storageBlobContributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

