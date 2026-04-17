#!/usr/bin/env bash
# backup-openclaw.sh — Daily backup of OpenClaw config and credentials
set -euo pipefail

BACKUP_DIR="$HOME/.openclaw/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/openclaw-backup-${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

tar czf "$BACKUP_FILE" \
  -C "$HOME/.openclaw" \
  openclaw.json \
  .env \
  credentials/ \
  identity/ \
  2>/dev/null || true

echo "Backup created: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Keep only last 14 backups
ls -t "$BACKUP_DIR"/openclaw-backup-*.tar.gz 2>/dev/null | tail -n +15 | xargs rm -f 2>/dev/null || true
