@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name used to derive resource names')
param baseName string

@description('Environment name')
param environment string

var vnetName = '${baseName}-vnet-${environment}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'snet-func-integration'
        properties: {
          addressPrefix: '10.0.1.0/26'
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: 'snet-logicapp-integration'
        properties: {
          addressPrefix: '10.0.2.0/26'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.0.3.0/27'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource funcIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: vnet
  name: 'snet-func-integration'
}

resource logicAppIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: vnet
  name: 'snet-logicapp-integration'
}

resource privateEndpointsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: vnet
  name: 'snet-private-endpoints'
}

// Private DNS zones for all private endpoint sub-resources
// Use the environment() function so zone names resolve correctly in sovereign clouds

var storageSuffix = az.environment().suffixes.storage

resource serviceBusDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
}

resource blobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${storageSuffix}'
  location: 'global'
}

resource queueDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.queue.${storageSuffix}'
  location: 'global'
}

resource tableDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.${storageSuffix}'
  location: 'global'
}

resource fileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${storageSuffix}'
  location: 'global'
}

// Link each DNS zone to the VNet so private endpoint DNS records resolve within the VNet

resource serviceBusDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: serviceBusDnsZone
  name: '${vnetName}-sb-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource blobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobDnsZone
  name: '${vnetName}-blob-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource queueDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: queueDnsZone
  name: '${vnetName}-queue-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource tableDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: tableDnsZone
  name: '${vnetName}-table-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource fileDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: fileDnsZone
  name: '${vnetName}-file-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

#disable-next-line no-hardcoded-env-urls
var sqlDnsZoneName = 'privatelink.database.windows.net'

resource sqlDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: sqlDnsZoneName
  location: 'global'
}

resource sqlDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlDnsZone
  name: '${vnetName}-sql-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

output vnetId string = vnet.id
output funcIntegrationSubnetId string = funcIntegrationSubnet.id
output logicAppIntegrationSubnetId string = logicAppIntegrationSubnet.id
output privateEndpointSubnetId string = privateEndpointsSubnet.id
output serviceBusDnsZoneId string = serviceBusDnsZone.id
output blobDnsZoneId string = blobDnsZone.id
output queueDnsZoneId string = queueDnsZone.id
output tableDnsZoneId string = tableDnsZone.id
output fileDnsZoneId string = fileDnsZone.id
output sqlDnsZoneId string = sqlDnsZone.id
