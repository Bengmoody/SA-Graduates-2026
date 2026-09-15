using 'main.bicep'

param companyName = readEnvironmentVariable('COMPANY_CODE', 'sagrad')
param location = readEnvironmentVariable('LOCATION_CODE', 'uksouth')
param environment = readEnvironmentVariable('ENVIRONMENT_CODE', 'dev')

// Sourced from the WORKLOAD_CODE env var (see .env next to this file) so you
// don't have to hardcode it here. Falls back to 'lab5' if it isn't set.
param workloadCode = readEnvironmentVariable('WORKLOAD_CODE', 'lab5')
