<#
    Scenario 3 - Step 3: Find your own object ID  (EXERCISE)
    -----------------------------------------------------------
    Every user (and group, and app registration) in Entra ID has a unique
    Object ID - it's what most Graph/Az cmdlets actually want under the
    hood when you point them at "a user" or "a group".

    This script pulls every user in the tenant and filters down to the
    one whose UserPrincipalName matches your own email address - your job
    is to fill in what happens once you've found it.
#>

# Set this to your own email address / UPN
$myUpn = "you@simpson-associates.co.uk"

# Pull every user, then filter down to the one that matches $myUpn
$allUsers = Get-MgUser -All
$me = $allUsers | Where-Object { $_.UserPrincipalName -eq $myUpn }
$objectId = $me.Id

# ---------------------------------------------------------------------
# YOUR TURN
# Using the $objectId variable above, add two lines below:
#   1. A Write-Host message confirming the object ID you found, e.g.
#      "found object ID $objectId for $myUpn"
#   2. A call to Get-MgUserMemberOf -UserId $objectId to list the groups
#      (and roles) that user belongs to
# ---------------------------------------------------------------------


