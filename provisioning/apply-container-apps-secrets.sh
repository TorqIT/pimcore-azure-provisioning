#!/bin/bash

set -e

resourceGroup=$(jq -r '.parameters.resourceGroup.value' parameters.json)
keyVaultName=$(jq -r '.parameters.keyVaultName.value' parameters.json)
phpFpmContainerAppName=$(jq -r '.parameters.phpFpmContainerAppName.value' parameters.json)
supervisordContainerAppName=$(jq -r '.parameters.supervisordContainerAppName.value' parameters.json)

jq -rc '.parameters.additionalSecrets.value.array[]' parameters.json | while IFS='' read secret;
do
  secretName=$(echo "$secret" | jq -r '.secretNameInKeyVault')
  secretEnvVarName=$(echo "$secret" | jq -r '.secretEnvVarNameInContainerApp')
  secretRef=$(echo "$secret" | jq -r '.secretRefInContainerApp')

  echo "Getting secret $secretName from Key Vault $keyVaultName..."
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName | jq -r '.value')

  echo "Setting secret $secretRef in Container App $phpFpmContainerAppName..."
  az containerapp secret set --resource-group $resourceGroup --name $phpFpmContainerAppName --secrets $secretRef=$secretValue
  echo "Setting environment variable $secretEnvVarName to reference $secretRef in $phpFpmContainerAppName..."
  az containerapp update --resource-group $resourceGroup --name $phpFpmContainerAppName --set-env-vars "$secretEnvVarName=secretref:$secretRef"

  echo "Setting secret $secretRef in Container App $supervisordContainerAppName..."
  az containerapp secret set --resource-group $resourceGroup --name $supervisordContainerAppName --secrets $secretRef=$secretValue
  echo "Setting environment variable $secretEnvVarName to reference $secretRef in $supervisordContainerAppName..."
  az containerapp update --resource-group $resourceGroup --name $supervisordContainerAppName --set-env-vars "$secretEnvVarName=secretref:$secretRef"
done

