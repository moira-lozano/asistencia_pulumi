
#!/usr/bin/env bash
set -Eeuo pipefail

# Uso:
# bash scripts/cfn-changeset.sh plan
# bash scripts/cfn-changeset.sh apply

MODE="${1:-}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
TEMPLATE="cloudformation/main.yaml"
PARAMETERS="cloudformation/parameters/lab.json"
PACKAGED_TEMPLATE="packaged.yaml"

: "${STACK_NAME:?Debes configurar STACK_NAME}"
: "${ARTIFACT_BUCKET:?Debes configurar ARTIFACT_BUCKET}"

if [[ "$MODE" != "plan" && "$MODE" != "apply" ]]; then
  echo "Uso: $0 plan|apply" >&2
  exit 2
fi

for command in aws jq; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "ERROR: falta el comando requerido: $command" >&2
    exit 2
  }
done

[[ -f "$TEMPLATE" ]] || {
  echo "ERROR: no existe $TEMPLATE" >&2
  exit 2
}

[[ -f "$PARAMETERS" ]] || {
  echo "ERROR: no existe $PARAMETERS" >&2
  exit 2
}

echo "==> Empaquetando plantillas anidadas..."
aws cloudformation package \
  --template-file "$TEMPLATE" \
  --s3-bucket "$ARTIFACT_BUCKET" \
  --s3-prefix "$STACK_NAME" \
  --output-template-file "$PACKAGED_TEMPLATE" \
  --region "$REGION"

echo "==> Validando plantilla empaquetada..."
aws cloudformation validate-template \
  --template-body "file://$PACKAGED_TEMPLATE" \
  --region "$REGION" >/dev/null

# Determinar si el stack ya existe.
if aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" >/dev/null 2>&1; then
  CHANGE_SET_TYPE="UPDATE"
else
  CHANGE_SET_TYPE="CREATE"
fi

CHANGE_SET_NAME="${STACK_NAME}-$(date -u +%Y%m%d%H%M%S)"

echo "==> Creando change set ($CHANGE_SET_TYPE)..."
aws cloudformation create-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --change-set-type "$CHANGE_SET_TYPE" \
  --template-body "file://$PACKAGED_TEMPLATE" \
  --parameters "file://$PARAMETERS" \
  --capabilities CAPABILITY_NAMED_IAM \
  --include-nested-stacks \
  --description "Preparado por scripts/cfn-changeset.sh ($MODE)" \
  --region "$REGION" >/dev/null

set +e
aws cloudformation wait change-set-create-complete \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$REGION"
WAIT_STATUS=$?
set -e

DETAILS="$(aws cloudformation describe-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$REGION" \
  --output json)"

STATUS="$(jq -r '.Status // ""' <<<"$DETAILS")"
REASON="$(jq -r '.StatusReason // ""' <<<"$DETAILS")"

if [[ "$STATUS" == "FAILED" ]]; then
  if grep -qi "didn't contain changes\|no changes" <<<"$REASON"; then
    echo "No hay cambios que aplicar."
    exit 0
  fi
  echo "ERROR al crear el change set: $REASON" >&2
  exit 1
fi

if [[ "$WAIT_STATUS" -ne 0 || "$STATUS" != "CREATE_COMPLETE" ]]; then
  echo "ERROR: el change set no terminó correctamente: $STATUS $REASON" >&2
  exit 1
fi

echo
echo "==> Cambios detectados:"
jq -r '
  .Changes[]? |
  [
    (.ResourceChange.Action // "?"),
    (.ResourceChange.ResourceType // "?"),
    (.ResourceChange.LogicalResourceId // "?"),
    ("Replacement=" + (.ResourceChange.Replacement // "N/A"))
  ] | @tsv
' <<<"$DETAILS" | column -t -s $'\t' || true

echo
echo "Change set: $CHANGE_SET_NAME"
echo "Stack:      $STACK_NAME"
echo "Región:     $REGION"

# PLAN nunca ejecuta cambios.
if [[ "$MODE" == "plan" ]]; then
  echo "PLAN: no se ejecutó ningún cambio en CloudFormation."
  exit 0
fi

# Bloqueo conservador de eliminaciones, reemplazos y cambios
# en stacks anidados que requieren inspección manual.
if jq -e '
  [
    .Changes[]?.ResourceChange? |
    select(
      .Action == "Remove" or
      .Action == "Delete" or
      .Replacement == "True" or
      .Replacement == "Conditional" or
      .ResourceType == "AWS::CloudFormation::Stack"
    )
  ] | length > 0
' <<<"$DETAILS" >/dev/null; then
  echo "BLOQUEADO: hay eliminaciones, posibles reemplazos o cambios en stacks anidados." >&2
  echo "Inspecciona manualmente el change set y los cambios de cada stack anidado." >&2
  echo "No se ejecutó el despliegue." >&2
  exit 1
fi

if [[ "${CONFIRM_EXECUTE:-}" != "true" ]]; then
  echo "BLOQUEADO: para ejecutar, revisa el change set y define CONFIRM_EXECUTE=true." >&2
  exit 1
fi

echo "==> Ejecutando change set..."
aws cloudformation execute-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$REGION"

echo "Solicitud de ejecución enviada. Verifica el estado del stack en AWS."
