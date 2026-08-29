#!/usr/bin/env bash
# Export selected named Docker volumes as tarballs.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config
need_cmd docker

log "=== Named volume exports ==="
dest="$BACKUP_ROOT/volumes/${STAMP}"
mkdir -p "$dest"

if ((${#VOLUME_INCLUDE[@]} == 0)); then
  warn "VOLUME_INCLUDE empty — nothing to do"
  exit 0
fi

for vol in "${VOLUME_INCLUDE[@]}"; do
  if ! docker volume inspect "$vol" >/dev/null 2>&1; then
    warn "Volume not found: $vol"
    continue
  fi
  out="${dest}/${vol}.tar.gz"
  log "Exporting volume $vol"
  # alpine + tar inside a throwaway container; volume mounted at /volume
  # Prefer a locally available alpine tag (avoid registry pulls when offline/DNS broken)
  local_img="alpine:latest"
  if ! docker image inspect "$local_img" >/dev/null 2>&1; then
    local_img="alpine:3.20"
  fi
  docker run --rm \
    -v "${vol}:/volume:ro" \
    -v "${dest}:/backup" \
    "$local_img" \
    sh -c "cd /volume && tar -czf /backup/$(basename "$out") ."
  sha_manifest "$out"
  log "OK $out ($(du -h "$out" | cut -f1))"
done

# Bundle into one archive for easier offsite copy
bundle="$BACKUP_ROOT/volumes/volumes_${STAMP}.tar"
if compgen -G "${dest}/*.tar.gz" >/dev/null; then
  tar -cf "$bundle" -C "$BACKUP_ROOT/volumes" "${STAMP}"
  gzip -f "$bundle"
  maybe_encrypt "${bundle}.gz" >/dev/null
  log "Volume bundle: $(du -h "${bundle}.gz"* 2>/dev/null | head -3)"
fi

prune_old "$BACKUP_ROOT/volumes" "${VOLUME_KEEP_DAYS:-14}" 'volumes_*.tar.gz*'
# Remove unpacked stamp dirs older than retention
find "$BACKUP_ROOT/volumes" -mindepth 1 -maxdepth 1 -type d -mtime "+${VOLUME_KEEP_DAYS:-14}" -exec rm -rf {} + 2>/dev/null || true

log "Volume exports complete"
