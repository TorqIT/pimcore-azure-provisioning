param location string = resourceGroup().location

param containerAppsEnvironmentName string

param virtualNetworkName string
param virtualNetworkResourceGroup string = resourceGroup().name
param virtualNetworkSubnetName string

param databaseServerName string

param containerRegistryName string

param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string

param phpFpmContainerAppExternal bool = true
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}
var subnetId = subnet.id
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    vnetConfiguration: {
      internal: phpFpmContainerAppExternal
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

var databaseHost = '${databaseServerName}.mysql.database.azure.com'

// Common environment variable configuration shared by the PHP-FPM and supervisord containers
var environmentVariables = [
  {
    name: 'APP_DEBUG'
    value: appDebug
  }
  {
    name: 'APP_ENV'
    value: appEnv
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_CONTAINER'
    value: storageAccountContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_CONTAINER_ASSETS'
    value: storageAccountAssetsContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: 'storage-account-key'
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'DATABASE_HOST'
    value: databaseHost
  }
  {
    name: 'DATABASE_NAME'
    value: databaseName
  }
  {
    name: 'DATABASE_PASSWORD'
    secretRef: 'database-password'
  }
  {
    name: 'DATABASE_USER'
    value: databaseUser
  }
  {
    name: 'PIMCORE_DEV'
    value: pimcoreDev
  }
  {
    name: 'PIMCORE_ENVIRONMENT'
    value: pimcoreEnvironment
  }
  {
    name: 'REDIS_DB'
    value: redisDb
  }
  {
    name: 'REDIS_HOST'
    value: redisHost
  }
  {
    name: 'REDIS_SESSION_DB'
    value: redisSessionDb
  }
]

resource phpFpmContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: phpFpmContainerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [
        containerRegistryPasswordSecret
        databasePasswordSecret
        storageAccountKeySecret
      ]
      registries: [
        containerRegistryConfiguration
      ]
      ingress: {
        // Slightly confusing - when we want to restrict access to this container to within the VNet, 
        // the environment (declared above) can be set to be internal within the VNet, but the webapp itself
        // still needs to be declared external here. Declaring it internal here would limit it to within the Container
        // Apps Environment, which is not what we want.
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
      secrets: [
        containerRegistryPasswordSecret
        databasePasswordSecret
        storageAccountKeySecret
      ]
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
