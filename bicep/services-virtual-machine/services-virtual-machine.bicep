param location string = resourceGroup().location

param name string

param servicesVmName string
param createServicesVm bool
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubnetName string
param virtualNetworkSubnetAddressSpace string = '10.0.3.0/29'
param adminUsername string = 'azureuser'
@secure()
param adminPublicSshKey string
param keyVaultName string
param keyVaultResourceGroupName string
param size string = 'Standard_B2s'
@allowed(['Ubuntu-2204', 'Ubuntu-2404'])
param ubuntuOSVersion string = 'Ubuntu-2404'
param firewallIpsForSsh array = []

var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2404': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-questing'
    sku: '24_04-lts-gen2'
    version: 'latest'
  }
}
var networkSecurityGroupName = '${name}-nsg'
var publicIPAddressName = '${name}-public-ip'
var networkInterfaceName = '${name}-net-int'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: virtualNetworkSubnetName
  parent: virtualNetwork
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-03-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [for ip in firewallIpsForSsh: {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: ip
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2024-03-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-03-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

var vmHardwareProfile = {
  vmSize: size
}
var vmOsDiskProfile = {
  createOption: 'FromImage'
  managedDisk: {
    storageAccountType: 'StandardSSD_LRS'
  }
}

resource existingVirtualMachine 'Microsoft.Compute/virtualMachines@2025-04-01' existing = if (createServicesVm == false) {
  name: servicesVmName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-07-01' = if (createServicesVm) {
  name: name
  location: location
  properties: {
    hardwareProfile: vmHardwareProfile
    storageProfile: {
      osDisk: vmOsDiskProfile
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPublicSshKey
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicSshKey
            }
          ]
        }
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
  }
}

resource guestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2025-04-01' = {
  name: 'GuestAttestation'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.LinuxAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: substring('emptystring', 0, 0)
          maaTenantName: 'GuestAttestation'
        }
      }
    }
  }
}
