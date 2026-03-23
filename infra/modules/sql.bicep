@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (test, staging, prod)')
param environment string

@description('Base name used to derive resource names')
param baseName string

@description('Subnet ID for the SQL private endpoint')
param privateEndpointSubnetId string

@description('Private DNS zone resource ID for privatelink.database.windows.net')
param sqlDnsZoneId string

var sqlServerName = '${baseName}-sql-${environment}'
var sqlDatabaseName = '${baseName}-db-${environment}'
var sqlUaiName = 'uai-sql-${baseName}-${environment}'

// User-assigned managed identity used by function apps to authenticate to SQL.
// This identity is set as the SQL Server AAD administrator, so both the main slot
// and staging slot can connect to SQL using the same credential via
// "Authentication=Active Directory Managed Identity;User Id=<clientId>".
resource sqlUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: sqlUaiName
  location: location
}

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      login: sqlUai.name
      sid: sqlUai.properties.principalId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: true
    }
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    requestedBackupStorageRedundancy: 'Local'
  }
}

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${sqlServerName}-pe'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${sqlServerName}-pe'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
        }
      }
    ]
  }
}

resource sqlDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: sqlPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sql'
        properties: { privateDnsZoneId: sqlDnsZoneId }
      }
    ]
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output sqlUaiId string = sqlUai.id
output sqlUaiClientId string = sqlUai.properties.clientId
