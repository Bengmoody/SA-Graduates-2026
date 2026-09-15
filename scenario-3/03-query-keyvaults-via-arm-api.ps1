<#
    Scenario 2 - Step 3: Query Key Vaults via the Azure Resource Manager REST API
    ---------------------------------------------------------------------------------
    Run 01-get-access-tokens.ps1 first, in the same session, so
    $mgmtTokenPlain is set.

    Same pattern as Step 2 - bearer token + Invoke-WebRequest - just a
    different base URL and a different token audience (ARM instead of
    Graph).
#>

$headers = @{
    Authorization = "Bearer $mgmtTokenPlain"
}

$subscriptionId = (Get-AzContext).Subscription.Id

$uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.KeyVault/vaults?api-version=2022-07-01"

$response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get

$vaults = ($response.Content | ConvertFrom-Json).value

$vaults | Select-Object name, location | Format-Table -AutoSize

# Find the key vault!