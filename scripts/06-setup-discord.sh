#!/usr/bin/env bash
# 06-setup-discord.sh — Configure Discord channel in OpenClaw
set -euo pipefail

source "$(dirname "$0")/../config.env"

VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo "=== Setting up Discord ==="

ssh "$VM" bash << REMOTE
set -euo pipefail
export PATH="\$HOME/.npm-global/bin:\$PATH"
source ~/.openclaw/.env

echo "[1/2] Adding Discord channel..."
openclaw channels add \
  --channel discord \
  --token "\$DISCORD_BOT_TOKEN" \
  2>&1 || echo "(channel may already exist)"

echo "[2/2] Discord channel configured."
echo ""
echo "============================================"
echo " NEXT STEPS (manual):"
echo " 1. Go to Discord Developer Portal"
echo " 2. Enable intents: Message Content,"
echo "    Server Members, Presence"
echo " 3. Invite bot to your server with URL:"
echo "    https://discord.com/oauth2/authorize"
echo "    ?client_id=YOUR_APP_ID&scope=bot"
echo "    &permissions=274877991936"
echo " 4. The guild, role, and DM allowlist"
echo "    are set in openclaw.json"
echo "============================================"
REMOTE
