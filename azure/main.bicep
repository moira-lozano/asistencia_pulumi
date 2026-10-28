// Azure: 3 servidores (frontend, backend, base de datos) con Bicep.
// Se despliega sobre un grupo de recursos YA creado:
//   az group create -n rg-asistencia-dev -l eastus
targetScope = 'resourceGroup'

@description('Región de Azure. Por defecto, la del grupo de recursos.')
param location string = resourceGroup().location

@description('Prefijo para nombrar los recursos.')
@minLength(2)
@maxLength(12)
param prefix string = 'asistencia'

@description('Tu IP pública en formato CIDR /32. Es el único origen autorizado para SSH.')
@minLength(9)
param adminSourceIp string

@description('Usuario administrador de Linux.')
param adminUsername string = 'azureuser'

@description('Contenido de la clave PUBLICA SSH (.pub). Nunca la privada.')
param sshPublicKey string

@description('Tamaño de las VMs. Si no hay cupo en tu región/suscripción, prueba Standard_B2s.')
param vmSize string = 'Standard_B1s'

@description('Tamaño (GB) del disco de datos persistente de la base de datos.')
@minValue(4)
param dbDataDiskSizeGB int = 32

var vnetCidr = '10.20.0.0/16'
var frontendSubnetCidr = '10.20.1.0/24'
var backendSubnetCidr = '10.20.2.0/24'
var dbSubnetCidr = '10.20.3.0/24'

module security 'modules/security.bicep' = {
  name: 'security'
  params: {
    location: location
    prefix: prefix
    adminSourceIp: adminSourceIp
    frontendSubnetCidr: frontendSubnetCidr
    backendSubnetCidr: backendSubnetCidr
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    prefix: prefix
    vnetCidr: vnetCidr
    frontendSubnetCidr: frontendSubnetCidr
    backendSubnetCidr: backendSubnetCidr
    dbSubnetCidr: dbSubnetCidr
    frontendNsgId: security.outputs.frontendNsgId
    backendNsgId: security.outputs.backendNsgId
    dbNsgId: security.outputs.dbNsgId
  }
}

module frontend 'modules/virtual-machine.bicep' = {
  name: 'vm-frontend'
  params: {
    name: '${prefix}-frontend'
    location: location
    subnetId: network.outputs.frontendSubnetId
    vmSize: vmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    createPublicIp: true
    dataDiskSizeGB: 0
  }
}

module backend 'modules/virtual-machine.bicep' = {
  name: 'vm-backend'
  params: {
    name: '${prefix}-backend'
    location: location
    subnetId: network.outputs.backendSubnetId
    vmSize: vmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    createPublicIp: false
    dataDiskSizeGB: 0
  }
}

module database 'modules/virtual-machine.bicep' = {
  name: 'vm-database'
  params: {
    name: '${prefix}-db'
    location: location
    subnetId: network.outputs.dbSubnetId
    vmSize: vmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    createPublicIp: false
    dataDiskSizeGB: dbDataDiskSizeGB
  }
}

output frontendPublicIp string = frontend.outputs.publicIp
output frontendPrivateIp string = frontend.outputs.privateIp
output backendPrivateIp string = backend.outputs.privateIp
output databasePrivateIp string = database.outputs.privateIp
output sshFrontend string = 'ssh ${adminUsername}@${frontend.outputs.publicIp}'
output sshBackendViaFrontend string = 'ssh -J ${adminUsername}@${frontend.outputs.publicIp} ${adminUsername}@${backend.outputs.privateIp}'
output sshDatabaseViaFrontend string = 'ssh -J ${adminUsername}@${frontend.outputs.publicIp} ${adminUsername}@${database.outputs.privateIp}'
