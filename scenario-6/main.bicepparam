using 'main.bicep'

param companyName = readEnvironmentVariable('COMPANY_CODE', 'sagrad')
param location = readEnvironmentVariable('LOCATION_CODE', 'uksouth')
param environment = readEnvironmentVariable('ENVIRONMENT_CODE', 'dev')

// Sourced from the WORKLOAD_CODE env var, same as every other scenario -
// names the NEW networking resources (VNet, private endpoint, DNS zone).
// This does NOT need to match the workload code you used for Scenario 5.
param workloadCode = readEnvironmentVariable('WORKLOAD_CODE', 'lab6')

// Point these at the resource group and Key Vault YOUR Scenario 5
// deployment created - copy them from its outputs (or look them up with
// Get-AzResourceGroup / Get-AzKeyVault if you didn't keep them).
param existingResourceGroupName = replace(readEnvironmentVariable('SCENARIO5_RESOURCE_GROUP_NAME', ''),'<workload>',workloadCode)
param existingKeyVaultName = replace(readEnvironmentVariable('SCENARIO5_KEY_VAULT_NAME', ''),'<workload>',workloadCode)
