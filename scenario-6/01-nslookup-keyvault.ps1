<#
  Scenario 6 - nslookup a Key Vault
  ---------------------------------------------------------------------------
  Small script to look up the DNS record for a Key Vault's public URL -
  run it BEFORE and AFTER you deploy the private endpoint in this scenario
  (main.bicep) so you can see whether the answer changes.

  Usage:
    .\01-nslookup-keyvault.ps1 -KeyVaultName "kv-sagrad-uks-d-yourcode-01"
#>

param(
    [Parameter(Mandatory)]
    [string]$KeyVaultName
)

$fqdn = "$KeyVaultName.vault.azure.net"

Write-Host "Looking up: $fqdn" -ForegroundColor Cyan
nslookup $fqdn

Write-Host ""
Write-Host "What to look for:" -ForegroundColor Yellow
Write-Host " - Before the private endpoint exists, the Address returned is a PUBLIC Azure IP."
Write-Host " - After deploying main.bicep, try this again from a machine INSIDE the new VNet -"
Write-Host "   the address should now be a PRIVATE one (10.60.x.x)."
Write-Host " - Try it again from your own laptop, outside the VNet - it will probably still show"
Write-Host "   the PUBLIC address. The private DNS zone is only linked to that one VNet, so nothing"
Write-Host "   else knows to use it yet. That's the DNS 'gotcha' worth remembering."
