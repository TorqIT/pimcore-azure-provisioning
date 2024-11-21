@secure()
param symfonyKernelSecretSecret object
param pimcoreEnterpriseTokenSecret object
param provisionForPortalEngine bool
param portalEnginePublicBuildStorageMountName string

// Volumes
module portalEngineVolumeMounts './portal-engine/container-app-portal-engine-volume-mounts.bicep' = if (provisionForPortalEngine) {
  name: 'portal-engine-volume-mounts'
  params: {
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
  }
}
var defaultVolumes = []
var kernelSecretVolume = !empty(symfonyKernelSecretSecret) ? [{
  storageType: 'Secret'
  name: 'kernel-secret'
  secrets: [
    {
      path: 'kernel-secret'
      secretRef: 'kernel-secret'
    }
  ]
}] : []
var portalEngineVolume = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolume] : []
var enterpriseVolume = !empty(pimcoreEnterpriseTokenSecret) ? [{
  storageType: 'Secret'
  name: 'pimcore-enterprise-token'
  secrets: [
    {
      path: 'pimcore-enterprise-token'
      secretRef: 'pimcore-enterprise-token'
    }
  ]
}] : []
output volumes array = concat(defaultVolumes, kernelSecretVolume, portalEngineVolume, enterpriseVolume)

// Volume mounts
var defaultVolumeMounts = []
var kernelSecretVolumeMount = !empty(kernelSecretVolume) ? [{
  mountPath: '/run/secrets'
  volumeName: 'kernel-secret'
}] : []
var enterpriseVolumeMount = !empty(pimcoreEnterpriseTokenSecret) ? [{
  mountPath: '/run/secrets'
  volumeName: 'pimcore-enterprise-token'
}] : []
var portalEngineVolumeMount = provisionForPortalEngine ? [portalEngineVolumeMounts.outputs.portalEngineVolumeMount] : []
output volumeMounts array = concat(defaultVolumeMounts, kernelSecretVolumeMount, enterpriseVolumeMount, portalEngineVolumeMount)
