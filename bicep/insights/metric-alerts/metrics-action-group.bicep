param actionGroupName string
param emailReceivers array

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: 'slackGroup'
    enabled: true
    emailReceivers: [for emailReceiver in emailReceivers: {
        name: emailReceiver
        emailAddress: emailReceiver
      }
    ]
  }
}
