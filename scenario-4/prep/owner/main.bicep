targetScope = 'managementGroup'

/*
  Scenario 4 - Prep: Owner role assignment at management group scope
  ---------------------------------------------------------------------------
  Grants the built-in "Owner" role, at a target management group, to a
  specific Entra ID group (identified by its Object ID). Run this against
  whichever management group you want that group to have full control
  over - use with care, Owner includes the ability to grant access to
  others.

  This deploys at MANAGEMENT GROUP scope, not resource group or
  subscription scope, so it needs its own connect + deploy command - see
  the .txt file in scenario-4/prep/ for the full format.
*/

@description('Azure region required by New-AzManagementGroupDeployment for deployment metadata - no regional resources are created here')
param location string = 'uksouth'

@description('Object ID of the Entra ID group to grant Owner access to')
param groupObjectId string

// Built-in "Owner" role definition ID
var ownerRoleId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

resource ownerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, groupObjectId, ownerRoleId)
  properties: {
    principalId: groupObjectId
    principalType: 'Group'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', ownerRoleId)
  }
}

output roleAssignmentId string = ownerAssignment.id
