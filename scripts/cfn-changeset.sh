#!/usr/bin/env bash
set -Eeuo pipefail

# Uso:
#   bash scripts/cfn-changeset.sh plan                         empaqueta, valida y MUESTRA los cambios (no ejecuta)
#   CONFIRM_EXECUTE=true bash scripts/cfn-changeset.sh apply   ejecuta, solo si no elimina ni reemplaza recursos
#
# Variables obligatorias: STACK_NAME, ARTIFACT_BUCKET

MODE="${1:-}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
TEMPLATE="${TEMPLATE:-cloudformation/main.yaml}"
PARAMETERS="${PARAMETERS:-cloudformation/parameters/lab.json}"
PACKAGED_TEMPLATE="${PACKAGED_TEMPLATE:-build/packaged.yaml}"
CAPABILITIES="${CAPABILITIES:-}"   # vacio: estas plantillas no crean recursos IAM

: "${STACK_NAME:?Debes configurar STACK_NAME}"
: "${ARTIFACT_BUCKET:?Debes configurar ARTIFACT_BUCKET}"

if [[ "$MODE" != "plan" && "$MODE" != "apply" ]]; then
  echo "Uso: $0 plan|apply" >&2
  exit 2
fi

for command in aws jq; do
  command -v "$command" >/dev/null 2>&1 || { echo "ERROR: falta el comando requerido: $command" >&2; exit 2; }
done
[[ -f "$TEMPLATE" ]]   || { echo "ERROR: no existe $TEMPLATE" >&2; exit 2; }
[[ -f "$PARAMETERS" ]] || { echo "ERROR: no existe $PARAMETERS" >&2; exit 2; }

CHANGE_SET_TYPE=""
CHANGE_SET_NAME=""
CS_CREATED=0
KEEP=0

cleanup() {
  if [[ "$CS_CREATED" == 1 && "$KEEP" == 0 ]]; then
    aws cloudformation delete-change-set --stack-name "$STACK_NAME" --change-set-name "$CHANGE_SET_NAME" \
      --region "$REGION" >/dev/null 2>&1 || true
    if [[ "$CHANGE_SET_TYPE" == "CREATE" ]]; then
      local st
      st="$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
        --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
      if [[ "$st" == "REVIEW_IN_PROGRESS" ]]; then
        aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION" >/dev/null 2>&1 || true
      fi
    fi
  fi
}
trap cleanup EXIT

mkdir -p "$(dirname "$PACKAGED_TEMPLATE")"

echo "==> Empaquetando plantillas anidadas (solo sube archivos a S3; no crea recursos)..."
aws cloudformation package \
  --template-file "$TEMPLATE" \
  --s3-bucket "$ARTIFACT_BUCKET" \
  --s3-prefix "$STACK_NAME" \
  --output-template-file "$PACKAGED_TEMPLATE" \
  --region "$REGION" >/dev/null

echo "==> Validando plantilla empaquetada (esto NO despliega nada)..."
aws cloudformation validate-template --template-body "file://$PACKAGED_TEMPLATE" --region "$REGION" >/dev/null

STACK_STATUS="$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$STACK_STATUS" in
  ""|None|REVIEW_IN_PROGRESS) CHANGE_SET_TYPE="CREATE" ;;
  ROLLBACK_COMPLETE|CREATE_FAILED|DELETE_FAILED)
    echo "ERROR: el stack '$STACK_NAME' esta en $STACK_STATUS y no se puede actualizar." >&2
    echo "Revise los eventos y elimínelo: aws cloudformation delete-stack --stack-name $STACK_NAME" >&2
    exit 1 ;;
  *) CHANGE_SET_TYPE="UPDATE" ;;
esac

CHANGE_SET_NAME="${STACK_NAME}-$(date -u +%Y%m%d%H%M%S)"

EXTRA_ARGS=()
if [[ "$CHANGE_SET_TYPE" == "UPDATE" ]]; then EXTRA_ARGS+=(--include-nested-stacks); fi
if [[ -n "$CAPABILITIES" ]]; then EXTRA_ARGS+=(--capabilities $CAPABILITIES); fi

