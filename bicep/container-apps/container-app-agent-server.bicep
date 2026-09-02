param location string = resourceGroup().location

param storageAccountName string
@secure()
param storageAccountKey string
param storageAccountFileShareName string

param keyVaultName string
param managedIdentityForKeyVaultId string
param managedIdentityId string
param containerRegistryName string

param containerAppsEnvironmentName string
param containerAppsEnvironmentStorageMountName string
param volumeName string

param containerAppName string
param imageName string
param cpuCores string
param memory string
param minReplicas int
param maxReplicas int

param agentServerAdminTokenSecretNameInKeyVault string
param anthropicApiKeySecretNameInKeyVault string
param openAiAuthTokenSecretNameInKeyVault string
param mercureJwtSecretNameInKeyVault string

// The internal Container Apps Environment DNS name of the PHP app this agent-server talks to
// (Pimcore Studio Backend API for session persistence, MCP tool calls, etc.)
param phpContainerAppName string

// Optional - only wired in if Mercure is also provisioned, for live cross-client chat sync
param provisionMercure bool
param mercureContainerAppName string

// Storage Account File Share
// A single share holds both durable Copilot runtime state and staged file uploads,
// mirroring how the Mercure Container App mounts subPaths of one share for /data and /config.
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}
resource storageAccountFileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  parent: storageAccount
  name: 'default'
}
resource storageAccountFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: storageAccountFileService
  name: storageAccountFileShareName
}

// Container App Environment storage mount
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}
resource storageMount 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: containerAppsEnvironment
  name: containerAppsEnvironmentStorageMountName
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: storageAccountFileShareName
      accessMode: 'ReadWrite'
    }
  }
}

// Secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource agentServerAdminTokenSecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2025-05-01' existing = {
  parent: keyVault
  name: agentServerAdminTokenSecretNameInKeyVault
}
var agentServerAdminTokenSecretRefName = 'agent-server-admin-token'
var agentServerAdminTokenSecret = {
  name: agentServerAdminTokenSecretRefName
  keyVaultUrl: agentServerAdminTokenSecretInKeyVault.?properties.secretUri
  identity: managedIdentityForKeyVaultId
}

resource anthropicApiKeySecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2025-05-01' existing = {
  parent: keyVault
  name: anthropicApiKeySecretNameInKeyVault
}
var anthropicApiKeySecretRefName = 'anthropic-api-key'
var anthropicApiKeySecret = {
  name: anthropicApiKeySecretRefName
  keyVaultUrl: anthropicApiKeySecretInKeyVault.?properties.secretUri
  identity: managedIdentityForKeyVaultId
}

resource openAiAuthTokenSecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2025-05-01' existing = {
  parent: keyVault
  name: openAiAuthTokenSecretNameInKeyVault
}
var openAiAuthTokenSecretRefName = 'open-ai-auth-token'
var openAiAuthTokenSecret = {
  name: openAiAuthTokenSecretRefName
  keyVaultUrl: openAiAuthTokenSecretInKeyVault.?properties.secretUri
  identity: managedIdentityForKeyVaultId
}

// Reuses the same Mercure JWT secret Mercure itself and PHP sign/verify with - agent-server publishes
// live chat updates to the same Mercure hub, so it needs the same shared key, not a secret of its own.
resource mercureJwtSecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2025-05-01' existing = if (provisionMercure) {
  parent: keyVault
  name: mercureJwtSecretNameInKeyVault
}
var mercureJwtSecretRefName = 'mercure-jwt-key'
var mercureJwtSecret = provisionMercure ? {
  name: mercureJwtSecretRefName
  keyVaultUrl: mercureJwtSecretInKeyVault.?properties.secretUri
  identity: managedIdentityForKeyVaultId
} : {}

var secrets = concat(
  [agentServerAdminTokenSecret, anthropicApiKeySecret, openAiAuthTokenSecret],
  provisionMercure ? [mercureJwtSecret] : []
)

// Environment variables
var envVars = concat(
  [
    { name: 'NODE_ENV', value: 'production' }
    { name: 'PORT', value: '3032' }
    // Same-environment Container Apps resolve each other by container app name over the internal DNS.
    { name: 'PIMCORE_INTERNAL_URL', value: 'http://${phpContainerAppName}' }
    { name: 'AGENT_SERVER_ADMIN_TOKEN', secretRef: agentServerAdminTokenSecretRefName }
    { name: 'ANTHROPIC_API_KEY', secretRef: anthropicApiKeySecretRefName }
    { name: 'OPEN_AI_AUTH_TOKEN', secretRef: openAiAuthTokenSecretRefName }
  ],
  provisionMercure ? [
    { name: 'MERCURE_SERVER_URL', value: 'http://${mercureContainerAppName}/.well-known/mercure' }
    { name: 'MERCURE_JWT_KEY', secretRef: mercureJwtSecretRefName }
  ] : []
)

resource agentServerContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  dependsOn: [storageMount]
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: secrets
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: managedIdentityId
        }
      ]
      ingress: {
        // Internal only - reached exclusively via PHP/nginx's reverse proxy (/agent-server/api/),
        // never exposed directly to the internet.
        external: false
        allowInsecure: false
        targetPort: 3032
      }
    }
    template: {
      containers: [
        {
          name: imageName
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          env: envVars
          volumeMounts: [
            {
              mountPath: '/app/.copilot-state'
              volumeName: volumeName
              subPath: 'copilot-state'
            }
            {
              mountPath: '/app/uploads'
              volumeName: volumeName
              subPath: 'uploads'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: { scheme: 'HTTP', port: 3032, path: '/agent-server/api/health' }
              initialDelaySeconds: 10
              periodSeconds: 30
              failureThreshold: 3
              timeoutSeconds: 5
            }
            {
              type: 'Readiness'
              httpGet: { scheme: 'HTTP', port: 3032, path: '/agent-server/api/health' }
              initialDelaySeconds: 5
              periodSeconds: 10
              failureThreshold: 3
              timeoutSeconds: 5
            }
          ]
        }
      ]
      volumes: [
        {
          name: volumeName
          storageName: containerAppsEnvironmentStorageMountName
          storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}
