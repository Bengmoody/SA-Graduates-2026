<#
    Scenario 1 - Step 1: Connect to Azure
    ---------------------------------------
    Run this first. It opens a browser window so you can sign in with your
    Azure AD account, then shows which account/tenant/subscription you
    ended up connected to.
#>

try {
    Connect-AzAccount
}
catch {
    Write-Host "Something went wrong connecting to Azure: $_" -ForegroundColor Red
    throw
}

# Show who/what we're connected as
Get-AzContext
