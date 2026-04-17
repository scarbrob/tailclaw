# Troubleshooting

## Mullvad VPN + Tailscale

**Problem**: Mullvad blocks the CGNAT range (100.64.0.0/10) that Tailscale uses. When Mullvad is active, Tailscale can't reach your VM.

**Fix**: Toggle Mullvad off when you need VM access. There's no clean coexistence solution — they fight over routing tables.

## Discord bot not responding

**Symptoms**: Bot shows offline in Discord, or shows online but doesn't respond to messages.

**Checklist**:
1. Is the gateway running? `oc-status`
2. Is the Discord token valid? Check gateway logs: `oc-logs`
3. Are intents enabled? Discord Developer Portal > Bot > Privileged Gateway Intents > all three checked
4. Is your guild in the allowlist? Check `openclaw.json` > `channels.discord.guilds`
5. Is `groupPolicy` set to `allowlist`? It defaults to `allowlist`, meaning you need to add guild IDs explicitly
6. Rate limited? Rapid reconnects trigger Discord rate limits. Wait 60 seconds, then `oc-restart`

## "origin not allowed" on Control UI

**Problem**: Opening `http://<vm_name>:18789` shows "origin not allowed".

**Fix**: The gateway binds to loopback. Access via SSH tunnel:
```bash
ssh -N -L 18789:127.0.0.1:18789 <admin_user>@<vm_name>
```
Then open `http://localhost:18789` in your browser.

## Port 18789 not listening

1. Check if gateway crashed: `oc-status`
2. Check for port conflicts: `ss -tlnp | grep 18789`
3. Look at logs: `oc-logs`
4. Restart: `oc-restart`
5. The health check cron should auto-restart within 5 minutes

## "pairing required" errors

**Cause**: `session.dmScope` was set to `per-channel-peer` or similar, which requires device pairing.

**Fix**: Set `session.dmScope` to `main` in `openclaw.json`, then `oc-restart`.

## az vm run-command hangs

Azure's run-command has a ~90 second timeout and can be flaky. If a script hangs:
1. Check VM serial console in Azure Portal
2. Try running the script content directly via Tailscale SSH if Tailscale is already set up
3. Break long scripts into smaller chunks

## Gateway won't start after config change

Run config validation:
```bash
openclaw config validate
```
Common issues:
- `tools.exec.security` must be `deny`, `allowlist`, or `full` (not `sandboxed`)
- `session.dmScope` must be `main`, `per-peer`, `per-channel-peer`, or `per-account-channel-peer` (not `open`)
- `agents.defaults.systemPrompt` doesn't exist — use `systemPromptOverride`
