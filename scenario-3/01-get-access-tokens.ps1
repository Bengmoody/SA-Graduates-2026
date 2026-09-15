<#
    Scenario 2 - Step 1: Get access tokens for ARM and Microsoft Graph
    -----------------------------------------------------------------------
    Assumes you're already connected (Connect-AzAccount from Scenario 1).

    Az PowerShell can hand you a raw bearer token for any resource it
    knows about - useful when you want to call a REST API directly
    instead of going through a cmdlet.
#>

# A token scoped to Azure Resource Manager (management.azure.com)
$mgmtToken = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"

# A token scoped to Microsoft Graph (graph.microsoft.com)
$graphToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/"

# Newer versions of the Az.Accounts module return the token as a
# SecureString rather than plain text. This helper unwraps it either way,
# so the rest of this scenario works regardless of which Az version
# you've got installed.
function ConvertFrom-AzToken {
    param($Token)
    if ($Token -is [System.Security.SecureString]) {
        return [System.Net.NetworkCredential]::new('', $Token).Password
    }
    return $Token
}

$mgmtTokenPlain  = ConvertFrom-AzToken $mgmtToken.Token
$graphTokenPlain = ConvertFrom-AzToken $graphToken.Token

Write-Host "Got a management.azure.com token, expires $($mgmtToken.ExpiresOn)"
Write-Host "Got a graph.microsoft.com token, expires $($graphToken.ExpiresOn)"

# Treat these like passwords - don't Write-Host the tokens themselves.
# 02-query-groups-via-graph-api.ps1 and 03-query-keyvaults-via-arm-api.ps1
# expect $graphTokenPlain / $mgmtTokenPlain to already be set, so either
# run this script first in the same session, or paste the lines above
# into the top of those scripts.
