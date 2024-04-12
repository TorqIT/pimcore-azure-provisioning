param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param cpuCores string
param memory string

param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param storageAccountAccessTier string
param storageAccountFileShareName string
param storageAccountFileShareAccessTier string

param virtualNetworkName string
param virtualNetworkResourceGroupName string

resource virtualNetwork 'Microsoft.ScVmm/virtualNetworks@2023-10-07' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
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
      virtualNetworkRules: [
        {
          id: virtualNetwork.id
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
  name: 'open-search-storage-mount'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: storageAccountFileShareName
      accessMode: 'ReadWrite'
    }
  }
}

resource openSearchContainerApp 'Microsoft.App/containerApps@2023-05-02-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        targetPort: 9200
        external: false
        transport: 'tcp'
        exposedPort: 9200
      }
    }
    template: {
      containers: [
        {
          name: 'open-search'
          image: 'opensearchproject/opensearch:2'
          env: [
            {
              name: 'DISABLE_SECURITY_PLUGIN'
              value: 'true'
            }
            {
              name: 'discovery.type'
              value: 'single-node'
            }
            {
              name: 'OPENSEARCH_JAVA_OPTS'
              value: '-Xms512m -Xmx512m'
            }
          ]
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          volumeMounts: [
            {
              mountPath: '/usr/share/opensearch/data'
              volumeName: 'opensearch-volume'
            }
            
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
               concurrentRequests: '10'
              }
            }
          }
        ]
      }
      volumes: [
        {
          storageType: 'AzureFile'
          name: 'opensearch-volume'
          storageName: storageMount.name
          mountOptions: 'uid=1000,gid=1000'
        }
      ]
    }
  }
}
