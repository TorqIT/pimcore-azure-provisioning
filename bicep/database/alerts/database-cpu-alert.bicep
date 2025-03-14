param databaseServerName string
param actionGroupName string

param threshold int = 1 // CPU usage threshold percentage
param timeAggregation string = 'Average'
param alertTimeWindow string = 'PT5M' // 5 minutes

resource slackActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: actionGroupName
}
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: databaseServerName
}

resource mysqlMetricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when CPU usage reaches 100% for at least 5 minutes'
    severity: 4 // Warning
    enabled: true
    evaluationFrequency: 'PT1M' // Check every minute
    windowSize: alertTimeWindow // The time window to check for the alert condition
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
      mysqlServer.id
    ]
    actions: [
      {
        actionGroupId: slackActionGroup.id
      }
    ]
  }
}
