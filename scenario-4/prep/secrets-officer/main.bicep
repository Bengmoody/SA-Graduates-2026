targetScope = 'managementGroup'

/*
  Scenario 4 - Prep: Key Vault Secrets Officer role assignment at management
  group scope
  ---------------------------------------------------------------------------
  Grants the built-in "Key Vault Secrets Officer" role, at a target
  management group, to a specific Entra ID group (identified by its Object
  ID). Unlike Reader/Contributor/Owner, this one is Key-Vault-specific: it
  lets the group manage secrets (get/list/set/delete) in any Key Vault
  under that management group that uses RBAC authorization, without
  granting broader Contributor/Owner rights over the vault resource itself
  or anything else in scope.

  This deploys at MANAGEMENT GROUP scope, not resource group or
  subscription scope, so it needs its own connect + deploy command - see
  the .txt file in scenario-4/prep/ for the full format.
*/

@description('Azure region required by New-AzManagementGroupDeployment for deployment metadata - no regional resources are created here')
param location string = 'uksouth'

@description('Object ID of the Entra ID group to grant Key Vault Secrets Officer access to')
param groupObjectId string

// Built-in "Key Vault Secrets Officer" role definition ID
var keyVaultSecretsOfficerRoleId = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

resource secretsOfficerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, groupObjectId, keyVaultSecretsOfficerRoleId)
  properties: {
    principalId: groupObjectId
    principalType: 'Group'
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsOfficerRoleId)
  }
}

output roleAssignmentId string = secretsOfficerAssignment.id
