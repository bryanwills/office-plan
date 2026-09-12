#!/usr/bin/env bash
#
# index-ingest.sh — Called by ingest-watcher.sh with a batch file of changed paths.
#
#   index-ingest.sh /path/to/batch-YYYYmmddTHHMMSS-PID.txt
#
# Each line of the batch file is "EVENT|/absolute/path".
#
# What this does today: builds a durable, append-only manifest (JSONL) of every
# file that lands in the ingest folder, with sha256, size, and MIME type, and
# moves successfully catalogued files into ingest/processed/.
#
# What you wire up next: the EMBED HOOK section below. That is where your local
# Ollama / Open WebUI knowledge collection ingestion goes. It is deliberately a
# stub — see docs/infrastructure/ai-nuc-smb-mount.md for the two options.

set -uo pipefail

BATCH="${1:?usage: index-ingest.sh <batch-file>}"
INGEST_DIR="${INGEST_DIR:-$HOME/ingest}"
MANIFEST="${MANIFEST:-$HOME/ai/ingest-manifest.jsonl}"
PROCESSED="$INGEST_DIR/processed"
FAILED="$INGEST_DIR/failed"
MOVE_AFTER_INDEX="${MOVE_AFTER_INDEX:-0}"   # 1 = relocate originals into processed/

mkdir -p "$(dirname "$MANIFEST")" "$PROCESSED" "$FAILED"

ts() { date -Is; }
say() { printf '%s [index] %s\n' "$(ts)" "$*"; }

json_escape() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

indexed=0 removed=0 skipped=0

while IFS='|' read -r event path; do
  [[ -n "${path:-}" ]] || continue

  # Deletions: record the tombstone so the index can prune.
  if [[ "$event" == *DELETE* || "$event" == *MOVED_FROM* ]]; then
    printf '{"ts":%s,"event":"delete","path":%s}\n' \
      "$(json_escape "$(ts)")" "$(json_escape "$path")" >> "$MANIFEST"
    ((removed++))
    continue
  fi

  # Directories and vanished files are not indexable.
  [[ -f "$path" ]] || { ((skipped++)); continue; }

  size=$(stat -c '%s' "$path" 2>/dev/null || echo 0)
  if (( size == 0 )); then ((skipped++)); continue; fi

  sha=$(sha256sum "$path" | awk '{print $1}')
  mime=$(file -b --mime-type "$path" 2>/dev/null || echo application/octet-stream)
  rel="${path#$INGEST_DIR/}"

  # ------------------------------------------------------------------------
  # EMBED HOOK — replace this block to push the file into your RAG store.
  #
  # Option A (Open WebUI knowledge collection):
  #   curl -sf -X POST "http://127.0.0.1:3000/api/v1/files/" \
  #        -H "Authorization: Bearer $OPENWEBUI_API_KEY" \
  #        -F "file=@${path}" || { echo "$path" >> "$FAILED/.log"; continue; }
  #
  # Option B (direct Ollama embeddings into your own vector store):
  #   curl -sf http://127.0.0.1:11434/api/embed \
  #        -d "{\"model\":\"nomic-embed-text\",\"input\":$(json_escape "$(head -c 8000 "$path")")}"
  #
  # Until one of these is enabled, the manifest below IS the index: an agent on
  # the NUC can tail it to learn what changed and act accordingly.
  # ------------------------------------------------------------------------

  printf '{"ts":%s,"event":"upsert","path":%s,"rel":%s,"sha256":%s,"bytes":%s,"mime":%s}\n' \
    "$(json_escape "$(ts)")" "$(json_escape "$path")" "$(json_escape "$rel")" \
    "$(json_escape "$sha")" "$size" "$(json_escape "$mime")" >> "$MANIFEST"
  ((indexed++))

  if [[ "$MOVE_AFTER_INDEX" == "1" ]]; then
    dest="$PROCESSED/$(date +%Y-%m-%d)"
    mkdir -p "$dest"
    mv -n "$path" "$dest/" 2>/dev/null || true
  fi
done < "$BATCH"

say "batch $(basename "$BATCH"): indexed=$indexed deleted=$removed skipped=$skipped"

# Keep the batch spool from growing unbounded; successful batches are disposable
# because the manifest is the durable record.
rm -f "$BATCH"
