# PowerShell & Az CLI Cheatsheet

A quick-reference for the cmdlets and commands you'll use constantly across
these labs. Keep this open in a second window while you work through the
scenarios.

---

## PowerShell

### 1. Getting set up: installing modules without local admin

Most Az PowerShell cmdlets live in a module (`Az`) that isn't installed by
default. Install it with:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

**Why `-Scope CurrentUser`?** By default, `Install-Module` tries to install
into the machine-wide module path (`C:\Program Files\WindowsPowerShell\Modules`),
which requires local admin rights. Most of us don't have local admin on our
work laptops. `-Scope CurrentUser` installs the module into your own user
profile instead (`$HOME\Documents\WindowsPowerShell\Modules`), which needs
no elevation at all — so it just works, and it only affects your own
account rather than every user on the machine.

### 2. Your PowerShell profile

Your **profile** is a script that runs automatically every time you open a
PowerShell session — it's the place to put aliases, helper functions, and
environment setup you want available everywhere.

```powershell
notepad $PROFILE
```
Opens your profile script in Notepad (it'll create an empty file the first
time if one doesn't exist yet).

```powershell
. $PROFILE
```
"Dot-sources" the profile — re-runs it in your *current* session so you
don't have to close and reopen PowerShell to pick up changes you just saved.

> There's a ready-made script in this folder — `edit-profile.ps1` — that
> automates adding a couple of useful aliases (`git`, `az`) and a
> `Load-EnvFile` helper function to your profile for you.

### 3. Connecting to Azure

```powershell
Connect-AzAccount
```
Opens a browser sign-in window and authenticates your session against
Azure AD.

```powershell
Get-AzContext
```
Shows which account, tenant, and subscription your current session is
active against — useful to sanity-check before running anything.

```powershell
Set-AzContext -Subscription "<subscription-id-or-name>"
```
Switches your active session into a different subscription. You'll need
this whenever you're working across more than one subscription (which,
in most tenants, is most of the time).

### 4. Finding your way around

```powershell
Get-Help <cmdlet-name> -Examples
```
Shows usage and examples for any cmdlet — always try this before Googling.

```powershell
Get-Command *AzKeyVault*
Get-Command -Verb Get -Noun *KeyVault*
```
Lists every cmdlet matching a pattern — handy when you know roughly what
you want to do but not the exact cmdlet name.

### 5. Basic navigation

```powershell
cd <path>       # change directory
cd ..           # back out 1 level
mkdir <name>    # create a new folder
rm <path>       # remove a file or folder (add -Recurse for folders with contents)
```

### 6. Querying Azure resources

```powershell
Get-AzSubscription                  # list subscriptions you can access
Get-AzKeyVault                      # list Key Vaults in the current subscription
Get-AzResource                      # list resources in the current subscription
Get-AzAccessToken -ResourceUrl "https://management.azure.com/"   # grab a bearer token for calling Azure REST APIs directly
```

### 7. Output and error handling

```powershell
Write-Host "Connecting to subscription $subId"
```
Prints a message straight to the console — good for status updates in a
script (note: it doesn't return data down the pipeline, it's for humans).

```powershell
try {
    # code that might fail
}
catch {
    Write-Host "Something went wrong: $_" -ForegroundColor Red
}
```
Wraps risky operations (auth, API calls) so a failure doesn't just dump a
raw red wall of text — you can catch it and decide what to do.

### 8. Microsoft Graph: `Connect-MgGraph`

A lot of Entra ID work (users, groups, sign-ins, conditional access) goes
through the Microsoft Graph PowerShell SDK rather than the `Az` module.
It's installed the same way, just a different module name:

```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

```powershell
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"
```
Signs you in to Microsoft Graph, same idea as `Connect-AzAccount` — except
here you also declare the **permission scopes** you need up front (Graph
is scope-based rather than subscription-based, so think "what data am I
allowed to touch" rather than "which subscription am I in"). You'll be
prompted to consent to any scopes you haven't already agreed to.

```powershell
Get-MgContext
```
Shows who you're connected as and, importantly, which scopes your current
session actually has — handy when a call fails with a permissions error
and you need to check what you're missing.

```powershell
Disconnect-MgGraph
```
Ends the session — useful when you need to reconnect with a different set
of scopes.

A few critical cmdlets once you're connected:

```powershell
Get-MgUser -UserId "user@domain.com"           # look up a single user
Get-MgUser -Filter "startsWith(displayName,'A')" -All   # search/filter users
Get-MgUserMemberOf -UserId "user@domain.com"   # groups/roles a user belongs to
Get-MgGroup -Filter "displayName eq 'Some Group'"        # look up a group
```

> Tip: if you're not sure which Graph cmdlet does what you want,
> `Find-MgGraphCommand -Command "*user*"` searches by keyword, and
> `Find-MgGraphCommand -Uri "/users"` searches by the underlying REST API
> path — useful since the Graph SDK has a *lot* of cmdlets.

---

## Az CLI

The Azure CLI (`az`) is the cross-platform, non-PowerShell way to do a lot
of the same things — you'll see both used interchangeably in the wild, so
it's worth knowing the basics.

**Always start with this sequence:**

```bash
az login
```
Opens a browser sign-in window, same idea as `Connect-AzAccount`.

```bash
az account show
```
Shows the currently active subscription/tenant for your CLI session —
your equivalent of `Get-AzContext`.

```bash
az account set --subscription "<subscription-id-or-name>"
```
Switches the active subscription — your equivalent of `Set-AzContext`.

> Tip: run `az login` → `az account show` → `az account set` in that order
> every time you start a new session against a tenant with multiple
> subscriptions.


# Convenience
Using your profile and aliases is a good way to save yourself some time.
If you find yourself doing repetitive actions each day, think about adding them to your profile.
> ***As long as there's nothing proprietary inside it, it may even be worth taking a copy of your $PROFILE regularly by either copying it to your OneDrive or dumping the contents somewhere you can access.***

To check an alias, do this
```
Get-Alias git | fl *
```

To create a new one (only for the current shell) do:
```
Set-Aliaz wh "Write-Host"
```

To understand the importance of the $PROFILE, run the above command then destroy that shell.  Run the command again.......not there, right?

In comparison, stuff you put in your $PROFILE gets loaded every time you create a new shell, so it's always there ready for you.  A great timesaver!

Add that line to `$PROFILE`, then run `. $PROFILE` to reload it.  

Try `wh yoyoyoyoyoyo` - does it work?


# Printing out more details
Often, for your convenience (annoyingly!), Powershell will give a very reduce set of outputs from a command.
Sometimes you need to pipe the command into a format capable of printing more detail.

```
Get-Alias git
Get-Alias git | fl *
Get-AzContext
Get-AzContext | ConvertTo-Json -Depth 10

```
