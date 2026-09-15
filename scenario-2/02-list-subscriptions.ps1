<#
    Scenario 1 - Step 2: List your subscriptions
    ---------------------------------------------
    Once you're connected, this shows every subscription your account has
    access to. You'll use this in Step 3 to pick one to work in.
#>

$subscriptions = Get-AzSubscription

$subscriptions | Select-Object Name, Id, State | Format-Table -AutoSize
