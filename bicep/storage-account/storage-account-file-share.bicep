param storageAccountName string
param fileShareName string
param fileShareAccessTier string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'

  resource fileShare 'shares' = {
    name: fileShareName
    properties: {
      accessTier: fileShareAccessTier
    }
  }
}
