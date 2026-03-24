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

@description('Subnet ID for Logic App VNet integration')
param logicAppIntegrationSubnetId string

@description('Subnet ID for private endpoints')
param privateEndpointSubnetId string

@description('Private DNS zone resource ID for privatelink.blob.core.windows.net')
param blobDnsZoneId string

@description('Private DNS zone resource ID for privatelink.queue.core.windows.net')
param queueDnsZoneId string

@description('Private DNS zone resource ID for privatelink.table.core.windows.net')
param tableDnsZoneId string

@description('Private DNS zone resource ID for privatelink.file.core.windows.net')
param fileDnsZoneId string

@description('Application Insights connection string')
param appInsightsConnectionString string

var logicAppName = '${baseName}-la-${environment}'
var storageAccountName = toLower(replace('${baseName}last${environment}', '-', ''))
var appServicePlanName = '${baseName}-asp-la-${environment}'
var contentShareName = 'la-content'

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
    publicNetworkAccess: 'Disabled'
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/${contentShareName}'
  properties: {}
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
}

resource logicApp 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: logicAppIntegrationSubnetId
    siteConfig: {
      appSettings: [
        // Identity-based storage connection — no account key in app settings
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        // File share connection is still key-based (required by Logic Apps Standard for workflow content)
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: contentShareName
        }
        // Route content share traffic through VNet so it reaches the storage private endpoint
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        // Identity-based Service Bus connection — workflows use managed identity
        {
          name: 'OrdersServiceBus__fullyQualifiedNamespace'
          value: serviceBusNamespaceFqdn
        }
      ]
    }
    httpsOnly: true
  }
}

// Private endpoints for all storage sub-resources

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

resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${storageAccountName}-file-pe'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-file-pe'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['file']
        }
      }
    ]
  }
}

resource storageFileDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: storageFilePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'file'
        properties: { privateDnsZoneId: fileDnsZoneId }
      }
    ]
  }
}

// RBAC: grant the Logic App managed identity access to its own storage account

resource serviceBusNamespaceRef 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource laStorageBlobOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicApp.id, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerRoleId)
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laStorageQueueContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicApp.id, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageQueueDataContributorRoleId
    )
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laStorageTableContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicApp.id, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageTableDataContributorRoleId
    )
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: grant the Logic App managed identity access to Service Bus

resource laServiceBusSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespaceRef.id, logicApp.id, serviceBusDataSenderRoleId)
  scope: serviceBusNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataSenderRoleId)
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laServiceBusReceiver 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespaceRef.id, logicApp.id, serviceBusDataReceiverRoleId)
  scope: serviceBusNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Staging slot variables
var stagingContentShareName = 'la-content-staging'

// Separate file share for the staging slot so it holds its own workflow definitions independently
resource stagingFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/${stagingContentShareName}'
  properties: {}
}

// Staging deployment slot — code is deployed here first, then swapped to production
resource logicAppStagingSlot 'Microsoft.Web/sites/slots@2023-01-01' = {
  parent: logicApp
  name: 'staging'
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: logicAppIntegrationSubnetId
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        // Each slot must have its own content share so workflows are independent between slot and production
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: stagingContentShareName
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'OrdersServiceBus__fullyQualifiedNamespace'
          value: serviceBusNamespaceFqdn
        }
      ]
    }
    httpsOnly: true
  }
}

// RBAC: grant the staging slot's managed identity access to storage and Service Bus
// (identity stays with the slot after swap, so both slot and production need their own roles)

resource laSlotStorageBlobOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicAppStagingSlot.id, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerRoleId)
    principalId: logicAppStagingSlot.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laSlotStorageQueueContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicAppStagingSlot.id, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageQueueDataContributorRoleId
    )
    principalId: logicAppStagingSlot.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laSlotStorageTableContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicAppStagingSlot.id, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageTableDataContributorRoleId
    )
    principalId: logicAppStagingSlot.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laSlotServiceBusSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespaceRef.id, logicAppStagingSlot.id, serviceBusDataSenderRoleId)
  scope: serviceBusNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataSenderRoleId)
    principalId: logicAppStagingSlot.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource laSlotServiceBusReceiver 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespaceRef.id, logicAppStagingSlot.id, serviceBusDataReceiverRoleId)
  scope: serviceBusNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
    principalId: logicAppStagingSlot.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output logicAppName string = logicApp.name
output logicAppHostname string = logicApp.properties.defaultHostName
