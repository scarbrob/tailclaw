#!/usr/bin/env bash
# 05-configure-openclaw.sh — Generate openclaw.json from template
set -euo pipefail

source "$(dirname "$0")/../config.env"
TEMPLATE_DIR="$(dirname "$0")/../templates"
VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo "=== Configuring OpenClaw ==="

# Generate gateway token if not provided
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 24)
  echo "Generated gateway token: ${OPENCLAW_GATEWAY_TOKEN}"
  echo "Save this — you'll need it for API access."
fi

# Build openclaw.json from template
echo "[1/3] Generating openclaw.json..."
export OPENCLAW_GATEWAY_TOKEN OPENCLAW_GATEWAY_PORT OPENCLAW_PERSONALITY
export DISCORD_BOT_TOKEN DISCORD_GUILD_ID DISCORD_ROLE_ID DISCORD_DM_ALLOW_USER_IDS
export GITHUB_COPILOT_DEFAULT_MODEL

RENDERED=$(envsubst < "$TEMPLATE_DIR/openclaw.json.tmpl")

ssh "$VM" bash << REMOTE || { echo ""; echo "ERROR: OpenClaw configuration failed. Check output above."; exit 1; }
set -euo pipefail
trap 'echo ""; echo "ERROR: Configuration failed at step (line \$LINENO)"; exit 1' ERR

# Write config
cat > ~/.openclaw/openclaw.json << 'CONFIGEOF'
${RENDERED}
CONFIGEOF

# Write .env
echo "[2/3] Writing secrets to .env..."
cat > ~/.openclaw/.env << 'ENVEOF'
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
ENVEOF

# Lock down permissions
echo "[3/3] Setting file permissions..."
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/.env

echo "=== OpenClaw configuration complete ==="
REMOTE
