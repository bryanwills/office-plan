#!/usr/bin/env bash
# Archive Docker compose tree + extra host data paths (configs + bind-mounted state).
# Skips bulky regenerable paths and existing backup archives.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config
need_cmd tar

MODE="${1:-daily}"   # daily | weekly
log "=== Docker data backup ($MODE) ==="

case "$MODE" in
  daily)  out_dir="$BACKUP_ROOT/daily" ;;
  weekly) out_dir="$BACKUP_ROOT/weekly" ;;
  *) die "Usage: $0 [daily|weekly]" ;;
esac
mkdir -p "$out_dir"

archive="${out_dir}/docker-data_${STAMP}.tar.gz"
excludes=(
  --exclude='./backups'
  --exclude='./scripts/backup/backup.conf'
  --exclude='./logs.txt'
  --exclude='./buzz/target'
  --exclude='./buzz/.git'
  --exclude='./.git'
  --exclude='*/node_modules'
  --exclude='*/.cache'
  --exclude='*/icon_cache'
  --exclude='./affine/backups'
)

# Daily: skip bulky DB dirs we already dump logically + ollama lives in named volume
if [[ "$MODE" == "daily" ]]; then
  excludes+=(
    --exclude='./forgejo/postgres-data'
    --exclude='./linkwarden/postgres-data'
    --exclude='./docmost/postgres-data'
    --exclude='./docmost/redis-data'
    --exclude='./n8n/data/nodes'
  )
fi

log "Creating $archive from $DOCKER_ROOT"
# Root-owned postgres/vault/pihole paths need elevated read for a complete archive
rm -f "$archive"
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  if command -v pigz >/dev/null 2>&1; then
    sudo tar -I 'pigz -1' -cf "$archive" "${excludes[@]}" -C "$DOCKER_ROOT" .
  else
    sudo tar -czf "$archive" "${excludes[@]}" -C "$DOCKER_ROOT" .
  fi
  sudo chown "$(id -u):$(id -g)" "$archive"
else
  warn "No passwordless sudo — archiving readable files only (DB dumps still cover Postgres)"
  tar_cz "$archive" "${excludes[@]}" -C "$DOCKER_ROOT" . || warn "tar reported unreadable paths; archive may be partial"
fi
maybe_encrypt "$archive" >/dev/null
log "Docker tree archive: $(du -h "$archive"* 2>/dev/null | head -5)"

# Extra paths outside docker root
if ((${#EXTRA_DATA_PATHS[@]} > 0)); then
  extra="${out_dir}/extra-host-data_${STAMP}.tar.gz"
  existing=()
  for p in "${EXTRA_DATA_PATHS[@]}"; do
    [[ -e "$p" ]] && existing+=("$p")
  done
  if ((${#existing[@]} > 0)); then
    log "Archiving extra host paths: ${existing[*]}"
    # Absolute paths under /; sudo needed for root-owned postgres under ~/.affine
    rm -f "$extra"
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
      if command -v pigz >/dev/null 2>&1; then
        sudo tar -I 'pigz -1' -cf "$extra" -C / "${existing[@]/#/}"
      else
        sudo tar -czf "$extra" -C / "${existing[@]/#/}"
      fi
      sudo chown "$(id -u):$(id -g)" "$extra"
    else
      tar_cz "$extra" -C / "${existing[@]/#/}" || warn "extra-host archive may be partial"
    fi
    maybe_encrypt "$extra" >/dev/null
  else
    warn "No EXTRA_DATA_PATHS found on disk"
  fi
fi

# Always keep a copy of compose inventory for restore planning
write_inventory

keep="${DAILY_KEEP_DAYS:-14}"
[[ "$MODE" == "weekly" ]] && keep="${WEEKLY_KEEP_DAYS:-60}"
prune_old "$out_dir" "$keep" 'docker-data_*.tar.gz*'
prune_old "$out_dir" "$keep" 'extra-host-data_*.tar.gz*'

log "Docker data backup ($MODE) complete"
