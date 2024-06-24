param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkDatabaseSubnetName string
param virtualNetworkDatabaseSubnetAddressSpace string

param databaseServerName string
param databaseAdminUser string
@secure()
param databaseAdminPassword string
param databaseSkuName string
param databaseSkuTier string
param databaseStorageSizeGB int
param databaseBackupRetentionDays int
param databaseName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

module databaseSubnet './n8n-database-subnet.bicep' = {
  name: 'database-subnet'
  scope: resourceGroup(virtualNetworkResourceGroupName)
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkDatabaseSubnetName: virtualNetworkDatabaseSubnetName
    virtualNetworkDatabaseSubnetAddressSpace: virtualNetworkDatabaseSubnetAddressSpace
  }
}

resource privateDNSzoneForDatabase 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${databaseServerName}-postgres.database.azure.com'
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'virtualNetworkLink'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: databaseServerName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    version: '14'
    administratorLogin: databaseAdminUser
    administratorLoginPassword: databaseAdminPassword
    network: {
      delegatedSubnetResourceId: databaseSubnet.outputs.subnetId
      privateDnsZoneArmResourceId: privateDNSzoneForDatabase.id
    }
    storage: {
      storageSizeGB: databaseStorageSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }

  resource database 'databases' = {
    name: databaseName
  }
}
