using 'main.bicep'

param companyName = readEnvironmentVariable('COMPANY_CODE','sagrad')
param location = readEnvironmentVariable('LOCATION_CODE','uksouth')
param environment = readEnvironmentVariable('ENVIRONMENT_CODE', 'dev')

// Sourced from the WORKLOAD_CODE env var (see .env next to this file, and
// utilities/edit-profile.ps1 -> Load-EnvFile) so you don't have to hardcode
// it here. Falls back to 'kv' if it isn't set.
param workloadCode = readEnvironmentVariable('WORKLOAD_CODE', 'kv')

