#!/usr/bin/env bash
# 02-harden-os.sh — OS hardening (runs ON the VM via az vm run-command)
set -euo pipefail

cat << 'REMOTE_SCRIPT'
#!/bin/bash
set -euo pipefail

echo "=== OS Hardening ==="

# System update
echo "[1/8] Updating packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Unattended upgrades — install patches automatically, never reboot or restart services
echo "[2/8] Configuring unattended security upgrades..."
apt-get install -y -qq unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Disable auto-reboot after kernel updates — the daily reboot cron handles this
cat > /etc/apt/apt.conf.d/51no-auto-reboot << 'EOF'
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Disable needrestart auto-restarts — set to list-only mode
if dpkg -l needrestart >/dev/null 2>&1; then
  sed -i "s/^\$nrconf{restart} = .*$/\$nrconf{restart} = 'l';/" /etc/needrestart/needrestart.conf
fi

# Fail2ban
echo "[3/8] Installing fail2ban..."
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
echo "[4/8] Configuring UFW..."
apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0
ufw --force enable

# SSHD hardening
echo "[5/8] Hardening SSHD..."
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
systemctl restart sshd

# Journal size limit
echo "[6/8] Limiting journal size..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size.conf << 'EOF'
[Journal]
SystemMaxUse=100M
EOF
systemctl restart systemd-journald

# Daily reboot cron — pending kernel updates and service restarts take effect here
echo "[7/7] Setting up daily reboot cron..."
REBOOT_HOUR="${DAILY_REBOOT_UTC:0:2}"
REBOOT_MIN="${DAILY_REBOOT_UTC:2:2}"
echo "${REBOOT_MIN} ${REBOOT_HOUR} * * * root /sbin/shutdown -r now" > /etc/cron.d/daily-reboot
chmod 644 /etc/cron.d/daily-reboot

echo "=== OS hardening complete ==="
REMOTE_SCRIPT
