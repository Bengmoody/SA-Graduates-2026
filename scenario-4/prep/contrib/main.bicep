targetScope = 'managementGroup'

/*
  Scenario 4 - Prep: Contributor role assignment at management group scope
  ---------------------------------------------------------------------------
  Grants the built-in "Contributor" role, at a target management group, to
  a specific Entra ID group (identified by its Object ID). Run this against
  whichever management group you want that group to have edit access over.

  This deploys at MANAGEMENT GROUP scope, not resource group or
  subscription scope, so it needs its own connect + deploy command - see
  the .txt file in scenario-4/prep/ for the full format.
*/

@description('Azure region required by New-AzManagementGroupDeployment for deployment metadata - no regional resources are created here')
param location string = 'uksouth'

@description('Object ID of the Entra ID group to grant Contributor access to')
param groupObjectId string

// Built-in "Contributor" role definition ID
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, groupObjectId, contributorRoleId)
  properties: {
    principalId: groupObjectId
    principalType: 'Group'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
  }
}

output roleAssignmentId string = contributorAssignment.id
