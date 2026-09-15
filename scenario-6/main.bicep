targetScope = 'subscription'

/*
  Scenario 6 - Private access to the Scenario 5 Key Vault
  ---------------------------------------------------------------------------
  Doesn't create a new Key Vault - it reaches back into whichever resource
  group and Key Vault YOUR Scenario 5 deployment created, and builds a
  private access path around it: a VNet, a Private DNS Zone, a Private
  Endpoint, and an A record. private-networking.bicep exists purely to
  cross the subscription -> resource-group scope boundary (see Scenario 4
  for the full explanation of why).

  Before you start: run scenario-6/01-nslookup-keyvault.ps1 against your
  Scenario 5 Key Vault name and note the (public) address it returns - then
  run it again after this deploys and compare.

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

@description('Workload code for the NEW networking resources created here - normally sourced from .env via readEnvironmentVariable() in main.bicepparam. Does not need to match the workload code you used for Scenario 5.')
param workloadCode string

@description('Name of the resource group YOUR Scenario 5 deployment created - copy it from that deployment\'s "resourceGroupName" output')
param existingResourceGroupName string

@description('Name of the Key Vault YOUR Scenario 5 deployment created - copy it from that deployment\'s "keyVaultName" output')
param existingKeyVaultName string

@description('Address space for the new VNet')
param vnetAddressPrefix string = '10.60.0.0/16'

@description('Address range for the private endpoints subnet')
param subnetAddressPrefix string = '10.60.0.0/24'

// --- Naming convention ------------------------------------------------------
// COMPANY_CODE-LOCATION_SHORT-ENV_CODE-WORKLOAD_CODE-01
// (Only used to name the NEW resources this scenario creates - the existing
// resource group and Key Vault keep whatever names Scenario 5 gave them.)

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

// --- Reference the existing Scenario 5 resource group ------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: existingResourceGroupName
}

// --- Private networking (thin module, deployed into the existing RG) --------

module privateNetworking './private-networking.bicep' = {
  name: 'deploy-private-net-${baseName}'
  scope: rg
  params: {
    baseName: baseName
    location: location
    keyVaultName: existingKeyVaultName
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
  }
}

output resourceGroupName string = rg.name
output vnetName string = privateNetworking.outputs.vnetName
output privateEndpointName string = privateNetworking.outputs.privateEndpointName
output privateDnsZoneName string = privateNetworking.outputs.privateDnsZoneName
output privateEndpointIp string = privateNetworking.outputs.privateEndpointIp
output keyVaultPrivateFqdn string = privateNetworking.outputs.keyVaultPrivateFqdn
