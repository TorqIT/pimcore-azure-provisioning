param location string = resourceGroup().location

param keyVaultName string
param managedIdentityForKeyVaultId string

param secrets array

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = [for secret in secrets: if (contains(secret, 'secretEnvVarNameInContainerApp')) {
  parent: keyVault
  name: secret.secretNameInKeyVault
}]

output secrets array = [for i in range(0, length(secrets)): {
  name: secrets[i].secretRefInContainerApp
  keyVaultUrl: keyVaultSecrets[i].properties.secretUri
  identity: managedIdentityForKeyVaultId
}]
// Only define environment variables for secrets with the secretEnvVarNameInContainerApp property
var envVarSecrets = filter(secrets, secret => contains(secret, 'secretEnvVarNameInContainerApp'))
output envVars array = [for secret in envVarSecrets: {
  name: secret.secretEnvVarNameInContainerApp
  secretRef: secret.secretRefInContainerapp
}]
