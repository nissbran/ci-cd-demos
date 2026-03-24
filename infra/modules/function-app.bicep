@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (test, staging, prod)')
param environment string

@description('Base name used to derive resource names')
param baseName string

@description('Fully qualified namespace hostname of the Service Bus (e.g. myns.servicebus.windows.net)')
param serviceBusNamespaceFqdn string

@description('Service Bus namespace resource name (used for RBAC scope)')
param serviceBusNamespaceName string

@description('Subnet ID for Function App VNet integration')
param funcIntegrationSubnetId string

@description('Subnet ID for private endpoints')
param privateEndpointSubnetId string

@description('Private DNS zone resource ID for privatelink.blob.core.windows.net')
param blobDnsZoneId string

@description('Private DNS zone resource ID for privatelink.queue.core.windows.net')
param queueDnsZoneId string

@description('Private DNS zone resource ID for privatelink.table.core.windows.net')
param tableDnsZoneId string

@description('Azure SQL Server fully qualified domain name')
param sqlServerFqdn string

@description('Azure SQL Database name')
param sqlDatabaseName string

@description('Resource ID of the user-assigned managed identity used for SQL authentication')
param sqlUaiId string

@description('Client ID of the user-assigned managed identity used for SQL authentication')
param sqlUaiClientId string

@description('Application Insights connection string')
param appInsightsConnectionString string

var functionAppName = '${baseName}-func-${environment}'
var storageAccountName = toLower(replace('${baseName}st${environment}', '-', ''))
var appServicePlanName = '${baseName}-asp-func-${environment}'
var deploymentContainerName = 'func-deployment-pkg'
var sqlConnectionString = 'Server=${sqlServerFqdn};Database=${sqlDatabaseName};Authentication=Active Directory Managed Identity;User Id=${sqlUaiClientId};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

// Built-in RBAC role definition IDs
var storageBlobDataOwnerRoleId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageQueueDataContributorRoleId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
var serviceBusDataSenderRoleId = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
var serviceBusDataReceiverRoleId = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    // Flex Consumption uses managed identity for all storage access - no key required
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
  }
}

// Blob container used by Flex Consumption to store deployment packages
resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/${deploymentContainerName}'
  properties: {}
}

// FC1 (Flex Consumption) - Linux-based, pay-per-use, supports VNet integration natively
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true // Required - Flex Consumption is Linux only
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    // SystemAssigned for storage/service-bus RBAC; UserAssigned (sqlUaiId) for SQL access
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${sqlUaiId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}${deploymentContainerName}'
          authentication: {
            // Use system-assigned managed identity to access the deployment blob container
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 100
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '10.0'
      }
    }
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      // Identity-based storage connection - no account key required
      AzureWebJobsStorage__accountName: storageAccount.name
      AzureWebJobsStorage__credential: 'managedidentity'
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
      // Identity-based Service Bus connection - triggers and outputs use managed identity
      OrdersServiceBus__fullyQualifiedNamespace: serviceBusNamespaceFqdn
      // SQL connection using the user-assigned managed identity
      SqlConnectionString: sqlConnectionString
    }
  }
}

// VNet integration for Flex Consumption is configured via a child networkConfig resource
resource funcNetworkConfig 'Microsoft.Web/sites/networkConfig@2024-04-01' = {
  parent: functionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: funcIntegrationSubnetId
  }
}

resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${storageAccountName}-blob-pe'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-blob-pe'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource storageBlobDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: storageBlobPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: { privateDnsZoneId: blobDnsZoneId }
      }
    ]
  }
}

resource storageQueuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${storageAccountName}-queue-pe'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-queue-pe'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['queue']
        }
      }
    ]
  }
}

resource storageQueueDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: storageQueuePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'queue'
        properties: { privateDnsZoneId: queueDnsZoneId }
      }
    ]
  }
}

resource storageTablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${storageAccountName}-table-pe'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-table-pe'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['table']
        }
      }
    ]
  }
}

resource storageTableDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: storageTablePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'table'
        properties: { privateDnsZoneId: tableDnsZoneId }
      }
    ]
  }
}

// RBAC: grant the Function App managed identity access to its own storage account

resource serviceBusNamespaceRef 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource funcStorageBlobOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource funcStorageQueueContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageQueueDataContributorRoleId
    )
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource funcStorageTableContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageTableDataContributorRoleId
    )
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: grant the Function App managed identity access to Service Bus

resource funcServiceBusSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespaceRef.id, functionApp.id, serviceBusDataSenderRoleId)
  scope: serviceBusNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataSenderRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource funcServiceBusReceiver 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespaceRef.id, functionApp.id, serviceBusDataReceiverRoleId)
  scope: serviceBusNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = functionApp.name
output functionAppHostname string = functionApp.properties.defaultHostName
