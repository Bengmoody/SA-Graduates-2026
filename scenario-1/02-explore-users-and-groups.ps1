<#
    Scenario 3 - Step 2: Explore users and groups
    -------------------------------------------------
    A first look at two of the most commonly used Graph cmdlets.
#>

# List a handful of users in the tenant
Get-MgUser -Top 10 | Select-Object DisplayName, UserPrincipalName, Id | Format-Table -AutoSize

# List a handful of groups in the tenant
Get-MgGroup -Top 10 | Select-Object DisplayName, Id | Format-Table -AutoSize
