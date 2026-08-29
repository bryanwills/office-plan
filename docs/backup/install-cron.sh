#!/usr/bin/env bash
# Append recommended cron entries (idempotent: skips if marker present).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER="# vps-backup-toolkit"

EXISTING="$(crontab -l 2>/dev/null || true)"
if echo "$EXISTING" | grep -qF "$MARKER"; then
  echo "Cron entries already installed ($MARKER)."
  exit 0
fi

TMP="$(mktemp)"
{
  echo "$EXISTING"
  echo
  echo "$MARKER"
  echo "# Daily 02:30 — DBs, sites, docker bind data, hermes, offsite sync"
  echo "30 2 * * * $SCRIPT_DIR/backup-all.sh >> $SCRIPT_DIR/../../backups/logs/cron-daily.log 2>&1"
  echo "# Weekly Sunday 03:15 — fuller archive + named volumes"
  echo "15 3 * * 0 $SCRIPT_DIR/backup-all.sh --weekly >> $SCRIPT_DIR/../../backups/logs/cron-weekly.log 2>&1"
} > "$TMP"

crontab "$TMP"
rm -f "$TMP"
echo "Installed cron entries. Review with: crontab -l"
echo "Configure OFFSITE_TARGET in $SCRIPT_DIR/backup.conf before relying on sync."
