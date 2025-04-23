param location string = resourceGroup().location

@minLength(5)
@maxLength(50)
param containerRegistryName string
param sku string = ''
var validSku = empty(sku) ? 'Premium' : sku

param virtualNetworkName string = ''
param virtualNetworkResourceGroupName string = ''
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (!empty(virtualNetworkName)) {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: validSku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleSet: {
      defaultAction: 'Deny'
      virtualNetworkRules: (!empty(virtualNetworkName) && sku == 'Premium') ? [
        {
          id: virtualNetwork.id
          action: 'Allow'
        }
      ]: []
    }
  }
}
