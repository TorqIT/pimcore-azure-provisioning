param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param cpuCores string
param memory string

param storageAccountName string
param storageAccountFileShareName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
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
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      volumes: [
        {
          storageType: 'AzureFile'
          name: 'opensearch-volume'
          storageName: storageMount.name
        }
      ]
    }
  }
}
