# Prerequisites

Before running `deploy.sh`, you need:

## Local machine

- **Azure CLI** (`az`) — [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  - Logged in: `az login`
  - Subscription set: `az account set --subscription YOUR_SUB_ID`
- **Tailscale** — [Install](https://tailscale.com/download)
  - Logged in to your tailnet
  - SSH enabled in ACLs (Settings > Access Controls)
- **SSH client** — built into macOS/Linux/Windows 10+
- `envsubst` — part of `gettext` (`brew install gettext` / `apt install gettext-base`)

## Accounts

- **Azure subscription** with permissions to create VMs, VNETs, NSGs
- **Tailscale account** — free tier works
- **Discord bot** — create at [Discord Developer Portal](https://discord.com/developers/applications):
  1. New Application > Bot > Copy token
  2. Enable intents: Message Content, Server Members, Presence
  3. Note the Application ID for the invite URL
- **AI model provider** (at least one):
  - [GitHub Copilot](https://github.com/features/copilot) — device flow auth during deployment
  - [Anthropic API key](https://console.anthropic.com/) — set during `openclaw onboard`
  - [OpenAI API key](https://platform.openai.com/) — set during `openclaw onboard`

## Optional

- **Tailscale auth key** — generate at [Admin Console > Settings > Keys](https://login.tailscale.com/admin/settings/keys) to skip interactive auth
