#!/usr/bin/env bash
# Shared helpers for VPS backup scripts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

load_config() {
  local conf="${BACKUP_CONF:-}"
  if [[ -z "$conf" ]]; then
    if [[ -f "$SCRIPT_DIR/backup.conf" ]]; then
      conf="$SCRIPT_DIR/backup.conf"
    elif [[ -f "${HOME}/.config/vps-backup.conf" ]]; then
      conf="${HOME}/.config/vps-backup.conf"
    else
      conf="$SCRIPT_DIR/backup.conf.example"
    fi
  fi
  # shellcheck disable=SC1090
  source "$conf"
  BACKUP_ROOT="${BACKUP_ROOT:-/home/bryanwi09/docker/backups}"
  DOCKER_ROOT="${DOCKER_ROOT:-/home/bryanwi09/docker}"
  STAMP="${STAMP:-$(date +%Y%m%d_%H%M%S)}"
  mkdir -p \
    "$BACKUP_ROOT/daily" \
    "$BACKUP_ROOT/weekly" \
    "$BACKUP_ROOT/hermes" \
    "$BACKUP_ROOT/websites" \
    "$BACKUP_ROOT/volumes" \
    "$BACKUP_ROOT/databases" \
    "$BACKUP_ROOT/manifests" \
    "$BACKUP_ROOT/logs"
  LOG_FILE="${LOG_FILE:-$BACKUP_ROOT/logs/backup-${STAMP}.log}"
}

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" | tee -a "$LOG_FILE" >&2; }
die()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# Prefer pigz when available for faster compression
tar_cz() {
  local dest="$1"; shift
  if command -v pigz >/dev/null 2>&1; then
    tar -I 'pigz -1' -cf "$dest" "$@"
  else
    tar -czf "$dest" "$@"
  fi
}

sha_manifest() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" >> "$BACKUP_ROOT/manifests/checksums-${STAMP}.txt"
  fi
}

maybe_encrypt() {
  local src="$1"
  if [[ -n "${GPG_RECIPIENT:-}" ]]; then
    need_cmd gpg
    log "Encrypting $(basename "$src") for $GPG_RECIPIENT"
    gpg --batch --yes --encrypt --recipient "$GPG_RECIPIENT" --output "${src}.gpg" "$src"
    sha_manifest "${src}.gpg"
    rm -f "$src"
    echo "${src}.gpg"
  else
    sha_manifest "$src"
    echo "$src"
  fi
}

prune_old() {
  local dir="$1" days="$2" pattern="$3"
  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime "+${days}" -print -delete \
    | while read -r f; do log "Pruned old backup: $f"; done || true
}

write_inventory() {
  local out="$BACKUP_ROOT/manifests/inventory-${STAMP}.txt"
  {
    echo "# VPS backup inventory ${STAMP}"
    echo "# host: $(hostname -f 2>/dev/null || hostname)"
    echo "# generated: $(date -Is)"
    echo
    echo "## docker ps"
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null || true
    echo
    echo "## docker volumes (named)"
    docker volume ls --format '{{.Name}}' 2>/dev/null || true
    echo
    echo "## bind mounts for running containers"
    docker ps -q | while read -r id; do
      name="$(docker inspect -f '{{.Name}}' "$id" | sed 's#^/##')"
      echo "### $name"
      docker inspect -f '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{println}}{{end}}' "$id"
    done 2>/dev/null || true
    echo
    echo "## disk"
    df -h / /home /var 2>/dev/null || df -h
  } > "$out"
  log "Wrote inventory: $out"
}
