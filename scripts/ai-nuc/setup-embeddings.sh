#!/usr/bin/env bash
#
# setup-embeddings.sh — Set up the ingest-folder embedding pipeline on the AI-NUC.
#
# Run ON THE AI-NUC, as your normal user (no sudo — nothing here needs root):
#     bash setup-embeddings.sh
#
# Idempotent: safe to re-run after pulling script updates from the repo.
#
# What this installs:
#   - a Python venv at ~/ai/venv with sqlite-vec, pypdf, python-docx, requests
#   - the nomic-embed-text model in Ollama (~274MB, 768-dim embeddings)
#   - embed_lib.py / embed-file.py / embed-query.py into ~/ai/scripts/
#
# After this, index-ingest.sh's embed step activates automatically (it checks
# for ~/ai/venv/bin/python + ~/ai/scripts/embed-file.py before calling them),
# and you can search everything already embedded with:
#   ~/ai/venv/bin/python ~/ai/scripts/embed-query.py "your question here"

set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run this as your normal user, not root/sudo"

VENV="$HOME/ai/venv"
SCRIPTS_DIR="$HOME/ai/scripts"
EMBED_MODEL="${EMBED_MODEL:-nomic-embed-text}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"

command -v ollama >/dev/null || die "ollama not found on PATH"
command -v python3 >/dev/null || die "python3 not found on PATH"

# ------------------------------------------------------------------ venv ----
if [[ ! -x "$VENV/bin/python" ]]; then
  log "Creating venv at $VENV"
  python3 -m venv "$VENV"
else
  log "venv already exists at $VENV"
fi

log "Installing/upgrading embedding pipeline dependencies"
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet sqlite-vec pypdf python-docx requests

# --------------------------------------------------------------- ollama ----
if ollama list 2>/dev/null | awk '{print $1}' | grep -qE "^${EMBED_MODEL}(:latest)?$"; then
  log "Ollama model $EMBED_MODEL already pulled"
else
  log "Pulling Ollama model $EMBED_MODEL (~274MB)"
  ollama pull "$EMBED_MODEL"
fi

# --------------------------------------------------------------- scripts ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$SCRIPTS_DIR"
for f in embed_lib.py embed-file.py embed-query.py; do
  [[ -f "$SRC_DIR/$f" ]] || die "missing $f next to this script — copy the whole scripts/ai-nuc/ directory over"
  install -m 0755 "$SRC_DIR/$f" "$SCRIPTS_DIR/$f"
done
log "Installed embedding scripts into $SCRIPTS_DIR/"

# ------------------------------------------------------------ smoke test ---
log "Verifying: embedding a test string end to end"
if "$VENV/bin/python" - <<'PYEOF'
import sys
sys.path.insert(0, __import__("os").path.expanduser("~/ai/scripts"))
import embed_lib
vec = embed_lib.embed_texts(["setup-embeddings.sh smoke test"])[0]
assert len(vec) == embed_lib.EMBED_DIM, f"expected {embed_lib.EMBED_DIM} dims, got {len(vec)}"
print(f"  embedded 1 string -> {len(vec)}-dim vector via {embed_lib.EMBED_MODEL} at {embed_lib.OLLAMA_URL}")
PYEOF
then
  log "Embedding pipeline is working."
else
  die "smoke test failed — check Ollama is running: curl $OLLAMA_URL/api/tags"
fi

echo
log "Done. Drop a .txt/.md/.pdf/.docx into ~/ingest/inbox/ and it will be indexed AND embedded automatically."
log "Search what's already there with: $VENV/bin/python $SCRIPTS_DIR/embed-query.py \"your question\""
