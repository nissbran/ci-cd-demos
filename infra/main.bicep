@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (test, staging, prod)')
@allowed(['test', 'staging', 'prod'])
param environment string

@description('Base name used to derive resource names')
param baseName string = 'cicd-demo'

module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: {
    location: location
    environment: environment
    baseName: baseName
  }
}

module serviceBus 'modules/service-bus.bicep' = {
  name: 'service-bus'
  params: {
    location: location
    environment: environment
    baseName: baseName
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    serviceBusDnsZoneId: networking.outputs.serviceBusDnsZoneId
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    environment: environment
    baseName: baseName
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    sqlDnsZoneId: networking.outputs.sqlDnsZoneId
  }
}

module functionApp 'modules/function-app.bicep' = {
  name: 'function-app'
  params: {
    location: location
    environment: environment
    baseName: baseName
    serviceBusNamespaceFqdn: serviceBus.outputs.serviceBusNamespaceFqdn
    serviceBusNamespaceName: serviceBus.outputs.serviceBusNamespaceName
    funcIntegrationSubnetId: networking.outputs.funcIntegrationSubnetId
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    blobDnsZoneId: networking.outputs.blobDnsZoneId
    queueDnsZoneId: networking.outputs.queueDnsZoneId
    tableDnsZoneId: networking.outputs.tableDnsZoneId
    sqlServerFqdn: sql.outputs.sqlServerFqdn
    sqlDatabaseName: sql.outputs.sqlDatabaseName
    sqlUaiId: sql.outputs.sqlUaiId
    sqlUaiClientId: sql.outputs.sqlUaiClientId
  }
}

module logicApp 'modules/logic-app.bicep' = {
  name: 'logic-app'
  params: {
    location: location
    environment: environment
    baseName: baseName
    serviceBusNamespaceFqdn: serviceBus.outputs.serviceBusNamespaceFqdn
    serviceBusNamespaceName: serviceBus.outputs.serviceBusNamespaceName
    logicAppIntegrationSubnetId: networking.outputs.logicAppIntegrationSubnetId
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    blobDnsZoneId: networking.outputs.blobDnsZoneId
    queueDnsZoneId: networking.outputs.queueDnsZoneId
    tableDnsZoneId: networking.outputs.tableDnsZoneId
    fileDnsZoneId: networking.outputs.fileDnsZoneId
  }
}

output functionAppName string = functionApp.outputs.functionAppName
output functionAppHostname string = functionApp.outputs.functionAppHostname
output logicAppName string = logicApp.outputs.logicAppName
output logicAppHostname string = logicApp.outputs.logicAppHostname
output serviceBusNamespaceName string = serviceBus.outputs.serviceBusNamespaceName
output vnetId string = networking.outputs.vnetId
