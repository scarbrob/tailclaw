#!/usr/bin/env bash
# 09-github-copilot-auth.sh — Interactive GitHub Copilot device flow
set -euo pipefail

source "$(dirname "$0")/../config.env"

VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo "=== GitHub Copilot Authentication ==="
echo ""
echo "This step is interactive — you'll need to visit a URL"
echo "and enter a code to authorize GitHub Copilot access."
echo ""

ssh -t "$VM" bash << 'REMOTE'
set -euo pipefail
export PATH="$HOME/.npm-global/bin:$PATH"

echo "Starting GitHub Copilot device flow..."
if ! openclaw models auth login-github-copilot; then
  echo ""
  echo "ERROR: GitHub Copilot authentication failed."
  echo "You can retry later: ssh into the VM and run:"
  echo "  openclaw models auth login-github-copilot"
  exit 1
fi

echo ""
echo "Verifying model access..."
openclaw models list 2>/dev/null | head -30 || echo "(run 'openclaw models list' to verify)"

echo ""
echo "=== GitHub Copilot auth complete ==="
REMOTE
