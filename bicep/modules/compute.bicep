// =============================================================
//  Compute module
//  Creates a free-tier-eligible Linux VM (Standard_B1s),
//  a public IP, and a NIC. Uses SSH key auth only (no passwords).
// =============================================================

@description('Azure region.')
param location string

@description('Resource name prefix.')
param namePrefix string

@description('Resource ID of the subnet to attach the NIC to.')
param subnetId string

@description('Admin username.')
param adminUsername string

@description('SSH public key contents.')
@secure()
param adminSshPublicKey string

@description('Tags applied to all resources.')
param tags object

// Standard_B1s is eligible for the Azure free account 750 hours/month allowance.
var vmSize = 'Standard_B1s'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${namePrefix}-vm-pip'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${namePrefix}-vm-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: '${namePrefix}-vm'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${namePrefix}vm'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

@description('Public IP address assigned to the VM.')
output publicIpAddress string = publicIp.properties.ipAddress
