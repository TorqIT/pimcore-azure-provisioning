param location string = resourceGroup().location

param containerAppsEnvironmentId string
param containerAppName string
param imageName string
param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param containerRegistryPasswordSecret object
param cpuCores string
param memory string

resource redisContainerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        containerRegistryPasswordSecret
      ]
      registries: [
        containerRegistryConfiguration
      ]
      ingress: {
        targetPort: 6379
        external: false
        transport: 'Tcp'
        exposedPort: 6379
      }
    }
    template: {
      containers: [
        {
          name: imageName
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
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
    }
  }
}
