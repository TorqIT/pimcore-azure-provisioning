param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param containerRegistryConfiguration object
param customDomains array
param cpuCores string
param memory string
param useProbes bool
param scaleToZero bool
param maxReplicas int
@secure()
param databasePasswordSecret object
@secure()
param containerRegistryPasswordSecret object
@secure()
param storageAccountKeySecret object
@secure()
param databaseBackupsStorageAccountKeySecret object

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource certificates 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' existing = [for customDomain in customDomains: {
  parent: containerAppsEnvironment
  name: customDomain.certificateName
}]

resource phpFpmContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [databasePasswordSecret, containerRegistryPasswordSecret, storageAccountKeySecret, databaseBackupsStorageAccountKeySecret]
      registries: [
        containerRegistryConfiguration
      ]
      ingress: {
        // Slightly confusing - when we want to restrict access to this container to within the VNet, 
        // the environment can be set to be internal within the VNet, but the webapp itself
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
        customDomains: [for i in range(0, length(customDomains)): {
            name: customDomains[i].domainName
            bindingType: 'SniEnabled'
            certificateId: certificates[i].id
        }]
      }
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
          probes: useProbes ? [
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
        minReplicas: scaleToZero ? 0: 1
        maxReplicas: maxReplicas
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
