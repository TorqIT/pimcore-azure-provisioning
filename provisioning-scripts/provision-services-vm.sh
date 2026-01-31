#!/bin/bash

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
LOCATION=$(jq -r '.parameters.location.value' $1)
PROVISION_SERVICES_VM=$(jq -r '.parameters.provisionServicesVM.value // false' $1)
SERVICES_VM_NAME=$(jq -r '.parameters.servicesVmName.value // empty' $1)

if [ -z "$PROVISION_SERVICES_VM" ] || [ "$PROVISION_SERVICES_VM" = "false" ] || [ -z "$SERVICES_VM_NAME" ]; then
  echo "Services VM provisioning not requested, skipping..."
  return 0
fi

set +e
az vm show \
  --resource-group $RESOURCE_GROUP \
  --name $SERVICES_VM_NAME \
  --output none
returnCode=$?
set -e
vmExists=([ $returnCode -eq 0 ])

echo "Provisioning Services VM..."
SERVICES_VM_SUBNET_NAME=$(jq -r '.parameters.servicesVmSubnetName.value // empty' $1)
SERVICES_VM_SUBNET_ADDRESS_SPACE=$(jq -r '.parameters.servicesVmSubnetAddressSpace.value // empty' $1)
SERVICES_VM_ADMIN_USERNAME=$(jq -r '.parameters.servicesVmAdminUsername.value // empty' $1)
SERVICES_VM_PUBLIC_KEY_KEY_VAULT_SECRET_NAME=$(jq -r '.parameters.servicesVmPublicKeyKeyVaultSecretName.value // empty' $1)
SERVICES_VM_SIZE=$(jq -r '.parameters.servicesVmSize.value // empty' $1)
SERVICES_VM_UBUNTU_OS_VERSION=$(jq -r '.parameters.servicesVmUbuntuOSVersion.value // empty' $1)
SERVICES_VM_FIREWALL_IPS_FOR_SSH=$(jq -r '.parameters.servicesVmFirewallIpsForSsh.value // empty' $1)

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file ./bicep/services-virtual-machine/services-virtual-machine.bicep \
    --parameters \
    name=$SERVICES_VM_NAME \
    location=$LOCATION \
    servicesVmSubnetName=$SERVICES_VM_SUBNET_NAME \
    servicesVmSubnetAddressSpace=$SERVICES_VM_SUBNET_ADDRESS_SPACE \
    servicesVmAdminUsername=$SERVICES_VM_ADMIN_USERNAME \
    servicesVmPublicKeyKeyVaultSecretName=$SERVICES_VM_PUBLIC_KEY_KEY_VAULT_SECRET_NAME \
    servicesVmSize=$SERVICES_VM_SIZE \
    servicesVmUbuntuOSVersion=$SERVICES_VM_UBUNTU_OS_VERSION \
    servicesVmFirewallIpsForSsh=$SERVICES_VM_FIREWALL_IPS_FOR_SSH