@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (test, staging, prod)')
param environment string

@description('Base name used to derive resource names')
param baseName string

@description('Subnet ID for private endpoints')
param privateEndpointSubnetId string

@description('Private DNS zone resource ID for privatelink.servicebus.windows.net')
param serviceBusDnsZoneId string

var serviceBusNamespaceName = '${baseName}-sb-${environment}'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    // Premium is required for private endpoint support
    name: 'Premium'
    tier: 'Premium'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true
  }
}

resource ordersInboundTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: serviceBusNamespace
  name: 'orders-inbound'
  properties: {
    defaultMessageTimeToLive: 'P14D'
    enableBatchedOperations: true
  }
}

resource ordersInternalTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: serviceBusNamespace
  name: 'orders-internal'
  properties: {
    defaultMessageTimeToLive: 'P14D'
    enableBatchedOperations: true
  }
}

resource ordersEnrichedTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: serviceBusNamespace
  name: 'orders-enriched'
  properties: {
    defaultMessageTimeToLive: 'P14D'
    enableBatchedOperations: true
  }
}

resource ordersOutboundTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: serviceBusNamespace
  name: 'orders-outbound'
  properties: {
    defaultMessageTimeToLive: 'P14D'
    enableBatchedOperations: true
  }
}

// Subscription for Logic App Workflow 1 on orders-inbound
resource laInboundSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersInboundTopic
  name: 'la-inbound'
  properties: {
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
  }
}

// Subscription for Azure Function on orders-internal
resource funcInternalSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersInternalTopic
  name: 'func-internal'
  properties: {
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
  }
}

// Subscription for Logic App Workflow 2 on orders-enriched
resource laEnrichedSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersEnrichedTopic
  name: 'la-enriched'
  properties: {
    lockDuration: 'PT1M'
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
  }
}

// Private endpoint routes all Service Bus traffic through the VNet
resource serviceBusPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${serviceBusNamespaceName}-pe'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${serviceBusNamespaceName}-pe'
        properties: {
          privateLinkServiceId: serviceBusNamespace.id
          groupIds: ['namespace']
        }
      }
    ]
  }
}

resource serviceBusDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: serviceBusPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'servicebus'
        properties: {
          privateDnsZoneId: serviceBusDnsZoneId
        }
      }
    ]
  }
}

output serviceBusNamespaceName string = serviceBusNamespace.name
output serviceBusNamespaceFqdn string = '${serviceBusNamespaceName}.servicebus.windows.net'
