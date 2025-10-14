// Per https://github.com/microsoft/azure-container-apps/issues/1542, DigiCert's IPs must be allowed access to the
// app in order for managed certificates to be issued. The list here was generated from 
// https://knowledge.digicert.com/alerts/ip-address-domain-validation. 
output digiCertIpRules array = [
  {
    name: 'DigiCert IP 1'
    action: 'Allow'
    ipAddressRange: '216.168.249.9'
  }
  {
    name: 'DigiCert IP 2'
    action: 'Allow'
    ipAddressRange: '216.168.240.4'
  }
  {
    name: 'DigiCert IP 3'
    action: 'Allow'
    ipAddressRange: '216.168.247.9'
  }
  {
    name: 'DigiCert IP 4'
    action: 'Allow'
    ipAddressRange: '202.65.16.4'
  }
  {
    name: 'DigiCert IP 5'
    action: 'Allow'
    ipAddressRange: '54.185.245.130'
  }
  {
    name: 'DigiCert IP 6'
    action: 'Allow'
    ipAddressRange: '13.58.90.0'
  }
  {
    name: 'DigiCert IP 7'
    action: 'Allow'
    ipAddressRange: '52.17.48.104'
  }
  {
    name: 'DigiCert IP 8'
    action: 'Allow'
    ipAddressRange: '18.193.239.14'
  }
  {
    name: 'DigiCert IP 9'
    action: 'Allow'
    ipAddressRange: '54.227.165.213'
  }
  {
    name: 'DigiCert IP 10'
    action: 'Allow'
    ipAddressRange: '54.241.89.140'
  }
]
