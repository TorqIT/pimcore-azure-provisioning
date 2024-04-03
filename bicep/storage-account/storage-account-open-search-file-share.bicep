param name string
param accessTier string

param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'

  resource fileShare 'shares' = {
    name: name
    properties: {
      accessTier: accessTier
    }
  }
}
