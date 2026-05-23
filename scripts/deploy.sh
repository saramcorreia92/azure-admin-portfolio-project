#!/usr/bin/env bash
# =============================================================
#  deploy.sh - create the resource group and deploy the Bicep template.
#  Usage: ./deploy.sh
#  Prereqs: az CLI installed and 'az login' completed.
# =============================================================

set -euo pipefail

# ---- Config (edit these) ----
RESOURCE_GROUP="rg-bicep-landing-zone"
LOCATION="uksouth"
DEPLOYMENT_NAME="landing-zone-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="bicep/main.bicep"
PARAMS_FILE="bicep/main.parameters.json"   # your real params file (gitignored)

# ---- Safety check ----
if [ ! -f "$PARAMS_FILE" ]; then
  echo "ERROR: $PARAMS_FILE not found."
  echo "Copy bicep/main.parameters.example.json to bicep/main.parameters.json"
  echo "and fill in your SSH public key before deploying."
  exit 1
fi

echo "==> Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags project=azure-bicep-landing-zone managedBy=bicep \
  --output table

echo "==> Validating template..."
az deployment group validate \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "@$PARAMS_FILE" \
  --output none
echo "    Validation passed."

echo "==> Previewing changes (what-if)..."
az deployment group what-if \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "@$PARAMS_FILE"

echo "==> Deploying (this can take a few minutes)..."
az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "@$PARAMS_FILE" \
  --output table

echo ""
echo "==> Done. Outputs:"
az deployment group show \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query properties.outputs \
  --output json
