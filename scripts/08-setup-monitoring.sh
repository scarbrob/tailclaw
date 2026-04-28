#!/usr/bin/env bash
# 08-setup-monitoring.sh — Health checks, backups, logrotate
set -euo pipefail

fail() { echo ""; echo "ERROR: $1"; echo "Setup failed at: $2"; exit 1; }

source "$(dirname "$0")/../config.env" || fail "Could not load config.env" "config load"
TEMPLATE_DIR="$(dirname "$0")/../templates"
VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo "=== Setting up monitoring ==="

# Copy scripts
echo "[1/4] Copying monitoring scripts..."
scp "$TEMPLATE_DIR/check-openclaw.sh" "$VM:~/check-openclaw.sh" || fail "Failed to copy check-openclaw.sh" "step 1/4"
scp "$TEMPLATE_DIR/backup-openclaw.sh" "$VM:~/backup-openclaw.sh" || fail "Failed to copy backup-openclaw.sh" "step 1/4"
scp "$TEMPLATE_DIR/openclaw-logrotate" "$VM:~/openclaw-logrotate" || fail "Failed to copy openclaw-logrotate" "step 1/4"

ssh "$VM" bash << 'REMOTE' || fail "Remote monitoring setup failed" "remote execution"
set -euo pipefail

trap 'echo ""; echo "ERROR: Monitoring setup failed at line $LINENO"; exit 1' ERR

chmod +x ~/check-openclaw.sh ~/backup-openclaw.sh

# Health check cron — every 5 minutes
echo "[2/4] Setting up health check cron..."
( (crontab -l 2>/dev/null || true) | grep -v check-openclaw; echo "*/5 * * * * $HOME/check-openclaw.sh >> $HOME/.openclaw/health.log 2>&1") | crontab -

# Backup cron — daily at 3 AM UTC
echo "[3/4] Setting up backup cron..."
( (crontab -l 2>/dev/null || true) | grep -v backup-openclaw; echo "0 3 * * * $HOME/backup-openclaw.sh >> $HOME/.openclaw/backup.log 2>&1") | crontab -

# Logrotate
echo "[4/4] Setting up log rotation..."
sudo mv ~/openclaw-logrotate /etc/logrotate.d/openclaw
sudo chown root:root /etc/logrotate.d/openclaw

echo "Crontab:"
crontab -l
echo ""
echo "=== Monitoring setup complete ==="
REMOTE
