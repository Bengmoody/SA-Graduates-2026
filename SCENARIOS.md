# Scenario Overview

This document describes each hands-on scenario in this repo: what you'll
learn, and what you need in place before you start. Work through them in
order — later scenarios build on skills from earlier ones.

---

## Scenario 1 — Exploring the directory with Microsoft Graph

**Folder:** [`scenario-1/`](./scenario-1)

**Learning objective:**
Get comfortable connecting to Microsoft Graph and querying Entra ID
directory objects: sign in with `Connect-MgGraph`, list users and groups
with `Get-MgUser` / `Get-MgGroup`, then find your own object ID by
filtering users down to the one whose UPN matches your email address —
and use it to look up your own group memberships.

**Prerequisites:**
- The `Microsoft.Graph` module installed (see
  [`utilities/useful-cmdlets.md`](./utilities/useful-cmdlets.md) section
  8 for the install command and `Connect-MgGraph` background)
- An Entra ID account with at least read access to users and groups

---

## Scenario 2 — Connecting to Azure with PowerShell

**Folder:** [`scenario-2/`](./scenario-2)

**Learning objective:**
Get comfortable with the basic PowerShell + Az module workflow for
authenticating to Azure and working with the right subscription: signing
in, listing the subscriptions you have access to, and switching your
session's active context into a specific one. This is the foundation
almost every other script in this repo builds on.
Then...
> Find the Key Vault!

**Prerequisites:**
- PowerShell installed, with the `Az` module available (see
  [`utilities/useful-cmdlets.md`](./utilities/useful-cmdlets.md) for the
  `Install-Module -Scope CurrentUser` install command)
- An Azure account with access to at least one subscription
- Comfortable opening a PowerShell terminal and running a `.ps1` script

---

## Scenario 3 — Calling Azure REST APIs directly with access tokens

**Folder:** [`scenario-3/`](./scenario-3)

**Learning objective:**
Understand what's actually happening underneath the Az/Graph cmdlets by
calling the REST APIs directly: get a bearer token for a specific
resource with `Get-AzAccessToken -ResourceUrl`, then use that token with
`Invoke-WebRequest` to query Entra ID groups (via Microsoft Graph) and
Key Vaults (via Azure Resource Manager). Useful for the (frequent) cases
where there isn't a ready-made cmdlet for what you need.

**Prerequisites:**
- Completed Scenario 2 (a connected Az PowerShell session)
- An Azure account with access to at least one subscription containing a
  Key Vault (the script still runs fine and just returns an empty list if
  not — nothing breaks)

---

## Scenario 4 — Deploying a Key Vault with Bicep, using a naming convention

**Folder:** [`scenario-4/naked-resource/`](./scenario-4/naked-resource)

**Learning objective:**
Deploy real infrastructure with Bicep instead of clicking through the
portal: parameterise company, location and environment, derive a
naming-convention variable in the form
`COMPANY_CODE-LOCATION_SHORT-ENV_CODE-WORKLOAD_CODE-01`, and deploy a
basic, public, RBAC-authorised Key Vault into its own resource group
using a plain `resource` block (no module) at subscription scope. This
"naked resource" version is deliberately basic — a module-based option
for comparison will be added alongside it.

**Prerequisites:**
- Completed Scenario 2 (a connected Az PowerShell session)
- Bicep installed (bundled with a recent Az CLI / `az bicep install`, or
  the Bicep VS Code extension)
- Access to subscription `3c98126a-f53e-41ca-b88c-cdce69d72fc7`
- Familiar with `.env` / `Load-EnvFile` from
  [`utilities/edit-profile.ps1`](./utilities/edit-profile.ps1) — this
  scenario's `.env` supplies the workload code used in the naming
  convention

---

## Scenario 5 — Storage account + public Key Vault, with a twist

**Folder:** [`scenario-5/`](./scenario-5)

**Learning objective:**
Apply the same naming-convention and thin-module pattern from Scenario 4
to a second resource type: deploy a storage account and a public,
RBAC-authorised Key Vault side by side, into one resource group. Then see
what happens when governance gets in the way of a deployment you thought
was straightforward.

**Instructor prep:** before running this with the group, deploy the two
guardrail policies in [`scenario-5/prep/`](./scenario-5/prep) against the
subscription — one denies any Storage Account deployment outright, the
other silently switches `publicNetworkAccess` to `Disabled` on any Key
Vault created afterwards. Graduates will hit the deny on their storage
account and see their "public" Key Vault come up locked down — a live
example of policy enforcement, not just theory.

**Prerequisites:**
- Completed Scenario 4 (comfortable with the naming convention and the
  thin-module pattern used here)
- Access to subscription `3c98126a-f53e-41ca-b88c-cdce69d72fc7`

---

## Scenario 6 — Putting the Key Vault from Scenario 5 behind a private endpoint

**Folder:** [`scenario-6/`](./scenario-6)

**Learning objective:**
Take the Key Vault your Scenario 5 deployment created and give it a private
access path: a VNet, a Private DNS Zone, a Private Endpoint, and an A
record linking the two together. Use
[`01-nslookup-keyvault.ps1`](./scenario-6/01-nslookup-keyvault.ps1) before
and after deploying to see the vault's address change — and to discover
why it *doesn't* change everywhere you'd expect it to (a nice, concrete
follow-up to the DNS/nslookup slides).

**Prerequisites:**
- A completed Scenario 5 deployment (this scenario doesn't create its own
  Key Vault — it reaches into the resource group and Key Vault Scenario 5
  made, so keep that deployment's `resourceGroupName` and `keyVaultName`
  outputs handy)
- Completed Scenario 4 (comfortable with the naming convention and the
  thin-module pattern used here)
- Access to subscription `3c98126a-f53e-41ca-b88c-cdce69d72fc7`

---

*More scenarios will be added here as they're built.*
