param desiredReplicas int
param start string
param end string
param timezone string

var cronScaleRule = {
  type: 'cron'
  metadata: any({
    desiredReplicas: '${desiredReplicas}'
    timezone: timezone
    start: start
    end: end
  })
}

output cronScaleRule object = cronScaleRule
