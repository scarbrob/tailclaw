#!/usr/bin/env bash
# deploy.sh — tailclaw: deploy a hardened OpenClaw instance on Azure + Tailscale
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

# Global error handler — never dump user to shell silently
trap 'echo ""; echo "========================================"; echo "  DEPLOYMENT FAILED"; echo "  Failed at line $LINENO of deploy.sh"; echo "  Review the output above for details."; echo "========================================"' ERR

# ─── Preflight ───────────────────────────────────────────────────────────────

echo "=========================================="
echo "  tailclaw — Hardened OpenClaw Deployment"
echo "=========================================="
echo ""

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: config.env not found."
  echo "Copy the example and fill in your values:"
  echo "  cp config.env.example config.env"
  exit 1
fi

source "$CONFIG_FILE"

# Validate required vars
REQUIRED_VARS=(
  AZURE_SUBSCRIPTION_ID
  AZURE_RESOURCE_GROUP
  AZURE_LOCATION
  AZURE_VM_NAME
  AZURE_VM_SIZE
  AZURE_ADMIN_USER
  DISCORD_BOT_TOKEN
)

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    MISSING+=("$var")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "ERROR: Missing required config variables:"
  printf '  - %s\n' "${MISSING[@]}"
  echo ""
  echo "Edit config.env and fill in these values."
  exit 1
fi

# Check prerequisites
for cmd in az ssh envsubst; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is not installed. See docs/prerequisites.md"
    exit 1
  fi
done

echo "Config loaded. Deploying to:"
echo "  Resource Group: $AZURE_RESOURCE_GROUP"
echo "  Location:       $AZURE_LOCATION"
echo "  VM:             $AZURE_VM_NAME ($AZURE_VM_SIZE)"
echo "  Admin User:     $AZURE_ADMIN_USER"
echo ""
read -rp "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

# Set Azure subscription
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# ─── Phase 1: Azure Infrastructure (az vm run-command) ───────────────────────

echo ""
echo ">>> Phase 1: Azure Infrastructure"
bash "$SCRIPT_DIR/scripts/01-provision-azure.sh"

# ─── Phase 2: OS Hardening (az vm run-command) ──────────────────────────────

echo ""
echo ">>> Phase 2: OS Hardening"
HARDEN_SCRIPT=$(sed -n '/^cat << '\''REMOTE_SCRIPT'\''$/,/^REMOTE_SCRIPT$/p' \
  "$SCRIPT_DIR/scripts/02-harden-os.sh" | sed '1d;$d')

# Inject config values that the single-quoted heredoc can't expand
HARDEN_SCRIPT="${HARDEN_SCRIPT//\$\{DAILY_REBOOT_UTC:0:2\}/${DAILY_REBOOT_UTC:0:2}}"
HARDEN_SCRIPT="${HARDEN_SCRIPT//\$\{DAILY_REBOOT_UTC:2:2\}/${DAILY_REBOOT_UTC:2:2}}"

az vm run-command invoke \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_VM_NAME" \
  --command-id RunShellScript \
  --scripts "$HARDEN_SCRIPT" \
  --output none

echo "OS hardening applied."

# ─── Phase 3: Tailscale (az vm run-command → interactive) ───────────────────

echo ""
echo ">>> Phase 3: Tailscale"
bash "$SCRIPT_DIR/scripts/03-install-tailscale.sh"

# ─── Phase 4-8: Via Tailscale SSH ───────────────────────────────────────────

echo ""
echo ">>> Phase 4: Install OpenClaw"
bash "$SCRIPT_DIR/scripts/04-install-openclaw.sh"

echo ""
echo ">>> Phase 5: Configure OpenClaw"
bash "$SCRIPT_DIR/scripts/05-configure-openclaw.sh"

echo ""
echo ">>> Phase 6: Discord Setup"
bash "$SCRIPT_DIR/scripts/06-setup-discord.sh"

echo ""
echo ">>> Phase 7: systemd Setup"
bash "$SCRIPT_DIR/scripts/07-setup-systemd.sh"

echo ""
echo ">>> Phase 8: Monitoring"
bash "$SCRIPT_DIR/scripts/08-setup-monitoring.sh"

# ─── Phase 9: GitHub Copilot (interactive) ──────────────────────────────────

echo ""
echo ">>> Phase 9: GitHub Copilot Auth"
read -rp "Set up GitHub Copilot models now? [y/N] " copilot
if [[ "$copilot" =~ ^[Yy]$ ]]; then
  bash "$SCRIPT_DIR/scripts/09-github-copilot-auth.sh"
fi

# ─── Validation ─────────────────────────────────────────────────────────────

VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo ""
echo "=========================================="
echo "  Validation"
echo "=========================================="

echo -n "Gateway status: "
ssh "$VM" 'systemctl --user is-active openclaw-gateway.service' || echo "INACTIVE"

echo -n "Port 18789: "
ssh "$VM" 'ss -tlnp | grep -q :18789 && echo "LISTENING" || echo "NOT LISTENING"'

echo -n "Cron jobs: "
ssh "$VM" 'crontab -l 2>/dev/null | wc -l'

echo ""
echo "=========================================="
echo "  Deployment complete!"
echo ""
echo "  SSH:        ssh ${VM}"
echo "  Status:     ssh ${VM} oc-status"
echo "  Logs:       ssh ${VM} oc-logs"
echo "  Control UI: ssh -N -L 18789:127.0.0.1:18789 ${VM}"
echo "              then open http://localhost:18789"
echo "=========================================="
