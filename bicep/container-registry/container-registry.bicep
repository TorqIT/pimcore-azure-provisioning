param location string = resourceGroup().location

@minLength(5)
@maxLength(50)
param containerRegistryName string
param sku string
param firewallIps array

param virtualNetworkName string = ''
param virtualNetworkResourceGroupName string = ''
param virtualNetworkSubnetName string = ''
param privateEndpointName string = ''
param privateEndpointNicName string = ''
param privateDnsZoneSubscriptionId string = ''
param privateDnsZoneResourceGroupName string = ''

var ipRules = [for ip in firewallIps: {
  value: ip
  action: 'Allow'
}]

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: !empty(sku) ? sku : 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: sku == 'Premium' ? 'Enabled' : null
    networkRuleSet: sku == 'Premium' ? {
      defaultAction: 'Deny'
      ipRules: ipRules
    }: {}
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = if (!empty(virtualNetworkName)) {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = if (!empty(virtualNetworkName)) {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (!empty(virtualNetworkName) && sku == 'Premium') {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${containerRegistryName}-private-endpoint'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: ['registry']
        }
      }
    ]
    customNetworkInterfaceName: !empty(privateEndpointNicName) ? privateEndpointNicName : null
  }

  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'privatelink-azurecr-io'
          properties: {
            privateDnsZoneId: resourceId(privateDnsZoneSubscriptionId, privateDnsZoneResourceGroupName, 'privatelink.azurecr.io')
          }
        }
      ]
    }
  }
}
