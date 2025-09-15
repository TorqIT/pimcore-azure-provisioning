param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param customDomains array
param cpuCores string
param memory string
param useProbes bool
param minReplicas int
param maxReplicas int
param firewallRules array
param managedIdentityId string
param isExternal bool

@secure()
param databasePasswordSecret object
@secure()
param storageAccountKeySecret object
param additionalSecrets array
param additionalVolumesAndMounts array

// Optional Portal Engine provisioning
param provisionForPortalEngine bool
param portalEnginePublicBuildStorageMountName string
@secure()
param portalEngineStorageAccountKeySecret object

// Optional scaling rules
param provisionCronScaleRule bool
param cronScaleRuleDesiredReplicas int
param cronScaleRuleStartSchedule string
param cronScaleRuleEndSchedule string
param cronScaleRuleTimezone string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource certificates 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' existing = [for customDomain in customDomains: {
  parent: containerAppsEnvironment
  name: customDomain.certificateName
}]

// Secrets
var defaultSecrets = [databasePasswordSecret, storageAccountKeySecret]
var portalEngineSecrets = provisionForPortalEngine ? [portalEngineStorageAccountKeySecret] : []
var secrets = concat(defaultSecrets, portalEngineSecrets, additionalSecrets)

// Volumes
module volumesModule './container-apps-volumes.bicep' = {
  name: 'container-app-php-volumes'
  params: {
    provisionForPortalEngine: provisionForPortalEngine
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
    additionalVolumesAndMounts: additionalVolumesAndMounts
  }
}

// Scaling rules
module scaleRules './scale-rules/container-app-scale-rules.bicep' = {
  name: 'container-app-scale-rules'
  params: {
    provisionCronScaleRule: provisionCronScaleRule
    cronScaleRuleTimezone: cronScaleRuleTimezone
    cronScaleRuleStartSchedule: cronScaleRuleStartSchedule
    cronScaleRuleEndSchedule: cronScaleRuleEndSchedule
    cronScaleRuleDesiredReplicas: cronScaleRuleDesiredReplicas
  }
}

// Firewall rules
module firewallRulesModule './container-app-firewall-rules.bicep' = {
  params: {
    firewallRules: firewallRules
    phpContainerAppExternal: isExternal
  }
}

resource phpContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: secrets
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: managedIdentityId
        }
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
        // ipSecurityRestrictions: firewallRulesModule.outputs.firewallRulesConsolidated
        ipSecurityRestrictions: concat(firewallRules, [
          {
            name: 'DigiCert IP 1'
            action: 'Allow'
            ipAddressRange: '216.168.249.9'
          }
          {
            name: 'DigiCert IP 2'
            action: 'Allow'
            ipAddressRange: '216.168.240.4'
          }
          {
            name: 'DigiCert IP 3'
            action: 'Allow'
            ipAddressRange: '216.168.247.9'
          }
          {
            name: 'DigiCert IP 4'
            action: 'Allow'
            ipAddressRange: '202.65.16.4'
          }
          {
            name: 'DigiCert IP 5'
            action: 'Allow'
            ipAddressRange: '54.185.245.130'
          }
          {
            name: 'DigiCert IP 6'
            action: 'Allow'
            ipAddressRange: '13.58.90.0'
          }
          {
            name: 'DigiCert IP 7'
            action: 'Allow'
            ipAddressRange: '52.17.48.104'
          }
          {
            name: 'DigiCert IP 8'
            action: 'Allow'
            ipAddressRange: '18.193.239.14'
          }
          {
            name: 'DigiCert IP 9'
            action: 'Allow'
            ipAddressRange: '54.227.165.213'
          }
          {
            name: 'DigiCert IP 10'
            action: 'Allow'
            ipAddressRange: '54.241.89.140'
          }
        ])
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
          volumeMounts: volumesModule.outputs.volumeMounts
        }
      ]
      volumes: volumesModule.outputs.volumes
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: scaleRules.outputs.scaleRules
      }
    }
  }
}
