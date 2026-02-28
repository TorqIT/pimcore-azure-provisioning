param databaseServerName string
param generalActionGroupName string
param criticalActionGroupName string
param cpuUsageThresholdPercentage int

resource generalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: generalActionGroupName
}
resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: criticalActionGroupName
}
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: databaseServerName
}

resource warningAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-${cpuUsageThresholdPercentage}-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average CPU usage exceeds ${cpuUsageThresholdPercentage}% or for at least 5 minutes'
    severity: 2 // Warning
    enabled: true
    evaluationFrequency: 'PT1M' 
    windowSize: 'PT5M' 
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPUUsage'
          metricName: 'cpu_percent'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: cpuUsageThresholdPercentage
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    scopes: [
      databaseServer.id
    ]
    actions: [
      {
        actionGroupId: generalActionGroup.id
      }
    ]
  }
}

resource errorAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-100-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when average CPU usage reaches 100% for at least 5 minutes'
    severity: 1 // Error
    enabled: true
    evaluationFrequency: 'PT1M' 
    windowSize: 'PT5M' 
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPUUsage'
          metricName: 'cpu_percent'
          timeAggregation: 'Average'
          operator: 'GreaterThanOrEqual'
          threshold: 100
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    scopes: [
      databaseServer.id
    ]
    actions: [
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}
