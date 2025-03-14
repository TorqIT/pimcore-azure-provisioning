param containerAppName string
param slackWebhookUrl string
param threshold int = 80 // RAM usage threshold percentage
param timeAggregation string = 'Average'
param alertTimeWindow string = 'PT5M' // 5 minutes

// Container App resource (example, already existing)
resource containerApp 'Microsoft.Web/containerApps@2024-04-01' existing = {
  name: containerAppName
}

// Create the Action Group (Slack notification)
resource slackActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'slackActionGroup'
  location: 'Global'
  properties: {
    groupShortName: 'slackGroup'
    enabled: true
    webhookReceivers: [
      {
        name: 'Slack Notification'
        serviceUri: slackWebhookUrl
      }
    ]
  }
}

// Create the Metric Alert for RAM usage
resource containerAppMetricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'containerAppMemoryUsageAlert'
  location: 'Global'
  properties: {
    description: 'Alert when memory usage reaches 80% for at least 5 minutes'
    severity: 3 // Choose an appropriate severity
    enabled: true
    evaluationFrequency: 'PT1M' // Check every minute
    windowSize: alertTimeWindow // The time window to check for the alert condition
    scopes: [
      containerApp.id
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'MemoryUsage'
          metricName: 'memory_usage'
          timeAggregation: timeAggregation
          operator: 'GreaterThan'
          threshold: threshold
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: slackActionGroup.id
      }
    ]
  }
}
