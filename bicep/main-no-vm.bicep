targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(10)
param namePrefix string = 'labz'

@allowed([ 'dev', 'demo', 'prod' ])
param environment string = 'demo'

@description('Your public IP in CIDR form, used by the NSG rule (least-privilege design).')
param allowedSshSourceCidr string = '0.0.0.0/0'

var commonTags = {
  project: 'azure-bicep-landing-zone'
  environment: environment
  managedBy: 'bicep'
  costCenter: 'portfolio-demo'
}

var storageAccountName = toLower('${namePrefix}stg${uniqueString(resourceGroup().id)}')

module network 'modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
    namePrefix: namePrefix
    allowedSshSourceCidr: allowedSshSourceCidr
    tags: commonTags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    subnetId: network.outputs.appSubnetId
    tags: commonTags
  }
}

output storageAccountName string = storage.outputs.storageAccountName
output vnetId string = network.outputs.vnetId
output appSubnetId string = network.outputs.appSubnetId
