#!/usr/bin/env bash
#
# mac-file-hygiene-apply.sh — apply an approved TSV. SECRET rows are never
# moved by this script (Bryan copies those to ~/.keys). Default is dry-run.
#
# Hermes on the Mac: read scripts/macbook/HERMES-HYGIENE.md first.
# Then:
#   bash scripts/macbook/mac-file-hygiene-apply.sh --plan ~/Desktop/mac-file-hygiene-plan-YYYYMMDD.tsv
#   bash scripts/macbook/mac-file-hygiene-apply.sh --plan ... --execute --batch home
#
# Batches: home | desktop | documents | downloads | movies | llc
# There is no secrets batch. Do not invent one.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_FILE="${SCRIPT_DIR}/hygiene-force-skip.txt"
HOME_DIR="${HOME}"
PLAN=""
WANT_EXECUTE=0
BATCH="all"

usage() {
  cat <<'EOF'
mac-file-hygiene-apply.sh — move non-secret rows from a hygiene TSV

  --plan FILE        TSV from mac-file-hygiene-plan.sh (required)
  --home DIR         folder the TSV paths are relative to (default: $HOME)
  --batch NAME       home|desktop|documents|downloads|movies|llc|all
  --execute          actually mv (default is dry-run)
  --help             this text

Never moves SECRET rows. Bryan copies those into ~/.keys, then runs
export-keys-to-vault.sh later. Force-skip names in hygiene-force-skip.txt
are treated as SKIP even if the TSV still says MOVE.

Dry-run first. One --batch per Hermes session. No rm. No overwrite.
EOF
}

in_batch() {
  local rel="$1"
  local dest="$2"
  case "${BATCH}" in
    all) return 0 ;;
    home) [[ "${rel}" != */* ]] ;;
    desktop) [[ "${rel}" == Desktop/* ]] ;;
    documents) [[ "${rel}" == Documents/* ]] ;;
    downloads) [[ "${rel}" == Downloads/* ]] ;;
    movies) [[ "${rel}" == Movies/* ]] ;;
    llc) [[ "${dest}" == Documents/llc/* ]] ;;
    secrets)
      echo "There is no secrets batch. Bryan moves SECRET rows to ~/.keys." >&2
      exit 2
      ;;
    *)
      echo "unknown --batch ${BATCH}" >&2
      exit 2
      ;;
  esac
}

force_skip() {
  local rel="$1"
  local name
  name="$(basename "${rel}")"
  [[ -f "${SKIP_FILE}" ]] || return 1
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    if [[ "${rel}" == "${line}" || "${name}" == "${line}" ]]; then
      return 0
    fi
  done < "${SKIP_FILE}"
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --plan)
      PLAN="${2:?--plan needs a file}"
      shift 2
      ;;
    --home)
      HOME_DIR="${2:?--home needs a path}"
      shift 2
      ;;
    --batch)
      BATCH="${2:?--batch needs a name}"
      shift 2
      ;;
    --execute)
      WANT_EXECUTE=1
      shift
      ;;
    *)
      echo "unknown flag: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "${PLAN}" ]] || { usage >&2; exit 2; }
[[ -f "${PLAN}" ]] || { echo "missing plan ${PLAN}" >&2; exit 2; }

if [[ "${BATCH}" == "secrets" ]]; then
  echo "There is no secrets batch. Bryan moves SECRET rows to ~/.keys." >&2
  exit 2
fi

mode="DRY-RUN"
[[ "${WANT_EXECUTE}" -eq 1 ]] && mode="EXECUTE"
echo "${mode} apply ${PLAN}  home=${HOME_DIR}  batch=${BATCH}"

moved=0
skipped=0
missing=0
exists=0

# Skip header. TSV is action, source, dest, reason.
while IFS=$'\t' read -r action source dest reason || [[ -n "${action}" ]]; do
  [[ "${action}" == "action" ]] && continue
  [[ -z "${action}" ]] && continue
  if [[ "${action}" == "SECRET" ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  if [[ "${action}" != "MOVE" ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  if force_skip "${source}"; then
    echo "FORCE-SKIP ${source}"
    skipped=$((skipped + 1))
    continue
  fi
  if ! in_batch "${source}" "${dest}"; then
    continue
  fi
  src_path="${HOME_DIR}/${source}"
  dest_path="${HOME_DIR}/${dest}"
  if [[ ! -e "${src_path}" ]]; then
    echo "MISSING ${source}"
    missing=$((missing + 1))
    continue
  fi
  if [[ -e "${dest_path}" ]]; then
    echo "EXISTS ${dest} (will not overwrite)"
    exists=$((exists + 1))
    continue
  fi
  if [[ "${WANT_EXECUTE}" -eq 0 ]]; then
    echo "would MOVE ${source} -> ${dest}"
    moved=$((moved + 1))
    continue
  fi
  mkdir -p "$(dirname "${dest_path}")"
  mv -n "${src_path}" "${dest_path}"
  echo "MOVED ${source} -> ${dest}"
  moved=$((moved + 1))
done < "${PLAN}"

echo
echo "${mode} counts: moved_or_would=${moved} force_or_skip=${skipped} missing=${missing} exists=${exists}"
echo "SECRET rows were ignored. Bryan handles ~/.keys, then Vault later."
