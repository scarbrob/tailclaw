#!/usr/bin/env bash
# check-openclaw.sh — Health check: restart gateway if down
set -euo pipefail

export PATH="$HOME/.npm-global/bin:$PATH"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if ! systemctl --user is-active openclaw-gateway.service &>/dev/null; then
  echo "$TIMESTAMP - Gateway service not active, restarting..."
  systemctl --user restart openclaw-gateway.service
  sleep 5
fi

if ! ss -tlnp | grep -q ':18789'; then
  echo "$TIMESTAMP - Port 18789 not listening, restarting..."
  systemctl --user restart openclaw-gateway.service
  sleep 5
fi

if ss -tlnp | grep -q ':18789'; then
  echo "$TIMESTAMP - OK"
else
  echo "$TIMESTAMP - FAILED: gateway not responding after restart"
fi
