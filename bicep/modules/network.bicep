// =============================================================
//  Network module
//  Creates a VNet with one subnet and a Network Security Group.
//  The NSG allows SSH only from a specified source CIDR.
// =============================================================

@description('Azure region.')
param location string

@description('Resource name prefix.')
param namePrefix string

@description('Source CIDR allowed to reach SSH (port 22).')
param allowedSshSourceCidr string

@description('Tags applied to all resources.')
param tags object

// Network Security Group - default-deny inbound, allow only SSH from our IP.
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${namePrefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-Inbound'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedSshSourceCidr
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${namePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          // Service endpoint lets the storage account trust traffic from this subnet.
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

@description('Resource ID of the app subnet.')
output appSubnetId string = vnet.properties.subnets[0].id

@description('Resource ID of the virtual network.')
output vnetId string = vnet.id
