#!/usr/bin/env bash
#
# index-ingest.sh — Called by ingest-watcher.sh with a batch file of changed paths.
#
#   index-ingest.sh /path/to/batch-YYYYmmddTHHMMSS-PID.txt
#
# Each line of the batch file is "EVENT|/absolute/path".
#
# What this does: builds a durable, append-only manifest (JSONL) of every
# file that lands in the ingest folder (sha256, size, MIME type), embeds
# extractable text (.txt/.md/.pdf/.docx/...) into a local sqlite-vec store via
# embed-file.py so it becomes semantically searchable with embed-query.py, and
# optionally moves catalogued files into ingest/processed/.
#
# See docs/infrastructure/ai-nuc-smb-mount.md §10 for what this pipeline is
# for, its limits, and the migration path to a heavier store later.

set -uo pipefail

BATCH="${1:?usage: index-ingest.sh <batch-file>}"
INGEST_DIR="${INGEST_DIR:-$HOME/ingest}"
MANIFEST="${MANIFEST:-$HOME/ai/ingest-manifest.jsonl}"
PROCESSED="$INGEST_DIR/processed"
FAILED="$INGEST_DIR/failed"
MOVE_AFTER_INDEX="${MOVE_AFTER_INDEX:-0}"   # 1 = relocate originals into processed/
EMBED_PY="${EMBED_PY:-$HOME/ai/venv/bin/python}"
EMBED_SCRIPT="${EMBED_SCRIPT:-$HOME/ai/scripts/embed-file.py}"
EMBED_LOG="${EMBED_LOG:-$HOME/ai/logs/embed.log}"

mkdir -p "$(dirname "$MANIFEST")" "$(dirname "$EMBED_LOG")" "$PROCESSED" "$FAILED"

embed_available=0
[[ -x "$EMBED_PY" && -f "$EMBED_SCRIPT" ]] && embed_available=1

ts() { date -Is; }
say() { printf '%s [index] %s\n' "$(ts)" "$*"; }

json_escape() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

indexed=0 removed=0 skipped=0

while IFS='|' read -r event path; do
  [[ -n "${path:-}" ]] || continue

  # Deletions: record the tombstone and drop any embedded chunks so search
  # results don't outlive the file.
  if [[ "$event" == *DELETE* || "$event" == *MOVED_FROM* ]]; then
    printf '{"ts":%s,"event":"delete","path":%s}\n' \
      "$(json_escape "$(ts)")" "$(json_escape "$path")" >> "$MANIFEST"
    if (( embed_available )); then
      "$EMBED_PY" "$EMBED_SCRIPT" delete "$path" >> "$EMBED_LOG" 2>&1 || true
    fi
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

  # ---------------------------------------------------------------- embed ---
  # Extracts text (.txt/.md/.pdf/.docx/...), chunks it, embeds each chunk with
  # nomic-embed-text via Ollama, and stores the vectors in
  # ~/ai/embeddings.sqlite3 (sqlite-vec). Files it doesn't know how to read
  # (images, archives, unrecognised binaries) are skipped for embedding but
  # still get a manifest entry above — the manifest is the record of what
  # arrived, embedding is what makes the text of it searchable.
  embed_status='"not_attempted"'
  if (( embed_available )); then
    embed_json="$("$EMBED_PY" "$EMBED_SCRIPT" upsert "$path" "$rel" "$sha" "$mime" 2>>"$EMBED_LOG")"
    if [[ -n "$embed_json" ]]; then
      embed_status="$embed_json"
    else
      embed_status='{"status":"error","reason":"embed-file.py produced no output"}'
    fi
  fi

  printf '{"ts":%s,"event":"upsert","path":%s,"rel":%s,"sha256":%s,"bytes":%s,"mime":%s,"embed":%s}\n' \
    "$(json_escape "$(ts)")" "$(json_escape "$path")" "$(json_escape "$rel")" \
    "$(json_escape "$sha")" "$size" "$(json_escape "$mime")" "$embed_status" >> "$MANIFEST"
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
