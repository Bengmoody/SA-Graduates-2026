// Thin module - deployed into a resource group via `scope: rg` from
// main.bicep, since a subscription-scoped template can't create a
// resource-group-scoped resource directly. Deliberately minimal: same
// public, RBAC-authorised, no-purge-protection Key Vault as before, just
// wrapped so it can cross that scope boundary.

@description('Name of the Key Vault to create')
param name string

@description('Azure region for the Key Vault')
param location string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output keyVaultName string = kv.name
output keyVaultUri string = kv.properties.vaultUri
