#!/usr/bin/env bash
# =============================================================
#  destroy.sh - delete the entire resource group and everything in it.
#  Usage: ./destroy.sh
#  This is the cost-control safety net: one command, everything gone.
# =============================================================

set -euo pipefail

RESOURCE_GROUP="rg-bicep-landing-zone"

echo "==> About to DELETE resource group '$RESOURCE_GROUP' and ALL resources in it."
read -r -p "    Type the resource group name to confirm: " CONFIRM

if [ "$CONFIRM" != "$RESOURCE_GROUP" ]; then
  echo "    Name did not match. Aborting. Nothing was deleted."
  exit 1
fi

echo "==> Deleting... (running in background; you can close this terminal)"
az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait

echo "    Delete request submitted. Verify in the portal that the group disappears."
