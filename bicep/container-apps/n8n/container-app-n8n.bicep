param location string = resourceGroup().location

param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param storageAccountAccessTier string
param storageAccountFileShareAccessTier string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubnetName string

param containerAppsEnvironmentName string

param n8nContainerAppName string
param n8nContainerAppCpuCores string
param n8nContainerAppMemory string
param n8nContainerAppMinReplicas int
param n8nContainerAppMaxReplicas int
param n8nContainerAppCustomDomains array

var n8nData = 'n8n-data'
var storageAccountFileShareName = n8nData
var containerAppsEnvironmentStorageMountName = n8nData
var n8nContainerAppVolumeName = n8nData

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource virtualNetworkSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    accessTier: storageAccountAccessTier
    networkAcls: {
      // Container App volume mounts do not currently work with Private Endpoints, so we use a firewall instead
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: virtualNetworkSubnet.id
        }
      ]
      defaultAction: 'Deny'
      bypass: 'None'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource fileServices 'fileServices' = {
    name: 'default'

    resource fileShare 'shares' = {
      name: storageAccountFileShareName
      properties: {
        accessTier: storageAccountFileShareAccessTier
      }
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}

resource storageMount 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: containerAppsEnvironment
  name: containerAppsEnvironmentStorageMountName
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: storageAccountFileShareName
      accessMode: 'ReadWrite'
    }
  }
}

resource certificates 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' existing = [for customDomain in n8nContainerAppCustomDomains: {
  parent: containerAppsEnvironment
  name: customDomain.certificateName
}]

resource n8nContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: n8nContainerAppName
  dependsOn: [storageMount]
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        allowInsecure: false
        targetPort: 5678
        customDomains: [for i in range(0, length(n8nContainerAppCustomDomains)): {
            name: n8nContainerAppCustomDomains[i].domainName
            bindingType: 'SniEnabled'
            certificateId: certificates[i].id
        }]
      }
    }
    template: {
      containers: [
        {
          name: 'n8n'
          image: 'n8nio/n8n:latest'
          resources: {
            cpu: json(n8nContainerAppCpuCores)
            memory: n8nContainerAppMemory
          }
          volumeMounts: [
            {
              mountPath: '/home/node/.n8n'
              volumeName: n8nContainerAppVolumeName
            }
          ]
        }
      ]
      volumes: [
        {
          name: n8nContainerAppVolumeName
          storageName: containerAppsEnvironmentStorageMountName
          storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: n8nContainerAppMinReplicas
        maxReplicas: n8nContainerAppMaxReplicas
      }
    }
  }
}

