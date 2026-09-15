// Thin module - deployed into the EXISTING resource group from Scenario 5
// via `scope: rg` from main.bicep (same reason as every other thin module
// in this repo: a subscription-scoped template can't create
// resource-group-scoped resources directly).
//
// Builds the private-access path around an existing Key Vault: a VNet,
// a Private DNS Zone, a Private Endpoint into that VNet, and an explicit
// A record pointing the Key Vault's private hostname at the Private
// Endpoint's actual private IP.
//
// Note: in a real environment you'd usually let a `privateDnsZoneGroup`
// sub-resource on the Private Endpoint create and maintain the A record
// automatically. Here it's split out as its own resource on purpose, so
// the DNS piece stays visible rather than happening behind the scenes.

@description('Naming-convention base name for the NEW networking resources created here')
param baseName string

@description('Azure region to deploy into')
param location string

@description('Name of the EXISTING Key Vault (from Scenario 5) to attach the private endpoint to')
param keyVaultName string

@description('Address space for the new VNet')
param vnetAddressPrefix string = '10.60.0.0/16'

@description('Address range for the private endpoints subnet')
param subnetAddressPrefix string = '10.60.0.0/24'

// The zone name is fixed by Azure for Key Vault private endpoints - every
// Key Vault private link everywhere uses this exact zone name, it isn't
// something we get to choose.
var privateDnsZoneName = 'privatelink.vaultcore.azure.net'
var subnetName = 'snet-private-endpoints'

// --- Reference the existing Key Vault from Scenario 5 -----------------------

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// --- Virtual network ----------------------------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-${baseName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// --- Private DNS zone + link to the new VNet -----------------------------

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-${baseName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// --- Private endpoint, into the new VNet, targeting the Key Vault --------

// Given an explicit name via customNetworkInterfaceName below, purely so
// we have a name for its NIC that Bicep can resolve BEFORE deployment
// starts (see the comment above the `existing` block further down).
var privateEndpointNicName = 'nic-pe-kv-${baseName}'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'pe-kv-${baseName}'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    customNetworkInterfaceName: privateEndpointNicName
    privateLinkServiceConnections: [
      {
        name: 'plsc-kv-${baseName}'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Read back the private IP Azure actually assigned to the private
// endpoint's NIC, so the A record below points at the real address rather
// than something we guessed.
//
// Our first attempt named this NIC by pulling it out of
// privateEndpoint.properties.networkInterfaces[0].id after the fact - that
// name only exists once Azure creates the NIC, so Bicep can't pin down the
// `existing` resource's identity at the start of the deployment, and
// restricts you to id/name/type/apiVersion on it (BCP307). Swapping in
// `reference()` instead hit the same wall, because `reference()` can only
// be used inside a resource/module/output, not assigned to a plain `var`.
//
// The actual fix: force the NIC's name ourselves via
// customNetworkInterfaceName above, so `privateEndpointNicName` is known
// purely from baseName - no runtime lookup required - and THIS `existing`
// block is now completely valid, full properties and all. The explicit
// dependsOn is required because, unlike before, nothing here symbolically
// references privateEndpoint anymore, so Bicep has no automatic ordering
// to infer - without it, this could try to read the NIC before the private
// endpoint has actually created it.
resource privateEndpointNic 'Microsoft.Network/networkInterfaces@2023-09-01' existing = {
  name: privateEndpointNicName
  dependsOn: [
    privateEndpoint
  ]
}

var privateEndpointIp = privateEndpointNic.properties.ipConfigurations[0].properties.privateIPAddress

// --- A record: <keyVaultName>.privatelink.vaultcore.azure.net -----------

resource aRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: keyVaultName
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpointIp
      }
    ]
  }
}

output vnetName string = vnet.name
output subnetName string = subnetName
output privateEndpointName string = privateEndpoint.name
output privateDnsZoneName string = privateDnsZone.name
output privateEndpointIp string = privateEndpointIp
output keyVaultPrivateFqdn string = '${keyVaultName}.${privateDnsZoneName}'
