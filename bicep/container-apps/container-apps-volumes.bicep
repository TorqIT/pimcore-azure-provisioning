param provisionForPortalEngine bool
param portalEnginePublicBuildStorageMountName string

param additionalVolumesAndMounts array

// Volumes
module portalEngineVolumeMounts './portal-engine/container-app-portal-engine-volume-mounts.bicep' = if (provisionForPortalEngine) {
  name: 'portal-engine-volume-mounts'
  params: {
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
  }
}
var defaultVolumes = []
var portalEngineVolume = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolume] : []
var secretsVolume = [{
  storageType: 'Secret'
  name: 'secrets'
}]
var additionalVolumes = [for volumeAndMount in additionalVolumesAndMounts: {
  storageType: 'NfsAzureFile'
  name: volumeAndMount.volumeName
  mountOptions: volumeAndMount.?mountOptions ?? 'uid=1000,gid=1000'
}]
output volumes array = concat(defaultVolumes, secretsVolume, portalEngineVolume, additionalVolumes)

// Volume mounts
var defaultVolumeMounts = []
var secretsVolumeMount = [{
  volumeName: 'secrets'
  mountPath: '/run/secrets'
}]
var portalEngineVolumeMount = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolumeMount] : []
var additionalVolumeMounts = [for volumeAndMount in additionalVolumesAndMounts: {
  volumeName: volumeAndMount.volumeName
  mountPath: volumeAndMount.mountPath
}]
output volumeMounts array = concat(defaultVolumeMounts, secretsVolumeMount, portalEngineVolumeMount, additionalVolumeMounts)
