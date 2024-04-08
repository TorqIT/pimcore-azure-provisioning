param name string
param accessMode string
param containerAppsEnvironmentName string
param storageAccountName string
param storageAccountFileShareName string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource storage 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: containerAppsEnvironment
  name: name
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: storageAccountFileShareName
      accessMode: accessMode
    }
  }
}
