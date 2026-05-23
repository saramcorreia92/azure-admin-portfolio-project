// =============================================================
//  Storage module
//  Creates a Standard_LRS storage account locked down so that
//  only the app subnet (via service endpoint) can reach it.
//  Public blob access is disabled and HTTPS is enforced.
// =============================================================

@description('Azure region.')
param location string

@description('Globally unique storage account name (3-24 lowercase alphanumeric).')
param storageAccountName string

@description('Resource ID of the subnet allowed to access this account.')
param subnetId string

@description('Tags applied to all resources.')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      // Deny by default; only the named subnet may connect.
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetId
          action: 'Allow'
        }
      ]
    }
  }
}

@description('Name of the storage account.')
output storageAccountName string = storageAccount.name
