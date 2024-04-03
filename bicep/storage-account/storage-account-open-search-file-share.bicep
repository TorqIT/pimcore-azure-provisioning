param name string
param accessTier string

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: name
  properties: {
    accessTier: accessTier
  }
}
