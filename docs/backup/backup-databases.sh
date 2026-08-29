#!/usr/bin/env bash
# Logical PostgreSQL dumps from running containers (safer than copying pgdata).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config
need_cmd docker

log "=== Database dumps ==="
mkdir -p "$BACKUP_ROOT/databases/${STAMP}"
ok=0
fail=0

for entry in "${POSTGRES_DUMPS[@]:-}"; do
  [[ -z "$entry" ]] && continue
  IFS=':' read -r container user db <<<"$entry"
  outfile="$BACKUP_ROOT/databases/${STAMP}/${container}_${db}.sql.gz"
  if ! docker ps --format '{{.Names}}' | grep -qx "$container"; then
    warn "Skip $container (not running)"
    continue
  fi
  log "Dumping $container / $db as $user"
  if docker exec "$container" pg_dump -U "$user" -d "$db" --no-owner --no-acl \
      | gzip -c > "$outfile"; then
    size="$(du -h "$outfile" | cut -f1)"
    log "OK $outfile ($size)"
    sha_manifest "$outfile"
    ok=$((ok + 1))
  else
    warn "FAILED dump for $container"
    rm -f "$outfile"
    fail=$((fail + 1))
  fi
done

# n8n uses sqlite on a bind mount — copy the live DB with sqlite .backup if possible
if docker ps --format '{{.Names}}' | grep -qx n8n; then
  n8n_db="$DOCKER_ROOT/n8n/data/database.sqlite"
  if [[ -f "$n8n_db" ]]; then
    out="$BACKUP_ROOT/databases/${STAMP}/n8n_database.sqlite"
    log "Snapshotting n8n sqlite"
    if docker exec n8n sh -c 'command -v sqlite3 >/dev/null && sqlite3 /home/node/.n8n/database.sqlite ".backup /tmp/n8n-backup.sqlite"' 2>/dev/null; then
      docker cp n8n:/tmp/n8n-backup.sqlite "$out"
      docker exec n8n rm -f /tmp/n8n-backup.sqlite || true
    else
      # Fallback: consistent-enough copy while container is up
      cp -a "$n8n_db" "$out"
    fi
    gzip -f "$out"
    sha_manifest "${out}.gz"
    ok=$((ok + 1))
  fi
fi

# Vaultwarden: sqlite + attachments live under bind mount; dump sqlite if present
vw_db="$DOCKER_ROOT/vaultwarden/db.sqlite3"
if [[ -f "$vw_db" ]]; then
  out="$BACKUP_ROOT/databases/${STAMP}/vaultwarden_db.sqlite3"
  log "Snapshotting vaultwarden sqlite"
  if docker ps --format '{{.Names}}' | grep -qx vaultwarden \
     && docker exec vaultwarden sh -c 'command -v sqlite3 >/dev/null' 2>/dev/null; then
    docker exec vaultwarden sqlite3 /data/db.sqlite3 ".backup /tmp/vw-backup.sqlite3"
    docker cp vaultwarden:/tmp/vw-backup.sqlite3 "$out"
    docker exec vaultwarden rm -f /tmp/vw-backup.sqlite3 || true
  else
    cp -a "$vw_db" "$out"
  fi
  gzip -f "$out"
  sha_manifest "${out}.gz"
  ok=$((ok + 1))
fi

log "Database dumps done: ok=$ok fail=$fail"
[[ "$fail" -eq 0 ]]