echo "==> Creando change set ($CHANGE_SET_TYPE): $CHANGE_SET_NAME"
aws cloudformation create-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --change-set-type "$CHANGE_SET_TYPE" \
  --template-body "file://$PACKAGED_TEMPLATE" \
  --parameters "file://$PARAMETERS" \
  --description "scripts/cfn-changeset.sh ($MODE)" \
  --region "$REGION" \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} >/dev/null
CS_CREATED=1

set +e
aws cloudformation wait change-set-create-complete --stack-name "$STACK_NAME" --change-set-name "$CHANGE_SET_NAME" --region "$REGION" 2>/dev/null
WAIT_STATUS=$?
set -e

DETAILS="$(aws cloudformation describe-change-set --stack-name "$STACK_NAME" --change-set-name "$CHANGE_SET_NAME" \
  --region "$REGION" --output json)"
STATUS="$(jq -r '.Status // ""' <<<"$DETAILS")"
REASON="$(jq -r '.StatusReason // ""' <<<"$DETAILS")"

if [[ "$STATUS" == "FAILED" ]]; then
  if grep -qiE "didn't contain changes|no changes" <<<"$REASON"; then
    echo "No hay cambios que aplicar."
    exit 0
  fi
  echo "ERROR al crear el change set: $REASON" >&2
  exit 1
fi
if [[ "$WAIT_STATUS" -ne 0 || "$STATUS" != "CREATE_COMPLETE" ]]; then
  echo "ERROR: el change set no termino correctamente: $STATUS $REASON" >&2
  exit 1
fi

BAD=0
inspect() {   # inspect <change-set> [<stack>]  -> imprime cambios y revisa tambien los stacks anidados
  local id="$1" json nested
  if [[ -n "${2:-}" ]]; then
    json="$(aws cloudformation describe-change-set --stack-name "$2" --change-set-name "$id" --region "$REGION" --output json)"
  else
    json="$(aws cloudformation describe-change-set --change-set-name "$id" --region "$REGION" --output json)"
  fi
  jq -r '.Changes[]? | .ResourceChange | [(.Action // "?"), (.LogicalResourceId // "?"), (.ResourceType // "?"), ("Replacement=" + (.Replacement // "N/A"))] | @tsv' <<<"$json"
  if jq -e '[.Changes[]?.ResourceChange | select(.Action=="Remove" or .Action=="Delete" or .Replacement=="True" or .Replacement=="Conditional")] | length > 0' <<<"$json" >/dev/null; then
    BAD=1
  fi
  for nested in $(jq -r '.Changes[]?.ResourceChange.ChangeSetId // empty' <<<"$json"); do
    echo "  -- cambios del stack anidado --"
    inspect "$nested"
  done
}

echo
echo "==> Cambios (Accion / Recurso / Tipo / Reemplazo):"
inspect "$CHANGE_SET_NAME" "$STACK_NAME"
echo
echo "Change set: $CHANGE_SET_NAME | Stack: $STACK_NAME | Region: $REGION"

if [[ "$BAD" == 1 ]]; then
  echo "BLOQUEADO: el change set ELIMINA o REEMPLAZA recursos. Revise el cambio manualmente." >&2
  echo "No se ejecuto ningun cambio." >&2
  exit 1
fi

if [[ "$MODE" == "plan" ]]; then
  echo "PLAN correcto: sin eliminaciones ni reemplazos. No se ejecuto ningun cambio."
  exit 0
fi

if [[ "${CONFIRM_EXECUTE:-}" != "true" ]]; then
  echo "BLOQUEADO: para ejecutar, revise el change set y defina CONFIRM_EXECUTE=true." >&2
  exit 1
fi

echo "==> Ejecutando change set..."
KEEP=1
aws cloudformation execute-change-set --stack-name "$STACK_NAME" --change-set-name "$CHANGE_SET_NAME" --region "$REGION"
if [[ "$CHANGE_SET_TYPE" == "CREATE" ]]; then WAITER="stack-create-complete"; else WAITER="stack-update-complete"; fi
if ! aws cloudformation wait "$WAITER" --stack-name "$STACK_NAME" --region "$REGION"; then
  echo "ERROR: el despliegue fallo. Eventos con error:" >&2
  aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --region "$REGION" \
    --query "StackEvents[?contains(ResourceStatus,'FAILED')].[LogicalResourceId,ResourceStatusReason]" --output text >&2 || true
  exit 1
fi
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
  --query 'Stacks[0].[StackName,StackStatus]' --output text
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output table || true
