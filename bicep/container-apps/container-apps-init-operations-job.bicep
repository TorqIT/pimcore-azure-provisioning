param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param environmentVariables array
param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param databasePasswordSecret object
@secure()
param containerRegistryPasswordSecret object

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}

resource containerAppJob 'Microsoft.App/jobs@2023-05-02-preview' = {
  location: location
  name: containerAppJobName
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      replicaTimeout: 60
      secrets: [containerRegistryPasswordSecret, databasePasswordSecret]
      triggerType: 'Manual'
      eventTriggerConfig: {
        scale: {
          minExecutions: 0
          maxExecutions: 1
        }
      }
      registries: [
        containerRegistryConfiguration
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          command: [
            '/bin/bash'
            '-c'
            'echo Running migrations...'
            'runuser -u www-data -- /var/www/html/bin/console doctrine:migrations:migrate -n'
            'echo Rebuilding classes...'
            'runuser -u www-data -- /var/www/html/bin/console pimcore:deployment:classes-rebuild -c -d -n'
            'echo Clearing caches...'
            'runuser -u www-data -- /var/www/html/bin/console cache:clear'
            'runuser -u www-data -- /var/www/html/bin/console pimcore:cache:clear'
          ]
          env: environmentVariables
          name: imageName
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
    }
  }
}
