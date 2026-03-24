@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (test, staging, prod)')
param environment string

@description('Base name used to derive resource names')
param baseName string

var logAnalyticsName = '${baseName}-law-${environment}'
var appInsightsName = '${baseName}-ai-${environment}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsId string = appInsights.id
output logAnalyticsId string = logAnalytics.id
