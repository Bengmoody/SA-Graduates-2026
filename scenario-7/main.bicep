targetScope = 'subscription'

/*
  Scenario 7 - A jump-box VM in the Scenario 6 VNet
  ---------------------------------------------------------------------------
  Doesn't create a new VNet - it reaches back into whichever resource group
  and VNet YOUR Scenario 6 deployment created, adds a new subnet to that
  VNet, and drops a Windows VM into it with a direct public IP and RDP
  open. vm.bicep exists purely to cross the subscription -> resource-group
  scope boundary (see Scenario 4 for the full explanation of why).

  Username/password auth only for now, B-series VM size to keep costs down,
  and RDP wide open to whatever you set allowedRdpSourceAddressPrefix to
  (default "*"). Remember to deallocate the VM when you're done with it -
  a B2s left running is cheap, but it's not free, and there's nothing in
  this template that shuts it down for you:

    Stop-AzVM -ResourceGroupName <rg> -Name <vmName> -Force

  Deploy (from a PowerShell session already connected - see Scenario 2):

    Set-AzContext -SubscriptionId '3c98126a-f53e-41ca-b88c-cdce69d72fc7'
    New-AzSubscriptionDeployment `
      -Location $location `
      -TemplateFile main.bicep `
      -TemplateParameterFile main.bicepparam
*/

@description('Short company code used in resource naming, e.g. "sa" for Simpson Associates')
param companyName string = 'sa'

@description('Azure region to deploy into - must match the region the Scenario 6 VNet is already in')
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

@description('Workload code for the NEW resources created here (subnet, NSG, public IP, NIC, VM) - normally sourced from .env via readEnvironmentVariable() in main.bicepparam. Does not need to match the workload code you used for Scenario 5 or 6.')
param workloadCode string

@description('Name of the resource group YOUR Scenario 5 deployment created - copy it from that deployment\'s "resourceGroupName" output (Scenario 6 deployed its VNet into the same resource group)')
param existingResourceGroupName string

@description('Name of the VNet YOUR Scenario 6 deployment created - copy it from that deployment\'s "vnetName" output')
param existingVnetName string

@description('Address range for the new VM subnet - must not overlap the private-endpoints subnet from Scenario 6 (10.60.0.0/24 by default)')
param subnetAddressPrefix string = '10.60.1.0/24'

@description('B-series VM size, to keep costs down')
param vmSize string = 'Standard_B2s'

@description('Local admin username for the VM')
param adminUsername string

@secure()
@minLength(12)
@description('Local admin password for the VM. Azure requires 12-123 characters and at least 3 of: uppercase, lowercase, digit, special character.')
param adminPassword string

@description('Source address range allowed to RDP in. Defaults to "*" (anywhere) - see vm.bicep for why you might not want to leave that as-is.')
param allowedRdpSourceAddressPrefix string = '*'

// --- Naming convention ------------------------------------------------------
// COMPANY_CODE-LOCATION_SHORT-ENV_CODE-WORKLOAD_CODE-01
// (Only used to name the NEW resources this scenario creates - the existing
// resource group and VNet keep whatever names Scenario 5 / 6 gave them.)

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

// --- VM (thin module, deployed into the existing RG) -------------------------

module vmDeploy './vm.bicep' = {
  name: 'deploy-vm-${baseName}'
  scope: rg
  params: {
    baseName: baseName
    location: location
    existingVnetName: existingVnetName
    subnetAddressPrefix: subnetAddressPrefix
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    allowedRdpSourceAddressPrefix: allowedRdpSourceAddressPrefix
  }
}

output resourceGroupName string = rg.name
output vmName string = vmDeploy.outputs.vmName
output subnetName string = vmDeploy.outputs.subnetName
output publicIpAddress string = vmDeploy.outputs.publicIpAddress
