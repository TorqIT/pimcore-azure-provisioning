param databaseServerName string
param actionGroupName string

param threshold int = 2 // CPU usage threshold percentage
param timeAggregation string = 'Average'
param alertTimeWindow string = 'PT5M' // 5 minutes

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: actionGroupName
}
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: databaseServerName
}

resource alert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when CPU usage reaches 100% for at least 5 minutes'
    severity: 2 // Warning
    enabled: true
    evaluationFrequency: 'PT1M' 
    windowSize: alertTimeWindow 
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPUUsage'
          metricName: 'cpu_percent'
          timeAggregation: timeAggregation
          operator: 'GreaterThan'
          threshold: threshold
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    scopes: [
      databaseServer.id
    ]
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
