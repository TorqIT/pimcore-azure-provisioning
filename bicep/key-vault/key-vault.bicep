param location string = resourceGroup().location

param name string

resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' = {
  location: location
  name: name
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
}
