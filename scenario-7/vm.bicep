// Thin module - deployed into the EXISTING resource group from Scenario 5
// (the same one Scenario 6's VNet lives in) via `scope: rg` from
// main.bicep, for the usual reason: a subscription-scoped template can't
// create resource-group-scoped resources directly.
//
// Adds a new subnet to the EXISTING Scenario 6 VNet, then a Windows VM in
// it with a direct public IP and an NSG rule allowing RDP in. Username +
// password auth only, as requested - no Bastion, no JIT, no Key Vault
// integration (yet). See the note above the RDP rule below before you
// point this at anything that isn't a disposable lab VM.

@description('Naming-convention base name for the NEW resources created here (subnet, NSG, public IP, NIC, VM)')
param baseName string

@description('Azure region to deploy into - must match the region the Scenario 6 VNet is already in')
param location string

@description('Name of the EXISTING VNet (from Scenario 6) to add the new subnet to')
param existingVnetName string

@description('Address range for the new VM subnet - must not overlap the private-endpoints subnet from Scenario 6 (10.60.0.0/24 by default)')
param subnetAddressPrefix string = '10.60.1.0/24'

@description('B-series VM size. Standard_B2s is the practical floor for a usable Windows Server RDP session - Standard_B1s is cheaper still but often too slow to be worth it for a lab machine.')
param vmSize string = 'Standard_B2s'

@description('Local admin username for the VM. Avoid reserved names Azure rejects outright - "administrator", "admin", "user", "guest" and a handful of others.')
param adminUsername string

@secure()
@minLength(12)
@description('Local admin password for the VM. Azure requires 12-123 characters and at least 3 of: uppercase, lowercase, digit, special character.')
param adminPassword string

@description('Source address range allowed to RDP in. Defaults to "*" (anywhere) to keep this scenario simple - fine for a short-lived lab VM, but this is exactly the kind of wide-open inbound rule Tenet 3 (conditional access) is about locking down. Narrow this to your own IP if you leave the VM up for any length of time.')
param allowedRdpSourceAddressPrefix string = '*'

// --- Naming ---------------------------------------------------------------

var subnetName = 'snet-vm-${baseName}'
var nsgName = 'nsg-vm-${baseName}'
var publicIpName = 'pip-vm-${baseName}'
var nicName = 'nic-vm-${baseName}'
var vmName = 'vm-${baseName}'

// Windows computer names are capped at 15 characters and can't contain
// hyphens the way our naming convention does - same reason Scenario 5
// strips and truncates for storage account names.
var computerName = take(replace(vmName, '-', ''), 15)

// --- Reference the existing Scenario 6 VNet --------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: existingVnetName
}

// --- NSG: allow RDP in, nothing else ---------------------------------------

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-Inbound'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: allowedRdpSourceAddressPrefix
          destinationPortRange: '3389'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// --- New subnet in the existing VNet, with the NSG attached -----------------

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// --- Public IP - Standard SKU, static (Basic SKU IPs are retired) ----------

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// --- NIC: subnet + direct public IP -----------------------------------------

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// --- VM: B-series, small-disk Windows Server image, Standard_LRS disk ------
// (cheapest practical combination: B-series compute, the "smalldisk" image
// variant, and Standard HDD-backed managed disks rather than SSD)

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-smalldisk'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output vmName string = vm.name
output subnetName string = subnet.name
output publicIpAddress string = publicIp.properties.ipAddress
