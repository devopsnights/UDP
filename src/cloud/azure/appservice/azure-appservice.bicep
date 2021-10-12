@minLength(1)
param servicePlanName string

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
@description('Describes plan\'s pricing tier and capacity. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
param skuName string = 'F1'

@minValue(1)
@description('Describes plan\'s instance count')
param skuCapacity int = 1
param siteName string = 'webSite${uniqueString(resourceGroup().id)}'

resource servicePlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: servicePlanName
  location: resourceGroup().location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: servicePlanName
  }
}

resource siteName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: siteName
  location: resourceGroup().location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${servicePlanName}': 'Resource'
    displayName: 'Website'
  }
  properties: {
    name: siteName
    serverFarmId: servicePlanName_resource.id
  }
}
