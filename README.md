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
Your device
  │
  │  Tailscale (WireGuard)
  │
Azure VM
  ├── NSG: deny-all-inbound, no public IP
  ├── UFW: tailscale0 interface only
  ├── fail2ban + key-only SSH
  └── OpenClaw Gateway (127.0.0.1:18789)
        ├── Discord bot (allowlisted guilds/roles)
        ├── AI models (configurable provider)
        ├── systemd (auto-restart on failure)
        ├── Daily reboot cron (applies pending updates)
        ├── Health check cron (every 5 min)
        └── Backup cron (daily, 14-day retention)
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
