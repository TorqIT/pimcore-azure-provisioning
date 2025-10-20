param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkAddressSpace string

param containerAppsSubnetName string
@description('Address space to allocate for the Container Apps subnet. Note that a subnet of at least /23 is required, and it must occupied exclusively by the Container Apps Environment and its Apps.')
param containerAppsSubnetAddressSpace string
param containerAppsEnvironmentUseWorkloadProfiles bool

param databaseSubnetName string
@description('Address space to allocate for the database subnet. Note that a subnet of at least /29 is required and it must be a delegated subnet occupied exclusively by the database.')
param databaseSubnetAddressSpace string

param privateEndpointsSubnetName string
@description('Address space to allocate for Private Endpoints')
param privateEndpointsSubnetAddressSpace string

param provisionN8N bool
param n8nDatabaseSubnetName string
@description('Address space to allocate for the n8n Postgres database subnet. Note that a subnet of at least /28 is required and it must be a delegated subnet occupied exclusively by the database.')
param n8nDatabaseSubnetAddressSpace string

param provisionServicesVM bool
param servicesVmSubnetName string
@description('Address space to allocate for the services VM. Note that a subnet of at least /29 is required.')
param servicesVmSubnetAddressSpace string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
  }
  // VERY IMPORTANT - the subnets property is deliberately excluded so that any subnets
  // that are not managed in the list below are untouched. Adding subnets: [] would result
  // in the existing subnets on the VNet being destroyed.
}

// SUBNETS

resource containerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: containerAppsSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: containerAppsSubnetAddressSpace
    // When using workload profiles with Container Apps requires the subnet to be delegated to Microsoft.App/environments;
    // for some reason, using a Consumption-only plan does not work with this setup
    delegations: containerAppsEnvironmentUseWorkloadProfiles ? [
      {
        name: 'Microsoft.App/environments'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ] : []
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.KeyVault'
      }
    ]
  }
}

resource databaseSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: databaseSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: databaseSubnetAddressSpace
    delegations: [
      {
        name: 'Microsoft.DBforMySQL/flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforMySQL/flexibleServers'
        }
      }
    ]
  }
}

// TODO this is a leftover of placing Private Endpoints improperly into the Container Apps subnet. This is to accommodate legacy apps
// that use this setup, but all new applications should provision a separate subnet for Private Endpoints.
resource privateEndpointsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = if (privateEndpointsSubnetName != containerAppsSubnetName) {
  name: privateEndpointsSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: privateEndpointsSubnetAddressSpace
  }
}

resource n8nDatabaseSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = if (provisionN8N) {
  name: n8nDatabaseSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: n8nDatabaseSubnetAddressSpace
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

resource servicesVmSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = if (provisionServicesVM) {
  name: servicesVmSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: servicesVmSubnetAddressSpace
  }
}
