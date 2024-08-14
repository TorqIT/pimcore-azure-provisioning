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

var secrets = [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret]

param volumes array

resource supervisordContainerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
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
          volumeMounts: [for volume in volumes: {
            mountPath: volume.mountPath
            volumeName: volume.volumeName
          }]
        }
      ]
      volumes: [for volume in volumes: {
        mountOptions: volume.mountOptions
        name: volume.volumeName
        storageName: volume.storageName
        storageType: 'AzureFile'
      }]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
