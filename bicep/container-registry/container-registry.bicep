param location string = resourceGroup().location

@minLength(5)
@maxLength(50)
param containerRegistryName string
param sku string

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

resource purgeTaskScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzureCLI'
  location: location
  name: 'acr-purge-task'
  properties: {
    azCliVersion: '2.8.0'
    retentionInterval: 'P1H'
    arguments: ''
    scriptContent: '''
      echo Setting up scheduled task to purge all but the latest 10 containers...

      CONTAINER_REGISTRY_REPOSITORIES=($PHP_FPM_IMAGE_NAME $SUPERVISORD_IMAGE_NAME $REDIS_IMAGE_NAME)

      PURGE_CMD="acr purge "
      for repository in ${CONTAINER_REGISTRY_REPOSITORIES[@]}
      do
        PURGE_CMD="$PURGE_CMD --filter '$repository:.*'"
      done
      PURGE_CMD="$PURGE_CMD --ago 0d --keep 10 --untagged"
      az acr task create \
        --resource-group $RESOURCE_GROUP \
        --name purgeTask \
        --cmd "$PURGE_CMD" \
        --schedule "0 0 * * *" \
        --registry $CONTAINER_REGISTRY_NAME \
        --context /dev/null
    '''
  }
}
