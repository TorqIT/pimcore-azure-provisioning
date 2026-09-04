param appDebug string
param appEnv string
param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string
param storageAccountKeySecretRefName string
param databaseServerName string
param databaseServerVersion string
param databaseName string
param databaseUser string
param databasePasswordSecretRefName string
param databaseUrlSecretRefName string
param pimcoreDevMode string
param pimcoreEnvironment string
param redisDb string
param redisHost string
param redisSessionDb string
param provisionOpensearch bool
param opensearchContainerAppName string
param provisionMercure bool
param mercureContainerAppName string
param mercureJwtSecreRefName string
param containerAppsEnvironmentName string
param phpContainerAppName string
param phpContainerAppCustomDomains array
param additionalEnvVars array

// Optional Portal Engine provisioning
param provisionPortalEngine bool
param portalEngineStorageAccountName string
param portalEngineStorageAccountDownloadsContainerName string
param portalEngineStorageAccountKeySecretRefName string

var defaultEnvVars = [
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
    secretRef: storageAccountKeySecretRefName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'DATABASE_HOST'
    value: '${databaseServerName}.mysql.database.azure.com'
  }
  {
    name: 'DATABASE_NAME'
    value: databaseName
  }
  {
    name: 'DATABASE_USER'
    value: databaseUser
  }
  {
    name: 'DATABASE_PASSWORD'
    secretRef: databasePasswordSecretRefName
  }
  {
    name: 'DATABASE_SERVER_VERSION'
    value: databaseServerVersion
  }
  {
    name: 'DATABASE_URL'
    secretRef: databaseUrlSecretRefName
  }
  {
    name: 'PIMCORE_DEV_MODE'
    value: pimcoreDevMode
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

// Optional (until v3) Opensearch Container App
resource opensearchContainerApp 'Microsoft.App/containerApps@2026-01-01' existing = if (provisionOpensearch) {
  name: opensearchContainerAppName
}
var opensearchEnvVars = provisionOpensearch ? [
  {
    name: 'OPENSEARCH_HOST'
    value: 'https://${opensearchContainerApp!.properties.configuration.ingress.fqdn}:443'
  }
] : []

// Optional Portal Engine env vars
var portalEngineEnvVars = provisionPortalEngine ? [
  {
    name: 'PORTAL_ENGINE_STORAGE_ACCOUNT'
    value: portalEngineStorageAccountName
  }
  {
    name: 'PORTAL_ENGINE_STORAGE_ACCOUNT_DOWNLOADS_CONTAINER'
    value: portalEngineStorageAccountDownloadsContainerName
  }
  {
    name: 'PORTAL_ENGINE_STORAGE_ACCOUNT_KEY'
    secretRef: portalEngineStorageAccountKeySecretRefName
  }
]: []

// Optional (until v3) Mercure Container App
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
var phpContainerAppDefaultFqdn = '${phpContainerAppName}.${containerAppsEnvironment.properties.defaultDomain}'
var phpContainerAppPublicFqdn = length(phpContainerAppCustomDomains) > 0 ? phpContainerAppCustomDomains[0].domainName : phpContainerAppDefaultFqdn
var mercureEnvVars = provisionMercure ? [
  {
    name: 'MERCURE_JWT_KEY'
    secretRef: mercureJwtSecreRefName
  }
  {
    name: 'MERCURE_URL_SERVER'
    value: 'http://${mercureContainerAppName}:80/.well-known/mercure'
  }
  {
    name: 'MERCURE_URL_CLIENT'
    value: 'https://${phpContainerAppPublicFqdn}/hub'
  }
]: []

output envVars array = concat(defaultEnvVars, additionalEnvVars, opensearchEnvVars, portalEngineEnvVars, mercureEnvVars)
