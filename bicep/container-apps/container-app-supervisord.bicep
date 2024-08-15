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

// Optional Portal Engine provisioning
param provisionForPortalEngine bool
@secure()
param portalEngineStorageAccountKeySecret object

var defaultSecrets = [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret]
var portalEngineSecrets = provisionForPortalEngine ? [portalEngineStorageAccountKeySecret] : []
var secrets = concat(defaultSecrets, portalEngineSecrets)

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
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
