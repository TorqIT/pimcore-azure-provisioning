param location string = resourceGroup().location

param frontDoorProfileName string
param endpointName string
param storageAccountName string
param storageAccountAssetsContainerName string
@secure()
param storageAccountSasToken string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2025-06-01' = {
  name: endpointName
  parent: frontDoorProfile
  location: location
}

// TODO custom domains

var storageAccountOriginHostName = '${storageAccountName}.blob.${environment().suffixes.storage}'
resource storageAccountOriginGroup 'Microsoft.Cdn/profiles/originGroups@2025-06-01' = {
  name: 'storage-account'
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}
resource storageAccountOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01' = {
  name: 'storage-account'
  parent: storageAccountOriginGroup
  properties: {
    hostName: storageAccountOriginHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: storageAccountOriginHostName
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource cdnRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  name: 'cdn'
  parent: endpoint
  dependsOn: [
    storageAccountOrigin
  ]
  properties: {
    originGroup: {
      id: storageAccountOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    ruleSets: [
      {
        id: storageAccountRuleSet.id
      }
    ]
    forwardingProtocol: 'MatchRequest'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

resource storageAccountRuleSet 'Microsoft.Cdn/profiles/ruleSets@2025-06-01' = {
  parent: frontDoorProfile
  name: 'storageAccount'

  resource thumbnailsRule 'rules' = {
    name: 'thumbnails'
    properties: {
      order: 1
      conditions: [
        {
          name: 'UrlPath'
          parameters: {
            typeName: 'DeliveryRuleUrlPathMatchConditionParameters'
            operator: 'Contains'
            matchValues: [
              'image-thumb'
            ] 
          }
        }
      ]
      actions: [
        {
          name: 'UrlRewrite'
          parameters: {
            typeName: 'DeliveryRuleUrlRewriteActionParameters'
            sourcePattern: '/'
            destination: '/${storageAccountAssetsContainerName}/thumbnails/{url_path}?${storageAccountSasToken}'
          }
        }
      ]
      matchProcessingBehavior: 'Stop'
    }
  }


  resource assetsCatchAllRule 'rules' = {
    name: 'assetsCatchAll'
    properties: {
      order: 2
      conditions: [
      ]
      actions: [
        {
          name: 'UrlRewrite'
          parameters: {
            typeName: 'DeliveryRuleUrlRewriteActionParameters'
            sourcePattern: '/'
            destination: '/${storageAccountAssetsContainerName}/assets/{url_path}?${storageAccountSasToken}'
          }
        }
      ]
    }
  }
}

output id string = frontDoorProfile.id
