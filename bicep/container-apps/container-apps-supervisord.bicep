param location string = resourceGroup().location

param containerAppsEnvironmentId string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param databasePasswordSecret object
@secure()
param containerRegistryPasswordSecret object
@secure()
param storageAccountKeySecret object
@secure()
param additionalSecrets object

resource supervisordContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: concat([databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret], [
        for secret in additionalSecrets
      ])
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
            cpu: 1
            memory: '2Gi'
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
