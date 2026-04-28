# tailclaw

Deploy a hardened [OpenClaw](https://openclaw.ai/) instance on Azure, accessible only via [Tailscale](https://tailscale.com/). No public IP, no open ports, zero attack surface.

## Features

- **Azure VM** — no public IP, deny-all-inbound NSG
- **OS hardening** — UFW, fail2ban, key-only SSH, unattended security patches
- **Update strategy** — patches install automatically, restarts only during daily reboot window
- **Tailscale** — WireGuard mesh VPN for all access (SSH + Control UI)
- **OpenClaw** — gateway on loopback with token auth, mDNS disabled
- **Discord** — bot with guild/role allowlists and DM policies
- **Models** — configurable AI provider (GitHub Copilot, Anthropic, OpenAI, etc.)
- **Reliability** — systemd auto-start, health checks (5 min), daily backups, log rotation
- **UX** — clear error messages on failure, no silent crashes; every step reports what went wrong and where

## Prerequisites

- Azure CLI (`az`) logged in with VM creation permissions
- Tailscale installed and logged in
- `envsubst` (part of `gettext`)
- A Discord bot token ([Developer Portal](https://discord.com/developers/applications))
- GitHub account with Copilot access (optional — or Anthropic/OpenAI API keys)

Full details in [docs/prerequisites.md](docs/prerequisites.md).

## Usage

```bash
# Configure
cp config.env.example config.env
nano config.env                     # fill in your values

# Deploy
chmod +x deploy.sh scripts/*.sh
./deploy.sh
```

The orchestrator provisions the VM, hardens the OS, installs Tailscale, sets up OpenClaw with Discord, enables systemd auto-start, and configures monitoring. Model provider auth (if needed) runs interactively at the end.

## Architecture

```
Your device                          Deploy pipeline
  │                                    │
  │  Tailscale (WireGuard)             ├─ 01 Provision Azure (VM, VNET, NSG)
  │                                    ├─ 02 Harden OS (UFW, fail2ban, patches)
  ▼                                    ├─ 03 Install Tailscale (mesh VPN)
Azure VM (no public IP)                ├─ 04 Install OpenClaw (Node.js + npm)
  ├── NSG: deny-all-inbound            ├─ 05 Configure OpenClaw (token, config)
  ├── UFW: tailscale0 only             ├─ 06 Discord setup (bot channel)
  ├── fail2ban + key-only SSH          ├─ 07 systemd service (auto-start)
  ├── 4GB swap (OOM protection)        ├─ 08 Monitoring (cron, backup, logrotate)
  └── OpenClaw Gateway (loopback)      └─ 09 GitHub Copilot auth (optional)
        ├── Discord bot (guild/role ACL)
        ├── AI models (configurable)
        ├── systemd (auto-restart)
        ├── Daily reboot (update window)
        ├── Health check (every 5 min)
        └── Backup (daily, 14-day retention)
```

## Post-deployment

```bash
ssh <admin_user>@<vm_name>

oc-status    # gateway status
oc-logs      # follow logs
oc-restart   # restart gateway
oc-config    # edit config

# Control UI via SSH tunnel
ssh -N -L 18789:127.0.0.1:18789 <admin_user>@<vm_name>
# open http://localhost:18789
```

## Documentation

- [Prerequisites](docs/prerequisites.md)
- [Security Model](docs/security-model.md) — 9 layers of defense-in-depth
- [Troubleshooting](docs/troubleshooting.md)

## License

MIT
