#!/usr/bin/env bash
# 04-install-openclaw.sh — Install Node.js and OpenClaw (runs via Tailscale SSH)
set -euo pipefail

source "$(dirname "$0")/../config.env"

VM="${AZURE_ADMIN_USER}@${AZURE_VM_NAME}"

echo "=== Installing OpenClaw ==="

ssh "$VM" bash << 'REMOTE' || { echo ""; echo "ERROR: OpenClaw installation failed. Check output above."; exit 1; }
set -euo pipefail
trap 'echo ""; echo "ERROR: Install failed at step (line $LINENO)"; exit 1' ERR

# Node.js 24
echo "[1/4] Installing Node.js 24..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y -qq nodejs
fi
echo "Node.js $(node --version)"

# npm global dir (no sudo for global installs)
echo "[2/4] Configuring npm global directory..."
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
if ! grep -q 'npm-global' ~/.bashrc; then
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.npm-global/bin:$PATH"

# Install OpenClaw
echo "[3/4] Installing OpenClaw..."
npm install -g openclaw

echo "[4/4] Creating workspace directories..."
mkdir -p ~/.openclaw/workspaces
mkdir -p ~/.openclaw/credentials
mkdir -p ~/.openclaw/identity

echo "OpenClaw $(openclaw --version) installed"
echo "=== OpenClaw installation complete ==="
REMOTE
