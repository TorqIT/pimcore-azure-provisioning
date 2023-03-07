param location string = resourceGroup().location

param containerAppsEnvironmentName string

param virtualNetworkName string
param virtualNetworkSubnetName string

param databaseServerName string

param containerRegistryName string

param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string

param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool = false

param supervisordContainerAppName string
param supervisordImageName string

param redisContainerAppName string
param redisImageName string

// Environment variables for PHP-FPM and supervisord containers
param appDebug string
param appEnv string
param databaseName string
@secure()
param databasePassword string
param databaseUser string
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisHost string
param redisSessionDb string

param parameters string
@secure()
param secrets string

var subnetId = resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: subnetId
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
  scope: resourceGroup()
}
var containerRegistryPasswordSecret = {
  name: 'container-registry-password'
  value: containerRegistry.listCredentials().passwords[0].value
}
var containerRegistryConfiguration = {
  server: '${containerRegistryName}.azurecr.io'
  username: containerRegistry.listCredentials().username
  passwordSecretRef: 'container-registry-password'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}
var storageAccountKeySecret = {
  name: 'storage-account-key'
  value: storageAccount.listKeys().keys[0].value  
}

var databasePasswordSecret = {
  name: 'database-password'
  value: databasePassword
}

module secretsModule '../../secrets.bicep' = {
  name: 'secretsModule'
  params: {
    secrets: secrets
  }
}

var originalSecrets = [containerRegistryPasswordSecret, storageAccountKeySecret, databasePasswordSecret]
var secretsArr = secretsModule.outputs.secretsOutput
var secretsArray = !empty(secretsArr) ? concat(originalSecrets, secretsArr) : originalSecrets

module parameterModule '../../parameters.bicep' = {
  name: 'environmentVariables'
  params: {
    pimcoreEnvironment: pimcoreEnvironment
    appDebug: appDebug
    appEnv: appEnv
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    pimcoreDev: pimcoreDev
    redisDb: redisDb
    redisHost: redisHost
    redisSessionDb: redisSessionDb
    additionalVars: parameters
  }
}

var environmentVariables = parameterModule.outputs.environmentVariables

resource phpFpmContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: phpFpmContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: secretsArray
      registries: [
        containerRegistryConfiguration
      ]
      ingress: {
        external: true
        allowInsecure: false
        targetPort: 80
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: phpFpmImageName
          image: '${containerRegistryName}.azurecr.io/${phpFpmImageName}:latest'
          env: environmentVariables
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          probes: phpFpmContainerAppUseProbes ? [
            { 
              type: 'Startup'
              httpGet: {
                port: 80
                path: '/'
              }
            }
            { 
              type: 'Liveness'
              httpGet: {
                port: 80
                path: '/'
              }
            }
          ]: []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
               concurrentRequests: '30'
              }
            }
          }
        ]
      }
    }
  }
}

resource supervisordContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: supervisordContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: secretsArray
      registries: [
        containerRegistryConfiguration
      ]
    }
    template: {
      containers: [
        {
          name: supervisordImageName
          image: '${containerRegistryName}.azurecr.io/${supervisordImageName}:latest'
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

resource redisContainerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: redisContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
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
          name: redisImageName
          image: '${containerRegistryName}.azurecr.io/${redisImageName}:latest'
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
