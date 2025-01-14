# TODO need to only do this on the "first" deploy
KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)
KEY_VAULT_RESOURCE_GROUP_NAME=$(jq -r '.parameters.keyVaultResourceGroupName.value // empty' $1)
KEY_VAULT_ENABLE_PURGE_PROTECTION=$(jq -r '.parameters.keyVaultEnablePurgeProtection.value // empty' $1)
echo "Deploying Key Vault..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/key-vault/key-vault.bicep \
  --parameters \
    name=$KEY_VAULT_NAME \
    enablePurgeProtection=$KEY_VAULT_ENABLE_PURGE_PROTECTION
echo "Assigning Key Vault Secrets Officer role to current user..."
PRINCIPAL_TYPE=$(az account show --query "user.type" -o tsv)
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/key-vault/key-vault-roles.bicep \
  --parameters \
    keyVaultName=$KEY_VAULT_NAME \
    principalType=$PRINCIPAL_TYPE
KEY_VAULT_GENERATE_RANDOM_SECRETS=$(jq -r '.parameters.keyVaultGenerateRandomSecrets.value' $1) 
if [ "${KEY_VAULT_RESOURCE_GROUP_NAME:-$RESOURCE_GROUP}" == "${RESOURCE_GROUP}" ]
then
  if [ "${KEY_VAULT_GENERATE_RANDOM_SECRETS}" != "null" ] || [ "${KEY_VAULT_GENERATE_RANDOM_SECRETS}" = true ]
  then
    echo Adding temporary network rule to the Key Vault firewall...
    az keyvault network-rule add \
      --name $KEY_VAULT_NAME \
      --resource-group $RESOURCE_GROUP \
      --ip-address $(curl ipinfo.io/ip)

    declare -A SECRETS=("databasePassword", "pimcore-admin-password", "kernel-secret")
    for secret in "${SECRETS[@]}"; do
      az keyvault secret show --vault-name $KEY_VAULT_NAME --name $secret > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo Setting random value for secret $secret...
        az keyvault secret set \
          --vault-name $KEY_VAULT_NAME \
          --name $secret \
          --value $(openssl rand -hex 16) \
          --output none
      fi
    done
    
    echo Removing network rule for this runner from the Key Vault firewall...
    az keyvault network-rule remove \
      --name $KEY_VAULT_NAME \
      --resource-group $RESOURCE_GROUP \
      --ip-address $(curl ipinfo.io/ip)
  fi
fi