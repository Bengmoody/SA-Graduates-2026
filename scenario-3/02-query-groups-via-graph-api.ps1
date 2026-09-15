<#
    Scenario 2 - Step 2: Query Entra ID groups via the Graph REST API
    --------------------------------------------------------------------
    Run 01-get-access-tokens.ps1 first, in the same session, so
    $graphTokenPlain is set.

    This calls Microsoft Graph directly with Invoke-WebRequest instead of
    a Get-Mg* cmdlet - same data, but you can see exactly what's being
    sent and received.
#>

$headers = @{
    Authorization = "Bearer $graphTokenPlain"
}

$response = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/groups" -Headers $headers -Method Get

$groups = ($response.Content | ConvertFrom-Json).value

$groups | Select-Object displayName, id | Format-Table -AutoSize
