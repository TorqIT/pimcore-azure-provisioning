param slackActionGroupName string
@secure()
param slackWebhook string

resource slackActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: slackActionGroupName
  location: 'Global'
  properties: {
    groupShortName: 'slackGroup'
    enabled: true
    emailReceivers: [
      {
        name: 'Slack #monitoring channel'
        emailAddress: 'monitoring-aaaaps57itecox3fm7qw24plii@torqit.slack.com'
      }
    ]
  }
}
