# Security Model

tailclaw deploys OpenClaw with 9 layers of defense-in-depth. No single layer is relied upon alone.

## Layers

| # | Layer | What it blocks |
|---|-------|---------------|
| 1 | **Azure NSG: deny-all-inbound, no public IP** | All internet-facing attacks. The VM is invisible to the internet. |
| 2 | **UFW firewall** | VNET-internal attacks. Only allows traffic on the `tailscale0` interface. |
| 3 | **Tailscale (WireGuard mesh + SSH)** | Unauthenticated remote access. All connections are end-to-end encrypted and identity-verified. |
| 4 | **SSHD: key-only, no root, fail2ban** | Brute-force and password attacks. 3 failed attempts = 1 hour ban. |
| 5 | **OpenClaw: loopback bind + token auth** | Unauthorized gateway access. Gateway only listens on 127.0.0.1. |
| 6 | **Discovery: mDNS off** | LAN broadcast/discovery. The instance doesn't advertise itself. |
| 7 | **Discord: DM allowlist + role-based guild access** | Strangers messaging the bot. Only approved users/roles can interact. |
| 8 | **Tool restrictions** | Prompt injection escalation. `gateway` tool denied, elevated access disabled. |
| 9 | **File permissions (700/600)** | Local privilege escalation. Config and secrets readable only by owner. |

## Update strategy

Security patches are installed automatically via `unattended-upgrades`, but the VM **never reboots or restarts services on its own**:

- `Unattended-Upgrade::Automatic-Reboot` is set to `false`
- `needrestart` is set to list-only mode (`'l'`) — it logs what needs restarting but doesn't act
- A daily reboot cron (configurable, default 2:30 AM PST) applies pending kernel updates and service restarts in a predictable window
- OpenClaw auto-starts after reboot via systemd + linger, so the bot comes back online within seconds

This avoids surprise outages mid-conversation while keeping the system patched.

## Why these specific settings

### `gateway.bind: loopback` (not `tailnet`)
Binding to loopback means the gateway only accepts connections from localhost. Even if someone is on your tailnet, they can't hit the gateway directly — you need an SSH tunnel.

### `tailscale.mode: off` (not `serve`)
We learned that `serve` mode conflicts with loopback bind. The gateway throws: "gateway.bind must resolve to loopback when gateway.tailscale.mode=serve". Keeping it off and using SSH tunnels is simpler and more secure.

### `session.dmScope: main` (not `per-channel-peer`)
`per-channel-peer` requires device pairing which causes "pairing required" errors for new connections. `main` uses a single session — simpler for personal use.

### `tools.exec.security: full`
The bot has full shell access on the VM. This is intentional — the VM is isolated and the assistant needs to manage it. The security boundary is the VM itself + Tailscale access control.

### Gateway token as plaintext
The `gateway.auth.token` schema doesn't support env var references. The token is stored in `openclaw.json` (chmod 600). The file is only readable by the service user.

### Discord token as env ref
Unlike the gateway token, Discord's channel config supports `{"$env": "DISCORD_BOT_TOKEN"}` references. The actual token lives in `.env`, loaded via systemd's `EnvironmentFile`.
