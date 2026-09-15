<#
    Scenario 1 - Step 3: Set your working subscription  (EXERCISE)
    -------------------------------------------------------------------
    Most tenants have several subscriptions attached, and almost
    everything you do with Az PowerShell operates against whichever
    subscription is "active" in your current context.

    This script pulls your subscriptions and filters down to one for you
    - your job is to fill in the bit that actually switches into it.
#>

# Pull all the subscriptions this account can see
$subscriptions = Get-AzSubscription

# For this exercise, just grab the first subscription in the list.
# In real life you'd usually filter by name instead, e.g.:
#   $subscriptions | Where-Object { $_.Name -eq "My Subscription Name" }
$sub = $subscriptions[0].Id

# ---------------------------------------------------------------------
# YOUR TURN
# Using the $sub variable above, add two lines below:
#   1. A Write-Host message telling us which subscription you're
#      connecting to, e.g. "connecting to subscription $sub"
#   2. A Set-AzContext call that switches your session into that
#      subscription
# ---------------------------------------------------------------------


