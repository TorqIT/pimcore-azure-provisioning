param databaseServerName string
param generalActionGroupName string
param criticalActionGroupName string

resource generalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: generalActionGroupName
}
resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: criticalActionGroupName
}
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: databaseServerName
}

resource eightyPercentAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-80%-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when CPU usage reaches 80% for at least 5 minutes'
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
          threshold: 80
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

resource oneHundredPercentAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${databaseServerName}-100%-cpu-alert'
  location: 'Global'
  properties: {
    description: 'Alert when CPU usage reaches 100% for at least 5 minutes'
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
          operator: 'Equals'
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
        actionGroupId: generalActionGroup.id
      }
      {
        actionGroupId: criticalActionGroup.id
      }
    ]
  }
}
