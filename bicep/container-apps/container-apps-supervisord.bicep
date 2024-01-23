param location string = resourceGroup().location

param containerAppsEnvironmentId string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param containerRegistryPasswordSecret object
param cpuCores string
param memory string
@secure()
param databasePasswordSecret object
@secure()
param storageAccountKeySecret object
@secure()
param databaseBackupsStorageAccountKeySecret object

resource supervisordContainerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret, databaseBackupsStorageAccountKeySecret]
      registries: [
        containerRegistryConfiguration
      ]
    }
    template: {
      containers: [
        {
          name: imageName
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          env: environmentVariables
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
