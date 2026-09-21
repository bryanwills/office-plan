#!/usr/bin/env bash
#
# mac-file-inventory.sh — read-only Mac home map for the hygiene project.
# Does not move, rename, or delete anything.
#
#   bash scripts/macbook/mac-file-inventory.sh
#   bash scripts/macbook/mac-file-inventory.sh --out ~/Desktop/mac-file-inventory.txt
#
# Wait until Time Machine says the current backup is finished before you
# let Hermes (or anyone) move files. This script is safe during a backup.
#
set -euo pipefail

HOME_DIR="${HOME}"
OUT=""

usage() {
  cat <<'EOF'
mac-file-inventory.sh — read-only map of a Mac home folder

  --home DIR     folder to scan (default: $HOME)
  --out FILE     write the report here (default: Desktop or /tmp)
  --help         this text

Always read-only. Skips Library, Trash, Time Machine locals, and
hidden top-level dirs. Upload the report to Open WebUI Knowledge.
Do not point an Open WebUI filesystem tool at this Mac. Hermes on
the Mac is the agent that may later move files, after Time Machine
finishes and after you approve a plan.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --home)
      HOME_DIR="${2:?--home needs a path}"
      shift 2
      ;;
    --out)
      OUT="${2:?--out needs a path}"
      shift 2
      ;;
    *)
      echo "unknown flag: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${OUT}" ]]; then
  if [[ -d "${HOME}/Desktop" ]]; then
    OUT="${HOME}/Desktop/mac-file-inventory-$(date +%Y%m%d).txt"
  else
    OUT="/tmp/mac-file-inventory-$(date +%Y%m%d).txt"
  fi
fi

echo "read-only inventory of ${HOME_DIR} -> ${OUT}"

{
  echo "# Mac file inventory (read-only)"
  echo "home: ${HOME_DIR}"
  echo "when: $(date -Iseconds 2>/dev/null || date)"
  echo "host: $(hostname)"
  echo
  echo "## Top-level sizes"
  if command -v du >/dev/null 2>&1; then
    du -sh "${HOME_DIR}"/* 2>/dev/null | sort -h || true
  fi
  echo
  echo "## Immediate children (why the top-level list looks empty)"
  echo "Hidden folders (dotfiles) are not listed. Files live *inside*"
  echo "Desktop/Documents/Downloads, not as extra top-level names."
  echo
  for dir in Desktop Documents Downloads Pictures Movies Music Public; do
    target="${HOME_DIR}/${dir}"
    if [[ ! -d "${target}" ]]; then
      echo "${dir}: missing"
      continue
    fi
    set +o pipefail
    count="$(find "${target}" -xdev -type f 2>/dev/null | head -n 5001 | wc -l | tr -d ' ')"
    kids="$(find "${target}" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
    set -o pipefail
    echo "${dir}: ${kids} immediate items, ${count} files under it (count stops at 5001)"
    find "${target}" -mindepth 1 -maxdepth 1 -printf '    %y %f\n' 2>/dev/null \
      | head -n 40 || ls -1 "${target}" 2>/dev/null | head -n 40 | sed 's/^/    /'
    echo "  largest (depth 2):"
    du -h -d 2 "${target}" 2>/dev/null | sort -h | tail -n 8 | sed 's/^/    /' || true
    echo
  done
  echo "## SKIP (do not let an agent rewrite these)"
  echo "- ${HOME_DIR}/Library"
  echo "- ${HOME_DIR}/.Trash and hidden top-level dirs"
  echo "- Time Machine locals / Backups.backupdb"
  echo "- Photos Library.photoslibrary internals"
  echo "- ~/.ollama ~/.hermes ~/.open-webui"
  echo
  echo "Next: wait for Time Machine to finish, import Claude export into"
  echo "Open WebUI Knowledge, plan in chat, then Hermes on the Mac with"
  echo "confirmations. See docs/infrastructure/mac-file-hygiene.md"
} > "${OUT}"

echo "Wrote ${OUT}"
