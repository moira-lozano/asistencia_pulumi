# CI/CD de CloudFormation con GitHub Actions (OIDC, sin claves guardadas)

Flujo: **Pull Request** → el workflow valida y muestra el change set (no despliega) → **merge a main** → el job `apply`
espera la aprobación del entorno `aws-lab` → ejecuta el change set. Si el change set elimina o reemplaza
recursos, el script se detiene.

## 1. Proveedor OIDC en AWS (una sola vez por cuenta)
```powershell
aws iam list-open-id-connect-providers          # si ya existe token.actions.githubusercontent.com, omita el siguiente
aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com
```
(Si el CLI pide `--thumbprint-list`, créelo desde la consola: IAM > Identity providers > Add provider > OpenID Connect.)

## 2. Rol para GitHub
Guarde como `trust.json` (reemplace `<ACCOUNT_ID>` por el resultado de `aws sts get-caller-identity`, y confirme el nombre del repo):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": { "token.actions.githubusercontent.com:sub": [
        "repo:moira-lozano/asistencia_pulumi:pull_request",
        "repo:moira-lozano/asistencia_pulumi:environment:aws-lab"
      ] }
    }
  }]
}
```
Guarde como `permisos.json` (punto de partida; **ajústelo** a los recursos que gestione su plantilla):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["cloudformation:*"], "Resource": "*" },
    { "Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject", "s3:GetBucketLocation", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::<BUCKET>", "arn:aws:s3:::<BUCKET>/*"] },
    { "Effect": "Allow", "Action": ["ec2:*"], "Resource": "*" },
    { "Effect": "Allow", "Action": ["ssm:GetParameters", "ssm:GetParameter"], "Resource": "*" }
  ]
}
```
```powershell
aws iam create-role --role-name github-cfn-asistencia --assume-role-policy-document file://trust.json
aws iam put-role-policy --role-name github-cfn-asistencia --policy-name cfn-deploy --policy-document file://permisos.json
aws iam get-role --role-name github-cfn-asistencia --query Role.Arn --output text    # copie este ARN
```
`ec2:*` es amplio: sirve para la demo, pero luego restrínjalo.

## 3. GitHub (Settings del repositorio)
- **Secrets and variables → Actions → Variables** (pestaña *Variables*, no *Secrets*; ninguna es secreta):
  `AWS_ROLE_ARN` (ARN anterior), `STACK_NAME` (`asistencia-demo`), `ARTIFACT_BUCKET`, `SSH_SOURCE_CIDR` (su IP `/32`),
  `SSH_PUBLIC_KEY` (contenido del `.pub`, nunca la privada), `ENVIRONMENT` (`demo`), `PROJECT` (`asistencia`).
  El workflow genera `cloudformation/parameters/lab.json` con ellas; su `lab.json` local sigue ignorado por Git.
- **Environments → New environment → `aws-lab`** → *Required reviewers*: agregue a quien aprueba. (En repos privados puede requerir plan de pago; sin esto el despliegue en `main` corre sin pausa.)
- **Branches → Add rule → `main`**: *Require a pull request before merging*.
- **Collaborators**: invite a su compañero con permiso *Write*.
- Mantenga el repositorio **privado**: hay IDs de cuenta e IPs en archivos rastreados.

## 4. Estructura esperada en el repo
```
cloudformation/main.yaml, network.yaml, compute.yaml (o red/seguridad/servidores)
cloudformation/parameters/lab.json      (SOLO local, en .gitignore; el CI lo genera desde variables)
scripts/cfn-changeset.sh
.github/workflows/cloudformation.yml
```
En `main.yaml` los hijos deben ser rutas locales (`TemplateURL: network.yaml`); `aws cloudformation package` las reemplaza por URLs de S3.
