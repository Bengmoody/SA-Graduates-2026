targetScope = 'subscription'

/*
  Scenario 5 - Deploy a storage account and a public Key Vault
  ---------------------------------------------------------------------------
  Same naming-convention and thin-module pattern as Scenario 4: create a
  resource group, then deploy a Storage Account and a public,
  RBAC-authorised Key Vault into it. storage-account.bicep and
  keyvault.bicep exist purely to cross the subscription -> resource-group
  scope boundary (see Scenario 4 for the full explanation of why).

  Before running this, check whether your instructor has deployed the
  guardrail policies in prep/ against this subscription - if so, don't be
  surprised if this deployment doesn't do quite what you expect.

  Deploy (from a PowerShell session already connected - see Scenario 2):

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

@description('Workload code identifying what this deployment is for - normally sourced from .env via readEnvironmentVariable() in main.bicepparam')
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

// Storage account names can't contain hyphens and are capped at 24 chars,
// so we strip and truncate rather than use baseName directly.
var storageAccountName = take(toLower('st${replace(baseName, '-', '')}'), 24)

// --- Resource group ----------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${baseName}'
  location: location
}

// --- Storage account (thin module, deployed into the new resource group) -----

module storageAccountDeploy './storage-account.bicep' = {
  name: 'deploy-st-${baseName}'
  scope: rg
  params: {
    name: storageAccountName
    location: location
  }
}

// --- Key Vault (thin module, deployed into the new resource group) -----------
// Public, RBAC-authorised, no purge protection - same as Scenario 4.

module keyVaultDeploy './keyvault.bicep' = {
  name: 'deploy-kv-${baseName}'
  scope: rg
  params: {
    name: 'kv-${baseName}'
    location: location
  }
}

output resourceGroupName string = rg.name
output storageAccountName string = storageAccountDeploy.outputs.storageAccountName
output keyVaultName string = keyVaultDeploy.outputs.keyVaultName
output keyVaultUri string = keyVaultDeploy.outputs.keyVaultUri
