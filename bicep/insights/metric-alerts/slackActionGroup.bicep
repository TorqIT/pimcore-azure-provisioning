param slackActionGroupName string
@secure()
param slackWebhook string

resource slackActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: slackActionGroupName
  location: 'Global'
  properties: {
    groupShortName: 'slackGroup'
    enabled: true
    webhookReceivers: [
      {
        name: 'Slack Notification'
        serviceUri: slackWebhook
      }
    ]
  }
}
