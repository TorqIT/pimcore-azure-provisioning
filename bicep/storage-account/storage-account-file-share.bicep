param fileServicesName string
param name string
param accessTier string

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' existing = {
  name: fileServicesName
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileServices
  name: name
  properties: {
    accessTier: accessTier
  }
}
