targetScope = 'managementGroup'

/*
  Scenario 4 - Prep: Reader role assignment at management group scope
  ---------------------------------------------------------------------------
  Grants the built-in "Reader" role, at a target management group, to a
  specific Entra ID group (identified by its Object ID). Run this against
  whichever management group you want that group to have read-only
  visibility over.

  This deploys at MANAGEMENT GROUP scope, not resource group or
  subscription scope, so it needs its own connect + deploy command - see
  the .txt file in scenario-4/prep/ for the full format.
*/

@description('Azure region required by New-AzManagementGroupDeployment for deployment metadata - no regional resources are created here')
param location string = 'uksouth'

@description('Object ID of the Entra ID group to grant Reader access to')
param groupObjectId string

// Built-in "Reader" role definition ID
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource readerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, groupObjectId, readerRoleId)
  properties: {
    principalId: groupObjectId
    principalType: 'Group'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
  }
}

output roleAssignmentId string = readerAssignment.id
