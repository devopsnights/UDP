@minLength(1)
param hostingPlanName string

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

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: hostingPlanName
  location: resourceGroup().location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName
  }
}

resource siteName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: siteName
  location: resourceGroup().location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    displayName: 'Website'
  }
  properties: {
    name: siteName
    serverFarmId: hostingPlanName_resource.id
  }
}

resource hostingPlanName_name 'Microsoft.Insights/autoscalesettings@2014-04-01' = {
  name: '${hostingPlanName}-${resourceGroup().name}'
  location: resourceGroup().location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    displayName: 'AutoScaleSettings'
  }
  properties: {
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: 1
          maximum: 2
          default: 1
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: '80'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: 1
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT1H'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: '60'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: 1
              cooldown: 'PT1H'
            }
          }
        ]
      }
    ]
    enabled: false
    name: '${hostingPlanName}-${resourceGroup().name}'
    targetResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource ServerErrors_siteName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'ServerErrors ${siteName}'
  location: resourceGroup().location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${siteName}': 'Resource'
    displayName: 'ServerErrorsAlertRule'
  }
  properties: {
    name: 'ServerErrors ${siteName}'
    description: '${siteName} has some server errors, status code 5xx.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/sites/${siteName}'
        metricName: 'Http5xx'
      }
      operator: 'GreaterThan'
      threshold: '0'
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    siteName_resource
  ]
}

resource ForbiddenRequests_siteName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'ForbiddenRequests ${siteName}'
  location: resourceGroup().location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${siteName}': 'Resource'
    displayName: 'ForbiddenRequestsAlertRule'
  }
  properties: {
    name: 'ForbiddenRequests ${siteName}'
    description: '${siteName} has some requests that are forbidden, status code 403.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/sites/${siteName}'
        metricName: 'Http403'
      }
      operator: 'GreaterThan'
      threshold: 0
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    siteName_resource
  ]
}

resource CPUHigh_hostingPlanName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'CPUHigh ${hostingPlanName}'
  location: resourceGroup().location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    displayName: 'CPUHighAlertRule'
  }
  properties: {
    name: 'CPUHigh ${hostingPlanName}'
    description: 'The average CPU is high across all the instances of ${hostingPlanName}'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
        metricName: 'CpuPercentage'
      }
      operator: 'GreaterThan'
      threshold: 90
      windowSize: 'PT15M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource LongHttpQueue_hostingPlanName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'LongHttpQueue ${hostingPlanName}'
  location: resourceGroup().location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    displayName: 'LongHttpQueueAlertRule'
  }
  properties: {
    name: 'LongHttpQueue ${hostingPlanName}'
    description: 'The HTTP queue for the instances of ${hostingPlanName} has a large number of pending requests.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
        metricName: 'HttpQueueLength'
      }
      operator: 'GreaterThan'
      threshold: '100'
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource Microsoft_Insights_components_siteName 'Microsoft.Insights/components@2014-04-01' = {
  name: siteName
  location: 'East US'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${siteName}': 'Resource'
    displayName: 'AppInsightsComponent'
  }
  properties: {
    applicationId: siteName
  }
  dependsOn: [
    siteName_resource
  ]
}