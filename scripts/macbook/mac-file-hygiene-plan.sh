#!/usr/bin/env bash
#
# mac-file-hygiene-plan.sh — DRY-RUN only. Prints proposed moves. Never mv.
#
# Scans the whole user folder (immediate children, plus one level inside
# Desktop/Documents/Downloads/Pictures/Movies/Public). Secrets go to
# ~/.keys/ for the existing Hashicorp export script. Everything else that
# is allowed to move goes to Documents/inbox/... Tax/W-2 style files go
# to Documents/llc/records. Dotfiles, Library, Applications, git trees,
# Photos libraries, iCloud MacBook copies, and installer junk are SKIP.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_FILE="${SCRIPT_DIR}/hygiene-force-skip.txt"
HOME_DIR="${HOME}"
OUT=""
WANT_EXECUTE=0
KEYS_REL=".keys"

usage() {
  cat <<'EOF'
mac-file-hygiene-plan.sh — dry-run of proposed user-folder moves

  --home DIR     folder to scan (default: $HOME)
  --out FILE     write the TSV plan here (default: Desktop or /tmp)
  --help         this text

Always a dry-run. Does not move, rename, or delete.

Covers the whole user folder (home-root files plus one level inside
Desktop/Documents/Downloads/Pictures/Movies/Public).

  SECRET  → ~/.keys/<name>     (rui.key, ssh.txt, nsec, keys.bryanwills.dev,
                                Claude config backups, *.pem / *.token, …)
  MOVE    → Documents/inbox/…  or Documents/llc/records for tax/W-2/contracts
  SKIP    → dotfiles, ~/Library, Applications, git repos, Photos libraries,
            iCloud "*MacBook*" copies, Photo Booth, Movies/TV, Resolve,
            CyberLink, CacheClip, Public/Drop Box, __MACOSX, dmg/pkg/zip/exe

--execute is rejected here. Hermes applies MOVE rows with
mac-file-hygiene-apply.sh after Bryan copies SECRET files to ~/.keys.
See scripts/macbook/HERMES-HYGIENE.md.
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

if [[ "${WANT_EXECUTE}" -eq 1 ]]; then
  echo "Refusing --execute. This script is dry-run only." >&2
  echo "Review the TSV, then move one approved folder with Hermes." >&2
  exit 2
fi

if [[ -z "${OUT}" ]]; then
  if [[ -d "${HOME}/Desktop" ]]; then
    OUT="${HOME}/Desktop/mac-file-hygiene-plan-$(date +%Y%m%d).tsv"
  else
    OUT="/tmp/mac-file-hygiene-plan-$(date +%Y%m%d).tsv"
  fi
fi

lc() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

is_user_folder() {
  case "$1" in
    Desktop|Documents|Downloads|Pictures|Movies|Public) return 0 ;;
  esac
  return 1
}

is_dot_or_system_top() {
  local name="$1"
  case "${name}" in
    .*|Library|Applications) return 0 ;;
  esac
  return 1
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

is_keep_in_place() {
  local name="$1"
  case "${name}" in
    bin|scripts|export-keys-to-vault.sh) return 0 ;;
  esac
  force_skip "${name}"
}

is_git_root() {
  [[ -d "$1/.git" ]]
}

is_icloud_copy() {
  local n
  n="$(lc "$1")"
  case "${n}" in
    *'macbook pro'*|desktop\ -\ *|documents\ -\ *) return 0 ;;
  esac
  return 1
}

is_software_or_library() {
  local name="$1"
  case "${name}" in
    "Photo Booth Library"|TV|"Resolve Project Backups"|CyberLink|CacheClip|"Drop Box"|thinkorswim|node_modules) return 0 ;;
  esac
  case "$(lc "${name}")" in
    *photoslibrary|*.app) return 0 ;;
  esac
  [[ "${name}" == *.app || "${name}" == *.photoslibrary ]]
}

is_installer_junk() {
  local name="$1"
  case "${name}" in
    __MACOSX) return 0 ;;
  esac
  case "$(lc "${name}")" in
    *.dmg|*.pkg|*.exe|*.iso|*.zip|*.deb|*.rpm) return 0 ;;
  esac
  return 1
}

is_secret_name() {
  local name="$1"
  local n
  n="$(lc "${name}")"
  case "${n}" in
    *.key|*.pem|*.p12|*.pfx|*.p8|*.crt|*.ppk) return 0 ;;
    id_rsa|id_ed25519|*.env) return 0 ;;
    ssh.txt|*.ssh.txt) return 0 ;;
    keys.bryanwills.dev|*.bryanwills.dev) return 0 ;;
    *nsec*|*githubtoken*|*oauth*|*client_secret*) return 0 ;;
    *secret*|*passwd*|*credential*) return 0 ;;
    *password*)
      case "${n}" in
        *passwordsafe*) return 1 ;;
      esac
      return 0
      ;;
    claude*config*|claude-config-backup*|claude-config-backup*.zip) return 0 ;;
  esac
  case "${n}" in
    *.env.example) return 1 ;;
  esac
  return 1
}

