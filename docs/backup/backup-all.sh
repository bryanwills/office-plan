#!/usr/bin/env bash
# Orchestrate a full (or partial) backup run.
#
# Usage:
#   ./backup-all.sh                 # daily: dbs + websites + docker-data + hermes + sync
#   ./backup-all.sh --weekly        # includes named volumes + fuller docker tree
#   ./backup-all.sh --quick         # databases + websites + hermes only
#   ./backup-all.sh --no-sync       # skip offsite push
#   ./backup-all.sh --sync-only     # only run sync-offsite.sh
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WEEKLY=0
QUICK=0
DO_SYNC=1
SYNC_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --weekly) WEEKLY=1 ;;
    --quick) QUICK=1 ;;
    --no-sync) DO_SYNC=0 ;;
    --sync-only) SYNC_ONLY=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) die "Unknown arg: $arg" ;;
  esac
done

load_config
need_cmd docker
need_cmd tar
need_cmd gzip

START_EPOCH=$(date +%s)
log "========== backup-all start (weekly=$WEEKLY quick=$QUICK) =========="
log "Free disk before: $(df -h "$BACKUP_ROOT" | awk 'NR==2{print $4" available on "$1}')"

if [[ "$SYNC_ONLY" -eq 1 ]]; then
  "$SCRIPT_DIR/sync-offsite.sh"
  exit 0
fi

failures=0
run_step() {
  local name="$1"; shift
  log "---- $name ----"
  if "$@"; then
    log "OK: $name"
  else
    warn "FAILED: $name"
    failures=$((failures + 1))
  fi
}

run_step "databases" "$SCRIPT_DIR/backup-databases.sh"
run_step "websites"  "$SCRIPT_DIR/backup-websites.sh"
run_step "hermes"    "$SCRIPT_DIR/backup-hermes.sh"

if [[ "$QUICK" -eq 0 ]]; then
  if [[ "$WEEKLY" -eq 1 ]]; then
    run_step "docker-data weekly" "$SCRIPT_DIR/backup-docker-data.sh" weekly
    run_step "volumes"            "$SCRIPT_DIR/backup-volumes.sh"
  else
    run_step "docker-data daily"  "$SCRIPT_DIR/backup-docker-data.sh" daily
  fi
fi

if [[ "$DO_SYNC" -eq 1 ]]; then
  run_step "offsite sync" "$SCRIPT_DIR/sync-offsite.sh"
fi

elapsed=$(( $(date +%s) - START_EPOCH ))
log "========== backup-all finished in ${elapsed}s (failures=$failures) =========="
log "Artifacts under: $BACKUP_ROOT"
log "Restore help: $SCRIPT_DIR/restore-hints.sh"

[[ "$failures" -eq 0 ]]
