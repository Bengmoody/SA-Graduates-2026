<#
    Scenario 3 - Step 1: Connect to Microsoft Graph
    ---------------------------------------------------
    See utilities/useful-cmdlets.md, section 8, for background on
    Connect-MgGraph and why Graph uses scopes rather than subscriptions.
#>

Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"

# Confirm who you're connected as and which scopes you actually have
Get-MgContext