is_tax_or_record() {
  local n
  n="$(lc "$1")"
  case "${n}" in
    *w2*|*w-2*|*1099*|*1095*|*taxreturn*|*tax_return*|*tax-return*) return 0 ;;
    *tax*return*|taxes*|tax[0-9]*|*billing*statement*|*contract-copy*|*contract_copy*) return 0 ;;
  esac
  return 1
}

already_organized() {
  local rel="$1"
  case "${rel}" in
    Documents/inbox|Documents/inbox/*|Documents/llc|Documents/llc/*|Documents/personal|Documents/personal/*|Documents/archive|Documents/archive/*|Pictures/inbox|Pictures/inbox/*|"${KEYS_REL}"|"${KEYS_REL}"/*)
      return 0
      ;;
  esac
  return 1
}

inbox_dest() {
  local rel="$1"
  local top="${rel%%/*}"
  if [[ "${rel}" == "${top}" ]]; then
    echo "Documents/inbox/home/${rel}"
    return
  fi
  case "${top}" in
    Desktop) echo "Documents/inbox/desktop/${rel#Desktop/}" ;;
    Downloads) echo "Documents/inbox/downloads/${rel#Downloads/}" ;;
    Pictures) echo "Pictures/inbox/${rel#Pictures/}" ;;
    Movies) echo "Documents/inbox/movies/${rel#Movies/}" ;;
    Public) echo "Documents/inbox/public/${rel#Public/}" ;;
    Documents) echo "Documents/inbox/documents/${rel#Documents/}" ;;
    *) echo "Documents/inbox/home/${rel}" ;;
  esac
}

emit() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
}

classify() {
  local path="$1"
  local rel="$2"
  local name
  name="$(basename "${path}")"

  if is_dot_or_system_top "${name}"; then
    emit SKIP "${rel}" "" "dotfile, Library, or Applications"
    return
  fi
  if is_keep_in_place "${name}" || force_skip "${rel}"; then
    emit SKIP "${rel}" "" "tooling / vault export script stays"
    return
  fi
  if is_icloud_copy "${name}"; then
    emit SKIP "${rel}" "" "iCloud or old-Mac copy"
    return
  fi
  if is_secret_name "${name}"; then
    emit SECRET "${rel}" "${KEYS_REL}/${name}" "secret-like; stage in ~/.keys for Vault export"
    return
  fi
  if is_software_or_library "${name}"; then
    emit SKIP "${rel}" "" "app data, Photos, or software folder"
    return
  fi
  if is_installer_junk "${name}"; then
    emit SKIP "${rel}" "" "installer, zip, or __MACOSX junk"
    return
  fi
  if is_git_root "${path}"; then
    emit SKIP "${rel}" "" "git working tree stays put"
    return
  fi
  if already_organized "${rel}"; then
    emit SKIP "${rel}" "" "already on the hygiene spine or in .keys"
    return
  fi
  if [[ "${rel}" == Documents/* && "${rel}" != Documents/*/* && -d "${path}" ]]; then
    emit SKIP "${rel}" "" "keep existing Documents folders; only loose files move"
    return
  fi
  if is_tax_or_record "${name}"; then
    emit MOVE "${rel}" "Documents/llc/records/${name}" "tax / billing / contract; not generic inbox"
    return
  fi
  emit MOVE "${rel}" "$(inbox_dest "${rel}")" "loose item"
}

scan_children() {
  local root="$1"
  local prefix="$2"
  [[ -d "${root}" ]] || return 0
  find "${root}" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
    | sort -z \
    | while IFS= read -r -d '' path; do
        classify "${path}" "${prefix}/$(basename "${path}")"
      done
}

echo "DRY-RUN inventory+plan of ${HOME_DIR} -> ${OUT}"

{
  printf 'action\tsource\tdestination\treason\n'
  find "${HOME_DIR}" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
    | sort -z \
    | while IFS= read -r -d '' path; do
        name="$(basename "${path}")"
        if is_user_folder "${name}"; then
          scan_children "${path}" "${name}"
          continue
        fi
        classify "${path}" "${name}"
      done
} > "${OUT}"

moves="$(awk -F '\t' 'NR>1 && $1=="MOVE" {c++} END {print c+0}' "${OUT}")"
secrets="$(awk -F '\t' 'NR>1 && $1=="SECRET" {c++} END {print c+0}' "${OUT}")"
skips="$(awk -F '\t' 'NR>1 && $1=="SKIP" {c++} END {print c+0}' "${OUT}")"
echo "Wrote ${OUT}"
echo "Proposed MOVE rows: ${moves}"
echo "Proposed SECRET rows (~/.keys): ${secrets}"
echo "SKIP rows: ${skips}"
echo "Nothing was moved. Open the TSV, edit rows, then Hermes one folder at a time."
echo "After ~/.keys is filled, run your existing export-keys-to-vault.sh yourself."
