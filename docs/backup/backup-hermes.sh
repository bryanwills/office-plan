#!/usr/bin/env bash
# Use Hermes' native backup (config, skills, sessions, state).
# Also supports profile export for LLC vs personal separation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config

if [[ "${BACKUP_HERMES:-1}" != "1" ]]; then
  log "BACKUP_HERMES disabled — skip"
  exit 0
fi

log "=== Hermes backup ==="
if ! command -v hermes >/dev/null 2>&1; then
  warn "hermes not on PATH — skip"
  exit 0
fi

dest="$BACKUP_ROOT/hermes"
mkdir -p "$dest"
out="${dest}/hermes-backup-${STAMP}.zip"

log "Running: hermes backup -o $out"
if hermes backup -o "$out"; then
  maybe_encrypt "$out" >/dev/null
  log "Hermes backup OK ($(du -h "$out"* 2>/dev/null | head -3))"
else
  warn "hermes backup failed (VPS profile may be empty/unconfigured)"
fi

# Quick critical-state snapshot (Hermes stores these as dirs under ~/.hermes/state-snapshots/)
if hermes backup --quick -l "vps-${STAMP}" 2>/dev/null; then
  latest_snap="$(find "${HOME}/.hermes/state-snapshots" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- || true)"
  if [[ -n "$latest_snap" && -d "$latest_snap" ]]; then
    snap_name="$(basename "$latest_snap")"
    snap_tar="${dest}/hermes-quick-${snap_name}.tar.gz"
    tar -czf "$snap_tar" -C "$(dirname "$latest_snap")" "$snap_name"
    sha_manifest "$snap_tar"
    log "Hermes quick snapshot archived: $snap_tar"
  else
    log "Hermes quick snapshot created in ~/.hermes/state-snapshots/"
  fi
fi

# Export named profiles if any exist beyond default
while read -r profile; do
  [[ -z "$profile" || "$profile" == "default" || "$profile" == "Profile" ]] && continue
  [[ "$profile" =~ ^[A-Za-z0-9_-]+$ ]] || continue
  pout="${dest}/hermes-profile-${profile}-${STAMP}.tar.gz"
  if hermes profile export "$profile" -o "$pout" 2>/dev/null; then
    sha_manifest "$pout"
    log "Exported profile: $profile"
  fi
done < <(hermes profile list 2>/dev/null | sed -n 's/^[[:space:]]*◆\?\([A-Za-z0-9_-]\+\).*/\1/p' || true)

prune_old "$dest" "${DAILY_KEEP_DAYS:-14}" 'hermes-*.zip*'
prune_old "$dest" "${DAILY_KEEP_DAYS:-14}" 'hermes-profile-*.tar.gz*'
log "Hermes backup complete"

cat <<'NOTE'

Hermes multi-device notes
------------------------
- `hermes backup` / restore copies config+state between machines.
- `hermes gateway` is the messaging bridge (Telegram/Discord/etc.), not a
  full CRDT sync of every machine's filesystem. Devices can share gateway
  access / relay enrollment so they see the same messaging surface.
- For LLC vs personal: create a dedicated profile on the LLC VPS:
    hermes profile create llc
    hermes profile use llc
    hermes setup
  Export/import profiles with `hermes profile export|import`.
- Run this same script on your MacBook and Pi so each device has an offsite
  copy under BACKUP_ROOT (or sync those zips with sync-offsite.sh).

NOTE
