using 'main.bicep'

param companyName = readEnvironmentVariable('COMPANY_CODE', 'sagrad')
param location = readEnvironmentVariable('LOCATION_CODE', 'uksouth')
param environment = readEnvironmentVariable('ENVIRONMENT_CODE', 'dev')

// Sourced from the WORKLOAD_CODE env var, same as every other scenario -
// names the NEW resources (subnet, NSG, public IP, NIC, VM). This does NOT
// need to match the workload code you used for Scenario 5 or 6.
param workloadCode = readEnvironmentVariable('WORKLOAD_CODE', 'lab7')

// Point these at the resource group Scenario 5 created and the VNet
// Scenario 6 created inside it - copy them from those deployments'
// outputs (or Get-AzResourceGroup / Get-AzVirtualNetwork if you didn't
// keep them).
param existingResourceGroupName = replace(readEnvironmentVariable('SCENARIO5_RESOURCE_GROUP_NAME', ''),'<workload>',workloadCode)
param existingVnetName = replace(readEnvironmentVariable('SCENARIO6_VNET_NAME', ''),'<workload>',workloadCode)

// VM admin credentials - username/password only for now. No default for
// the password on purpose: set VM_ADMIN_PASSWORD in your .env rather than
// deploying with something guessable. Must be 12-123 characters with at
// least 3 of: uppercase, lowercase, digit, special character.
param adminUsername = readEnvironmentVariable('VM_ADMIN_USERNAME', 'labadmin')
param adminPassword = readEnvironmentVariable('VM_ADMIN_PASSWORD')

// Leave as "*" for a short-lived lab VM, or narrow it to your own IP
// (e.g. "203.0.113.42/32") if you're leaving this one running for a while.
param allowedRdpSourceAddressPrefix = readEnvironmentVariable('RDP_SOURCE_ADDRESS_PREFIX', '*')
