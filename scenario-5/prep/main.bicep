targetScope = 'subscription'

/*
  Scenario 5 - Prep: lab guardrail policies
  ---------------------------------------------------------------------------
  Run this BEFORE the group starts Scenario 5 - it deploys two policies
  against the subscription that change what they'll see when they deploy
  their storage account and Key Vault:

    1. Denies any Microsoft.Storage/storageAccounts deployment outright.
    2. Silently sets publicNetworkAccess to Disabled on any Key Vault
       deployed afterwards (a Modify-effect policy - needs its own managed
       identity + role assignment to actually remediate, not just flag).

  Deploy:

    Set-AzContext -SubscriptionId '3c98126a-f53e-41ca-b88c-cdce69d72fc7'
    New-AzSubscriptionDeployment `
      -Location $location `
      -TemplateFile main.bicep `
      -TemplateParameterFile main.bicepparam

  To clean up afterwards, so the subscription is reset for the next
  cohort:

    Remove-AzPolicyAssignment -Name 'deny-storage-accounts'
    Remove-AzPolicyAssignment -Name 'modify-kv-public-access'
    Remove-AzPolicyDefinition -Name 'deny-storage-account-deployments' -Force
    Remove-AzPolicyDefinition -Name 'modify-keyvault-disable-public-access' -Force
    Remove-AzRoleAssignment -ObjectId <modifyAssignmentPrincipalId output> `
      -RoleDefinitionName 'Key Vault Contributor' `
      -Scope "/subscriptions/3c98126a-f53e-41ca-b88c-cdce69d72fc7"
*/

@description('Azure region used for the policy assignment identity')
@allowed([
  'uksouth'
  'ukwest'
  'westeurope'
  'northeurope'
])
param location string = 'uksouth'

// Built-in "Key Vault Contributor" role - needed so the Modify policy's
// managed identity can actually change a Key Vault's properties, not just
// evaluate whether it should.
var keyVaultContributorRoleId = 'f25e0fa2-a7c8-4377-a976-54943a77a395'

// --- Policy 1: deny storage account deployments ------------------------------

resource denyStorageAccountsPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'deny-storage-account-deployments'
  properties: {
    displayName: 'Deny Storage Account deployments'
    description: 'Blocks creation of any Microsoft.Storage/storageAccounts resource in scope, for this lab.'
    policyType: 'Custom'
    mode: 'All'
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Storage/storageAccounts'
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource denyStorageAccountsAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'deny-storage-accounts'
  properties: {
    displayName: 'Deny Storage Account deployments'
    policyDefinitionId: denyStorageAccountsPolicy.id
  }
}

// --- Policy 2: modify incoming Key Vaults to disable public access -----------

resource modifyKeyVaultPublicAccessPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'modify-keyvault-disable-public-access'
  properties: {
    displayName: 'Turn off public network access on Key Vaults'
    description: 'Automatically sets publicNetworkAccess to Disabled on any Key Vault deployed in scope, for this lab.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.KeyVault/vaults'
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultContributorRoleId)
          ]
          operations: [
            {
              operation: 'addOrReplace'
              field: 'Microsoft.KeyVault/vaults/publicNetworkAccess'
              value: 'Disabled'
            }
          ]
        }
      }
    }
  }
}

resource modifyKeyVaultPublicAccessAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'modify-kv-public-access'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Turn off public network access on Key Vaults'
    policyDefinitionId: modifyKeyVaultPublicAccessPolicy.id
  }
}

// Grant the assignment's managed identity permission to actually modify Key
// Vaults - without this, the Modify effect can evaluate but can't remediate.
// Note: it can take a few minutes after this deploys before the identity is
// usable everywhere - a known Azure AD propagation delay, not a bug here.
resource kvContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'modify-kv-public-access', keyVaultContributorRoleId)
  properties: {
    principalId: modifyKeyVaultPublicAccessAssignment.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultContributorRoleId)
  }
}

output modifyAssignmentPrincipalId string = modifyKeyVaultPublicAccessAssignment.identity.principalId
