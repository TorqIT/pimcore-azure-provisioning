param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkDatabaseSubnetName string
param virtualNetworkDatabaseSubnetAddressSpace string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
}

resource virtualNetworkSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: virtualNetworkDatabaseSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: virtualNetworkDatabaseSubnetAddressSpace
    delegations: [
      {
        name: 'Microsoft.DBforPostgreSQL/flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
}

output subnetId string = virtualNetworkSubnet.id
