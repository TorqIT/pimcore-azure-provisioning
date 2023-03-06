export SERVICE_PRINCIPAL_ID=
export SERVICE_PRINCIPAL_PASSWORD=
export DATABASE_ADMIN_PASSWORD=

# Add new secrets like so, all in one string
export OAUTH_CLIENT_SECRET=ijkl
export SECRETS="[{name: 'OAUTH_CLIENT_SECRET' value: ${OAUTH_CLIENT_SECRET}}]"