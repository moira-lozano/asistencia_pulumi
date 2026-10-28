# Azure con Bicep: 3 servidores

Frontend (IP pública, 80/443) · Backend (solo IP privada, 8090 solo desde el frontend) · Base de datos (solo IP privada, 3306 solo desde el backend).
SSH: solo desde tu IP hacia el frontend; backend y BD se alcanzan saltando por el frontend.

## Antes de desplegar (PowerShell)
```powershell
az version; az bicep version
az login
az account show                      # confirme la suscripción
az account set --subscription "<ID>" # si tiene varias
ssh-keygen -t ed25519                # si no tiene clave (se guarda en $HOME\.ssh\id_ed25519)

$env:ADMIN_SOURCE_IP = "$(Invoke-RestMethod https://api.ipify.org)/32"
$env:SSH_PUBLIC_KEY  = (Get-Content $HOME\.ssh\id_ed25519.pub -Raw).Trim()
```

## Validar, simular y desplegar
```powershell
az bicep build --file azure/main.bicep                       # compila (detecta errores)
az group create -n rg-asistencia-dev -l eastus
az deployment group what-if -g rg-asistencia-dev -p azure/parameters/development.bicepparam
az deployment group create  -g rg-asistencia-dev -p azure/parameters/development.bicepparam
az deployment group show -g rg-asistencia-dev -n main --query properties.outputs
```

## Verificar
```powershell
az vm list -g rg-asistencia-dev -d -o table                  # deben ser 3, en ejecución
ssh azureuser@<IP_PUBLICA_FRONTEND>
ssh -J azureuser@<IP_PUBLICA_FRONTEND> azureuser@<IP_PRIVADA_BACKEND>
```
Desde el frontend: `nc -zv <IP_PRIVADA_BACKEND> 8090` (debe conectar cuando el backend esté escuchando) y
`nc -zv <IP_PRIVADA_BD> 3306` (debe fallar: solo el backend puede llegar a la BD).

## Costos y limpieza
El NAT Gateway y la IP pública cobran por hora. Al terminar la demo:
```powershell
az group delete -n rg-asistencia-dev --yes --no-wait
```

## Base de datos (MySQL)
El disco de datos (32 GB, lun 0) está vacío: hay que formatearlo y montarlo y apuntar `datadir` de MySQL allí. Copias de seguridad: `mysqldump` programado y/o Azure Backup para la VM; no están incluidos.
