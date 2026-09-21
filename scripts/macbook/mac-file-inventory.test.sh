#!/usr/bin/env bash
#
# mac-file-inventory.test.sh — flag and dry-run checks.
# Does not move files. Safe on Linux or macOS.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/scripts/macbook/mac-file-inventory.sh"
fail=0

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "FAIL ${label}: missing '${needle}'" >&2
    fail=1
  fi
}

assert_exit() {
  local expected="$1" label="$2"
  shift 2
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  if [[ "${rc}" -ne "${expected}" ]]; then
    echo "FAIL ${label}: exit ${rc}, want ${expected}" >&2
    fail=1
  fi
}

[[ -x "${SCRIPT}" ]] || chmod +x "${SCRIPT}"

assert_exit 2 "unknown flag" "${SCRIPT}" --explode
help_out="$("${SCRIPT}" --help 2>&1 || true)"
assert_contains "${help_out}" "read-only" "help says read-only"
assert_contains "${help_out}" "Time Machine" "help warns about Time Machine"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
mkdir -p "${tmpdir}/Downloads" "${tmpdir}/Documents" "${tmpdir}/Desktop" "${tmpdir}/Library/Caches"
printf 'sample\n' > "${tmpdir}/Downloads/note.txt"

out="$("${SCRIPT}" --home "${tmpdir}" --out "${tmpdir}/report.txt")"
assert_contains "${out}" "read-only" "run announces read-only"
[[ -s "${tmpdir}/report.txt" ]] || { echo "FAIL report missing" >&2; fail=1; }
report="$(cat "${tmpdir}/report.txt")"
assert_contains "${report}" "Downloads" "report lists Downloads"
assert_contains "${report}" "SKIP" "report marks Library skip"

if [[ "${fail}" -eq 0 ]]; then
  echo "mac-file-inventory.test.sh: ok"
  exit 0
fi
echo "mac-file-inventory.test.sh: failed" >&2
exit 1
