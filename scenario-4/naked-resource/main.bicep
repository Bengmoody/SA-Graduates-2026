targetScope = 'subscription'

/*
  Scenario 4 (Option 1) - Deploy a basic Key Vault as a "naked" resource
  ---------------------------------------------------------------------------
  A single subscription-scoped template that creates a resource group and a
  public, RBAC-authorised Key Vault inside it.

  The Key Vault itself is still a plain, minimal `resource` - no AVM/verified
  module - but it now lives in keyvault.bicep behind a thin module wrapper.
  That's not a design choice, it's a scope limitation: `scope` on a normal
  `resource` only works for extension resources (locks, role assignments,
  etc). A subscription-scoped template can't hand a resource-group-scoped
  resource type (like a Key Vault) its own scope directly - the only way to
  cross that boundary is a `module`, which compiles down to its own nested
  deployment targeting that resource group. keyvault.bicep exists purely to
  get us across that line.

  Deploy (from a PowerShell session already connected - see Scenario 1):

    Set-AzContext -SubscriptionId '3c98126a-f53e-41ca-b88c-cdce69d72fc7'
    New-AzSubscriptionDeployment `
      -Location $location `
      -TemplateFile main.bicep `
      -TemplateParameterFile main.bicepparam
*/

@description('Short company code used in resource naming, e.g. "sa" for Simpson Associates')
param companyName string = 'sa'

@description('Azure region to deploy into')
@allowed([
  'uksouth'
  'ukwest'
  'westeurope'
  'northeurope'
])
param location string = 'uksouth'

@description('Environment short name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Workload code identifying what this deployment is for (e.g. "kv" for a Key Vault) - normally sourced from .env via readEnvironmentVariable() in main.bicepparam')
param workloadCode string

// --- Naming convention ------------------------------------------------------
// COMPANY_CODE-LOCATION_SHORT-ENV_CODE-WORKLOAD_CODE-01

var locationShortCodes = {
  uksouth: 'uks'
  ukwest: 'ukw'
  westeurope: 'weu'
  northeurope: 'neu'
}

var environmentCodes = {
  dev: 'd'
  test: 't'
  prod: 'p'
}

var baseName = '${companyName}-${locationShortCodes[location]}-${environmentCodes[environment]}-${workloadCode}-01'

// --- Resource group ----------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${baseName}'
  location: location
}

// --- Key Vault (thin module, deployed into the new resource group) -----------
// Public, RBAC-authorised, no purge protection - deliberately basic for this
// lab. Compare this against a proper (AVM) module-based version later.
// scope: rg deploys keyvault.bicep as a nested deployment targeting the
// resource group created above, rather than the subscription this file
// itself targets.

module keyVault './keyvault.bicep' = {
  name: 'deploy-kv-${baseName}'
  scope: rg
  params: {
    name: 'kv-${baseName}'
    location: location
  }
}

output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
