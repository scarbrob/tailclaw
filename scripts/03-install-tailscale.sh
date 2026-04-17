#!/usr/bin/env bash
# 03-install-tailscale.sh — Install Tailscale and join tailnet
set -euo pipefail

source "$(dirname "$0")/../config.env"

echo "=== Installing Tailscale ==="

# Build the remote script based on whether we have an auth key
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
  TAILSCALE_UP_CMD="tailscale up --ssh --authkey=${TAILSCALE_AUTH_KEY}"
  INTERACTIVE=false
else
  TAILSCALE_UP_CMD="tailscale up --ssh"
  INTERACTIVE=true
fi

REMOTE_SCRIPT=$(cat << ENDSCRIPT
#!/bin/bash
set -euo pipefail

echo "[1/2] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "[2/2] Joining tailnet..."
${TAILSCALE_UP_CMD}

echo "Tailscale status:"
tailscale status
ENDSCRIPT
)

echo "Running Tailscale install via az vm run-command..."
RESULT=$(az vm run-command invoke \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_VM_NAME" \
  --command-id RunShellScript \
  --scripts "$REMOTE_SCRIPT" \
  --output json)

echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['value'][0]['message'])" 2>/dev/null || echo "$RESULT"

if [[ "$INTERACTIVE" == "true" ]]; then
  echo ""
  echo "============================================"
  echo " INTERACTIVE AUTH REQUIRED"
  echo " Check the output above for a Tailscale"
  echo " auth URL. Visit it in your browser to"
  echo " approve the device."
  echo "============================================"
  echo ""
  read -rp "Press Enter once you've approved the device in Tailscale..."
fi

# Verify connectivity
echo "Verifying Tailscale SSH connectivity..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
  "${AZURE_ADMIN_USER}@${AZURE_VM_NAME}" 'echo "Tailscale SSH working"'; then
  echo "=== Tailscale setup complete ==="
else
  echo "ERROR: Cannot SSH via Tailscale. Check that:"
  echo "  1. The device was approved in your tailnet"
  echo "  2. Tailscale SSH is enabled in ACLs"
  echo "  3. The VM hostname matches: ${AZURE_VM_NAME}"
  exit 1
fi
