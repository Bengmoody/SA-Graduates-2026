using 'main.bicep'

param location = readEnvironmentVariable('LOCATION_CODE', 'uksouth')

// Replace with the Object ID of the Entra ID group you want to grant
// Reader access to, at this management group.
param groupObjectId = '<REPLACE-WITH-GROUP-OBJECT-ID>'
