using '../main.bicep'

param prefix = 'asistencia'
// Se leen de variables de entorno: no se guardan en el repositorio.
param adminSourceIp = readEnvironmentVariable('ADMIN_SOURCE_IP')
param sshPublicKey = readEnvironmentVariable('SSH_PUBLIC_KEY')
param vmSize = 'Standard_B1s'
