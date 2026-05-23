// =============================================================
//  Secure Azure Landing Zone - main deployment
//  Deploys: VNet + subnet, NSG, locked-down Storage Account,
//           and a free-tier-eligible Linux VM (B1s).
//  Scope: resource group
// =============================================================

targetScope = 'resourceGroup'

// ---------- Parameters ----------

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Short name prefix for resources (3-10 lowercase letters/numbers).')
@minLength(3)
@maxLength(10)
param namePrefix string = 'labz'

@description('Environment tag value, e.g. dev / demo / prod.')
@allowed([
  'dev'
  'demo'
  'prod'
])
param environment string = 'demo'

@description('Admin username for the Linux VM.')
param adminUsername string

@description('SSH public key for the Linux VM. Paste the contents of your ~/.ssh/id_rsa.pub here.')
@secure()
param adminSshPublicKey string

@description('Your current public IP in CIDR form (e.g. 203.0.113.5/32) so only you can SSH in. Leave as 0.0.0.0/0 only for quick testing.')
param allowedSshSourceCidr string = '0.0.0.0/0'

// ---------- Variables ----------

var commonTags = {
  project: 'azure-bicep-landing-zone'
  environment: environment
  managedBy: 'bicep'
  costCenter: 'portfolio-demo'
}

// Storage account names must be globally unique, 3-24 chars, lowercase + numbers only.
var storageAccountName = toLower('${namePrefix}stg${uniqueString(resourceGroup().id)}')

// ---------- Network module ----------

module network 'modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
    namePrefix: namePrefix
    allowedSshSourceCidr: allowedSshSourceCidr
    tags: commonTags
  }
}

// ---------- Storage module ----------

module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    subnetId: network.outputs.appSubnetId
    tags: commonTags
  }
}

// ---------- Compute module ----------

module compute 'modules/compute.bicep' = {
  name: 'computeDeployment'
  params: {
    location: location
    namePrefix: namePrefix
    subnetId: network.outputs.appSubnetId
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    tags: commonTags
  }
}

// ---------- Outputs ----------

@description('Public IP address of the deployed VM (use to SSH in).')
output vmPublicIp string = compute.outputs.publicIpAddress

@description('Name of the storage account created.')
output storageAccountName string = storage.outputs.storageAccountName

@description('Resource ID of the virtual network.')
output vnetId string = network.outputs.vnetId
