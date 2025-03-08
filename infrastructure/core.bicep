// Define Paramaters
// what parameters are needed to create the core resources (make it generic to be used in multiple environments dev, test, prod)
// we need location --> at what region do we want to deploy the resources
param location string
param prefix string
param vnetSettings object = {
  addressPrefix: [
    '10.0.0.0/20'
  ]
  subnets: [
    {
      name: 'subnet1'
      addressPrefix: '10.0.0.0/22'
    }
    ]
}


// Start writing some Bicep! to create core resources that everything else will depend on.
// A Virtual Network that resources can join
// NSG for securing the network ingress

// create NSG
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: [
      // Default rules will be applied
    ]
  }
}


// create vNet
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetSettings.addressPrefix
      
    }
    subnets: [for subnet in vnetSettings.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        // add NSG here
        networkSecurityGroup: {
          id: networkSecurityGroup.id
      }
    }
      // we don't have to explicitly create a dependency , we can just run the deployment and it will create the NSG first and then the vNet
    }]      
  }
}

// Deploy and check if everything is working as expected
// Try & Deploy often to make sure that you are catching those errors as soon as possible


// Databases -- cosmosdb
//secure access to cosmosdb using private endpoint

// Deploy ComsmosDB resource
// use private endpoint to join to the vNet and lock it down to only allow traffic from the vNet

// DB Requirements -- SQL API, -- Session Consistency, -- Single Orders Container, -- id as partition key
// Infra Requirementts -- serverless atleast for dev, add multi-region support later

// create cosmosdb
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: '${prefix}-cosmos-account'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

// create cosmos sql database
resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: '${prefix}-sqlDb'
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: '${prefix}-sqlDb'
    }
    options: {
    }
  }
}

// Add cosmos sql container
resource sqlContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: sqlDb 
  name: '${prefix}-orders'
  properties: {
    resource: {
      id: '${prefix}-orders'
      partitionKey: {
        paths: [
          '/id'
        ]
      }
    }
    options: {}
  }
}

// Run Deployment and check if everything is working as expected
// check in Azure Portal if the resources are created as expected
// At present this resource is open to the internet, we need to lock it down to only allow traffic from the vNet

// create private endpoint & restrict access to the vNet
// we need to do multiple things here
     // 1. Sort out the DNS for the private endpoint --> Need a DNS solution for resolving private records for the resources
     // Easier way is to use Azure Private DNS Zones
     // create the Zone and link it to the vNet and then link it to private endpoint & it will create the DNS records for us

     // Actual DNS Zone itself
     // Link to Vnet
     // Link to Private Endpoint

resource cosmosPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com' // this is the DNS name for cosmosdb - check the docs for the correct name
  location: 'global' // this is a global resource
}

resource cosmosPrivateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${prefix}-cosmos-dns-Link'
  location: 'global'
  parent: cosmosPrivateDns
  properties: {
    registrationEnabled:false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// create private endpoint

resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: '${prefix}-cosmos-pe'
  location: location
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${prefix}-cosmos-pe'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'sql'
          ]
        }
      }
    ]
  }
}

// Link the private endpoint to the DNS Zone
resource cosmosPrivateEndPointDnsLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${prefix}-cosmos-pe-dns'
  parent: cosmosPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.documents.azure.com'
        properties: {
          privateDnsZoneId: cosmosPrivateDns.id
        }
      }
    ]
  }
}

//Run the deployment and check if everything is working as expected
