#!/bin/bash

echo Logging into Azure using service principal $SERVICE_PRINCIPAL_ID...
az login \
  --tenant $TENANT_NAME \
  --service-principal -u $SERVICE_PRINCIPAL_ID -p $SERVICE_PRINCIPAL_PASSWORD 

echo Creating dump of $DATABASE_NAME...
FILE_NAME=$DATABASE_NAME-$(date +%s).sql
mysqldump \
    -h $DATABASE_SERVER_NAME.mysql.database.azure.com \
    -u $DATABASE_ADMIN_USER@$DATABASE_SERVER_NAME \
    -p$DATABASE_ADMIN_PASSWORD \
    $DATABASE_NAME \
    --ssl-ca=./ca-cert.crt.pem \
    > $FILE_NAME

echo Uploading $FILE_NAME to $STORAGE_ACCOUNT_NAME storage account...
az storage blob upload \
    --account-name $STORAGE_ACCOUNT_NAME \
    --container-name $STORAGE_ACCOUNT_CONTAINER_NAME \
    --account-key $STORAGE_ACCOUNT_KEY \
    --file $FILE_NAME \
    --name $FILE_NAME