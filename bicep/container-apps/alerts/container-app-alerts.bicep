param containerAppName string
param generalMetricAlertsActionGroupName string

module memoryAlerts './container-app-memory-alert.bicep' = {
  name: '${containerAppName}-memory-alert'
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
  }
}
module replicaRestartAlerts './container-app-restarts-alert.bicep' = {
  name: '${containerAppName}-memory-alert'
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
  }
}
