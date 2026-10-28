// Red virtual, 3 subredes y NAT Gateway para la salida a Internet de backend y BD.
// Desde el 31-mar-2026 las VNets nuevas son "privadas" por defecto: sin NAT,
// las VMs sin IP pública no pueden instalar paquetes (apt).
param location string
param prefix string
param vnetCidr string
param frontendSubnetCidr string
param backendSubnetCidr string
param dbSubnetCidr string
param frontendNsgId string
param backendNsgId string
param dbNsgId string

resource natPip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${prefix}-pip-nat'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nat 'Microsoft.Network/natGateways@2024-05-01' = {
  name: '${prefix}-nat'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natPip.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    subnets: [
      {
        name: 'snet-frontend'
        properties: {
          addressPrefix: frontendSubnetCidr
          networkSecurityGroup: {
            id: frontendNsgId
          }
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-backend'
        properties: {
          addressPrefix: backendSubnetCidr
          networkSecurityGroup: {
            id: backendNsgId
          }
          natGateway: {
            id: nat.id
          }
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-db'
        properties: {
          addressPrefix: dbSubnetCidr
          networkSecurityGroup: {
            id: dbNsgId
          }
          natGateway: {
            id: nat.id
          }
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

output frontendSubnetId string = vnet.properties.subnets[0].id
output backendSubnetId string = vnet.properties.subnets[1].id
output dbSubnetId string = vnet.properties.subnets[2].id
