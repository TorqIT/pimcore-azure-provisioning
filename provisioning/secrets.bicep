@secure()
param secrets string
var secretsOutput = !empty(secrets) ? json(secrets) : []
output secretsOutput array = secretsOutput
