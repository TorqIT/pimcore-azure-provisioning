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

// TODO really don't like this
var secrets = empty(databaseBackupsStorageAccountKeySecret) ? [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret] : [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret, databaseBackupsStorageAccountKeySecret]

param volumeMounts array
param volumes array

resource supervisordContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: secrets
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
          volumeMounts: volumeMounts
        }
      ]
      volumes: volumes
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
