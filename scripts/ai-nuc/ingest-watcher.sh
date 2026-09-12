#!/usr/bin/env bash
#
# ingest-watcher.sh — Watch the SMB ingest folder and hand batches of changed
# files to the indexer. Runs as a systemd --user service on the AI-NUC.
#
# Why batching: a single Finder copy over SMB produces dozens of inotify events
# (temp file, rename, xattr writes). We coalesce everything that happens within
# DEBOUNCE seconds of quiet into one indexer invocation.

set -uo pipefail

INGEST_DIR="${INGEST_DIR:-$HOME/ingest}"
WATCH_DIR="$INGEST_DIR/inbox"
INDEXER="${INDEXER:-$HOME/ai/scripts/index-ingest.sh}"
LOG_DIR="${LOG_DIR:-$HOME/ai/logs}"
LOG="$LOG_DIR/ingest-watcher.log"
BATCH_DIR="${BATCH_DIR:-$HOME/ai/batches}"
DEBOUNCE="${DEBOUNCE:-4}"

mkdir -p "$WATCH_DIR" "$LOG_DIR" "$BATCH_DIR"

log() { printf '%s %s\n' "$(date -Is)" "$*" >> "$LOG"; }

# Files macOS/SMB create as scaffolding that must never reach the indexer.
NOISE_RE='(/\.DS_Store$|/\._[^/]*$|/\.smbdelete|/\.TemporaryItems/|/\.Spotlight-V100/|/\.Trashes/|/\.fseventsd/|/\.DocumentRevisions|~$|\.part$|\.crdownload$|\.tmp$|/\.#)'

command -v inotifywait >/dev/null || { log "FATAL: inotifywait not found"; exit 1; }

log "watcher starting; watching $WATCH_DIR (debounce ${DEBOUNCE}s, indexer $INDEXER)"

pending=()

flush() {
  ((${#pending[@]})) || return 0
  local batch
  batch="$BATCH_DIR/batch-$(date +%Y%m%dT%H%M%S)-$$.txt"
  printf '%s\n' "${pending[@]}" | sort -u > "$batch"
  local n
  n=$(wc -l < "$batch" | tr -d ' ')
  log "flushing $n path(s) -> $batch"
  pending=()
  if [[ -x "$INDEXER" ]]; then
    if "$INDEXER" "$batch" >> "$LOG" 2>&1; then
      log "indexer OK for $batch"
    else
      log "ERROR: indexer exited $? for $batch (batch file retained)"
    fi
  else
    log "ERROR: indexer $INDEXER is missing or not executable; batch retained at $batch"
  fi
}

# --format gives us "EVENT|/full/path". -m monitor, -r recursive, -q quiet.
while true; do
  if IFS= read -r -t "$DEBOUNCE" line; then
    event="${line%%|*}"
    path="${line#*|}"
    [[ -n "$path" ]] || continue
    if [[ "$path" =~ $NOISE_RE ]]; then
      continue
    fi
    pending+=("$event|$path")
  else
    rc=$?
    if (( rc > 128 )); then
      # read timed out -> the directory has been quiet for DEBOUNCE seconds
      flush
    else
      # EOF: inotifywait died. Flush what we have and let systemd restart us.
      log "inotifywait stream closed (rc=$rc); flushing and exiting for restart"
      flush
      exit 1
    fi
  fi
done < <(
  inotifywait -m -r -q \
    -e close_write -e moved_to -e moved_from -e delete -e create \
    --format '%e|%w%f' \
    "$WATCH_DIR"
)
