param name string
param staticIp string
param vnetId string

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name

  resource aRecord 'A' = {
    name: '*.${name}'
    properties: {
      aRecords: [
        {
          ipv4Address: staticIp
        }
      ]
      
    }
  }

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'container-apps-vnet-link'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetId
      }
    }
  }

}
