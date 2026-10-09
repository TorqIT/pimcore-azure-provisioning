param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkDatabaseSubnetName string

param databaseServerName string
@description('Major version of PostgreSQL. For existing servers, upgrade the server first (e.g. az postgres flexible-server upgrade) and then set this to match.')
param databaseVersion string
param databaseAdminUser string
@secure()
param databaseAdminPassword string
param databaseSkuName string
param databaseSkuTier string
param databaseStorageSizeGB int
param databaseBackupRetentionDays int
param databaseName string

// Optional metric alerts provisioning
param provisionMetricAlerts bool = false
param generalMetricAlertsActionGroupName string = ''
param criticalMetricAlertsActionGroupName string = ''

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

resource databaseSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkDatabaseSubnetName
}

resource privateDNSzoneForDatabase 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${databaseServerName}.private.postgres.database.azure.com'
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'vnet-link'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }

}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' = {
  name: databaseServerName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    version: databaseVersion
    administratorLogin: databaseAdminUser
    administratorLoginPassword: databaseAdminPassword
    network: {
      delegatedSubnetResourceId: databaseSubnet.id
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

  resource serverParameters 'configurations' = {
    name: 'require_secure_transport'
    properties: {
      source: 'user-override'
      value: 'OFF'
    }
  }
}

module databaseAlerts './alerts/n8n-database-alerts.bicep' = if (provisionMetricAlerts) {
  name: 'n8n-database-alerts'
  dependsOn: [postgresDatabase]
  params: {
    databaseServerName: databaseServerName
    generalActionGroupName: generalMetricAlertsActionGroupName
    criticalActionGroupName: criticalMetricAlertsActionGroupName
  }
}
