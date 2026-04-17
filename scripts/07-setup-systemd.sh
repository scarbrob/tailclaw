#!/usr/bin/env bash
# 07-setup-systemd.sh — systemd user service with auto-start on boot
set -euo pipefail

source "$(dirname "$0")/../config.env"
TEMPLATE_DIR="$(dirname "$0")/../templates"
VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo "=== Setting up systemd ==="

# Copy templates to VM
echo "[1/4] Copying service files..."
scp "$TEMPLATE_DIR/openclaw-gateway.service" "$VM:~/openclaw-gateway.service"
scp "$TEMPLATE_DIR/env.conf.tmpl" "$VM:~/env.conf"
scp "$TEMPLATE_DIR/watchdog.conf" "$VM:~/watchdog.conf"

ssh "$VM" bash << 'REMOTE'
set -euo pipefail

# Install service
echo "[2/4] Installing systemd service..."
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d
mv ~/openclaw-gateway.service ~/.config/systemd/user/
mv ~/env.conf ~/.config/systemd/user/openclaw-gateway.service.d/
mv ~/watchdog.conf ~/.config/systemd/user/openclaw-gateway.service.d/

# Enable lingering (service survives logout)
echo "[3/4] Enabling linger..."
sudo loginctl enable-linger "$(whoami)"

# Enable and start
echo "[4/4] Enabling and starting gateway..."
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user restart openclaw-gateway.service

sleep 3
systemctl --user status openclaw-gateway.service --no-pager || true

echo "=== systemd setup complete ==="
REMOTE
