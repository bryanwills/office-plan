#!/usr/bin/env bash
# Push local backup archives to another device / object storage.
# Configure OFFSITE_METHOD + OFFSITE_TARGET (or RCLONE_REMOTE) in backup.conf
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config

METHOD="${OFFSITE_METHOD:-none}"
log "=== Offsite sync (method=$METHOD) ==="

if [[ "$METHOD" == "none" || -z "${OFFSITE_TARGET:-}${RCLONE_REMOTE:-}" ]]; then
  warn "Offsite sync not configured."
  cat <<'EOF'

Set in backup.conf, then re-run:

  OFFSITE_METHOD="rsync"
  OFFSITE_TARGET="bryan@YOUR-TAILSCALE-IP:/backups/vps-primary/"

or:

  OFFSITE_METHOD="rclone"
  RCLONE_REMOTE="b2:your-bucket/vps-primary/"

Recommended first destination: another VPS, your Mac over Tailscale, or
Backblaze B2 / Wasabi via rclone. Keep at least one copy OFF this VPS.

EOF
  exit 0
fi

# What to sync: recent archives + checksums (not the huge unpacked volume dirs)
INCLUDE_PATHS=(
  "$BACKUP_ROOT/daily"
  "$BACKUP_ROOT/weekly"
  "$BACKUP_ROOT/websites"
  "$BACKUP_ROOT/databases"
  "$BACKUP_ROOT/hermes"
  "$BACKUP_ROOT/volumes"
  "$BACKUP_ROOT/manifests"
)

case "$METHOD" in
  rsync)
    need_cmd rsync
    [[ -n "${OFFSITE_TARGET:-}" ]] || die "OFFSITE_TARGET required for rsync"
    log "rsync -> $OFFSITE_TARGET"
    rsync -avh --partial --progress \
      --include='*/' \
      --include='*.tar.gz' \
      --include='*.tar.gz.gpg' \
      --include='*.zip' \
      --include='*.zip.gpg' \
      --include='*.sql.gz' \
      --include='*.sqlite*.gz' \
      --include='checksums-*.txt' \
      --include='inventory-*.txt' \
      --exclude='*' \
      "${INCLUDE_PATHS[@]}" \
      "$OFFSITE_TARGET"
    ;;
  rclone)
    need_cmd rclone
    [[ -n "${RCLONE_REMOTE:-}" ]] || die "RCLONE_REMOTE required for rclone"
    log "rclone sync -> $RCLONE_REMOTE"
    for p in "${INCLUDE_PATHS[@]}"; do
      [[ -d "$p" ]] || continue
      name="$(basename "$p")"
      rclone sync "$p" "${RCLONE_REMOTE%/}/$name" \
        --include='*.tar.gz' --include='*.tar.gz.gpg' \
        --include='*.zip' --include='*.zip.gpg' \
        --include='*.sql.gz' --include='*.sqlite*.gz' \
        --include='checksums-*.txt' --include='inventory-*.txt' \
        --fast-list -v
    done
    ;;
  *)
    die "Unknown OFFSITE_METHOD: $METHOD (use rsync|rclone|none)"
    ;;
esac

log "Offsite sync complete"
