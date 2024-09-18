param portalEnginePublicStorageMountName string

output portalEngineVolume object = {
  name: 'portal-engine-public'
  storageName: portalEnginePublicStorageMountName
  storageType: 'AzureFile'
}
output portalEngineVolumeMount object = {
  volumeName: 'portal-engine-public'
  mountPath: '/var/www/html/public/portal-engine'
}
