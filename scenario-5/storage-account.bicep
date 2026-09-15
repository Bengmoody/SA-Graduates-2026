// Thin module - deployed into a resource group via `scope: rg` from
// main.bicep, same pattern as keyvault.bicep. Deliberately basic: not
// hardened, but not made public either - the "public" resource in this
// scenario is the Key Vault, not this.

@description('Name of the storage account to create (must be globally unique, lowercase alphanumeric only, 3-24 chars)')
param name string

@description('Azure region for the storage account')
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
