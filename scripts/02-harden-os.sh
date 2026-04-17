#!/usr/bin/env bash
# 02-harden-os.sh — OS hardening (runs ON the VM via az vm run-command)
set -euo pipefail

cat << 'REMOTE_SCRIPT'
#!/bin/bash
set -euo pipefail

echo "=== OS Hardening ==="

# System update
echo "[1/6] Updating packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Unattended upgrades
echo "[2/6] Enabling unattended security upgrades..."
apt-get install -y -qq unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Fail2ban
echo "[3/6] Installing fail2ban..."
apt-get install -y -qq fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF
systemctl enable fail2ban
systemctl restart fail2ban

# UFW
echo "[4/6] Configuring UFW..."
apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0
ufw --force enable

# SSHD hardening
echo "[5/6] Hardening SSHD..."
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
systemctl restart sshd

# Journal size limit
echo "[6/6] Limiting journal size..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size.conf << 'EOF'
[Journal]
SystemMaxUse=100M
EOF
systemctl restart systemd-journald

echo "=== OS hardening complete ==="
REMOTE_SCRIPT
