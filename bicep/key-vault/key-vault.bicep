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
    enabledForTemplateDeployment: true // allows the vault to be used by Bicep templates
    tenantId: tenant().tenantId
  }
}
