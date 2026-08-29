#!/usr/bin/env bash
# Archive website docroots under /var/www
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config
need_cmd tar

log "=== Website backups ==="
dest_dir="$BACKUP_ROOT/websites"
mkdir -p "$dest_dir"

for site in "${WEB_SITES[@]:-}"; do
  [[ -z "$site" ]] && continue
  if [[ ! -d "$site" ]]; then
    warn "Missing site path: $site"
    continue
  fi
  name="$(basename "$site")"
  archive="${dest_dir}/${name}_${STAMP}.tar.gz"
  log "Archiving $site -> $archive"
  # Parent must be readable; may need sudo for some ownerships
  if [[ -r "$site" ]]; then
    tar_cz "$archive" -C "$(dirname "$site")" "$(basename "$site")"
  else
    need_cmd sudo
    if command -v pigz >/dev/null 2>&1; then
      sudo tar -I 'pigz -1' -cf "$archive" -C "$(dirname "$site")" "$(basename "$site")"
    else
      sudo tar -czf "$archive" -C "$(dirname "$site")" "$(basename "$site")"
    fi
    sudo chown "$(id -u):$(id -g)" "$archive"
  fi
  maybe_encrypt "$archive" >/dev/null
  log "Site $name size: $(du -h "${archive}" "${archive}.gpg" 2>/dev/null | awk '{print $1,$2}')"
done

prune_old "$dest_dir" "${DAILY_KEEP_DAYS:-14}" '*_????????_??????.tar.gz*'
log "Website backups complete"
