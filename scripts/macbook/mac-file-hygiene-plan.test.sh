#!/usr/bin/env bash
#
# mac-file-hygiene-plan.test.sh — dry-run only. Never moves files.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/scripts/macbook/mac-file-hygiene-plan.sh"
fail=0

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "FAIL ${label}: missing '${needle}'" >&2
    fail=1
  fi
}

assert_absent() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    echo "FAIL ${label}: unexpectedly has '${needle}'" >&2
    fail=1
  fi
}

row() {
  local body="$1" action="$2" source="$3"
  awk -F '\t' -v a="${action}" -v s="${source}" '$1==a && $2==s {print; found=1} END {exit found?0:1}' <<<"${body}"
}

[[ -x "${SCRIPT}" ]] || chmod +x "${SCRIPT}"

help_out="$("${SCRIPT}" --help 2>&1 || true)"
assert_contains "${help_out}" "dry-run" "help says dry-run"
assert_contains "${help_out}" ".keys" "help mentions keys dir"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
mkdir -p \
  "${tmpdir}/Desktop" \
  "${tmpdir}/Documents" \
  "${tmpdir}/Downloads" \
  "${tmpdir}/Pictures/Photo Booth Library" \
  "${tmpdir}/Movies/TV" \
  "${tmpdir}/Public/Drop Box" \
  "${tmpdir}/.ssh" \
  "${tmpdir}/.keys" \
  "${tmpdir}/Library/Preferences" \
  "${tmpdir}/Applications" \
  "${tmpdir}/office-plan/.git" \
  "${tmpdir}/Movies/Resolve Project Backups"
printf 'note\n' > "${tmpdir}/Desktop/loose-note.txt"
printf 'old\n' > "${tmpdir}/Downloads/installer.dmg"
printf 'zip\n' > "${tmpdir}/Downloads/payload.zip"
printf 'deb\n' > "${tmpdir}/Downloads/passwordsafe-ubuntu20-1.13-amd64.deb"
printf 'dnd\n' > "${tmpdir}/Downloads/dnd-ttrpg-battle-map-creature-tokens.excalidrawlib"
printf 'sshkey\n' > "${tmpdir}/Downloads/bryans-macbook-pro"
printf 'sshpub\n' > "${tmpdir}/Downloads/bryans-macbook-pro.pub"
mkdir -p "${tmpdir}/Downloads/__MACOSX"
printf 'secret\n' > "${tmpdir}/.ssh/id_ed25519"
printf 'pref\n' > "${tmpdir}/Library/Preferences/x.plist"
printf 'repo\n' > "${tmpdir}/office-plan/README.md"
printf 'key\n' > "${tmpdir}/rui.key"
printf 'crt\n' > "${tmpdir}/rui.crt"
printf 'sshdump\n' > "${tmpdir}/ssh.txt"
printf 'nsec\n' > "${tmpdir}/sample-nsec-DELETE-AFTER-IMPORT.txt"
printf 'vaultmeta\n' > "${tmpdir}/keys.bryanwills.dev"
mkdir -p "${tmpdir}/Desktop/Claude-config-backup-2026-08-23"
printf 'zipcfg\n' > "${tmpdir}/Desktop/Claude-config-backup-2026-08-23.zip"
mkdir -p "${tmpdir}/Desktop/Desktop - Bryan’s MacBook Pro"
printf 'icloud\n' > "${tmpdir}/Desktop/Desktop - Bryan’s MacBook Pro/old.txt"
printf 'tax\n' > "${tmpdir}/Downloads/2025 W2.pdf"
printf 'ok\n' > "${tmpdir}/random_notes.txt"

plan="$("${SCRIPT}" --home "${tmpdir}" --out "${tmpdir}/plan.tsv")"
assert_contains "${plan}" "DRY-RUN" "run announces dry-run"
[[ -s "${tmpdir}/plan.tsv" ]] || { echo "FAIL plan missing" >&2; fail=1; }
body="$(cat "${tmpdir}/plan.tsv")"

assert_contains "${body}" "Desktop/loose-note.txt" "plans Desktop loose file"
assert_contains "${body}" "rui.key" "sees home-root rui.key"
assert_contains "${body}" "keys.bryanwills.dev" "sees non-obvious vault filename"
assert_contains "${body}" ".keys/rui.key" "secrets dest is .keys"
assert_contains "${body}" ".keys/ssh.txt" "ssh.txt to keys"
assert_contains "${body}" ".keys/sample-nsec-DELETE-AFTER-IMPORT.txt" "nsec to keys"
assert_contains "${body}" ".keys/keys.bryanwills.dev" "bryanwills.dev keys file to keys"
assert_contains "${body}" "Documents/llc/records/2025 W2.pdf" "tax to llc records not inbox"
assert_contains "${body}" "Documents/inbox/home/random_notes.txt" "home clutter to inbox/home"

assert_absent "${body}" ".ssh/id_ed25519" "never plans ~/.ssh contents"
assert_absent "${body}" "Library/Preferences" "never plans Library"
assert_absent "${body}" "Applications/" "never plans Applications"
assert_absent "${body}" "office-plan/README.md" "never plans git repos"
if ! row "${body}" SKIP "office-plan" >/dev/null; then
  echo "FAIL office-plan git tree should SKIP" >&2
  fail=1
fi

if ! row "${body}" SKIP "Downloads/installer.dmg" >/dev/null; then
  echo "FAIL installer.dmg should SKIP" >&2
  fail=1
fi
if ! row "${body}" SKIP "Downloads/payload.zip" >/dev/null; then
  echo "FAIL zip should SKIP" >&2
  fail=1
fi
if ! row "${body}" SKIP "Downloads/passwordsafe-ubuntu20-1.13-amd64.deb" >/dev/null; then
  echo "FAIL passwordsafe deb should SKIP as installer" >&2
  fail=1
fi
if ! row "${body}" SKIP "Downloads/dnd-ttrpg-battle-map-creature-tokens.excalidrawlib" >/dev/null; then
  echo "FAIL D&D tokens should SKIP (force-skip list)" >&2
  fail=1
fi
if ! grep -F $'SECRET\tDesktop/Claude-config-backup-2026-08-23.zip' <<<"${body}" >/dev/null; then
  echo "FAIL Claude config zip should SECRET" >&2
  fail=1
fi
if ! row "${body}" SKIP "Downloads/__MACOSX" >/dev/null; then
  echo "FAIL __MACOSX should SKIP" >&2
  fail=1
fi
if ! row "${body}" SKIP "Pictures/Photo Booth Library" >/dev/null; then
  echo "FAIL Photo Booth Library should SKIP" >&2
  fail=1
fi
if ! row "${body}" SKIP "Movies/TV" >/dev/null; then
  echo "FAIL Movies/TV should SKIP" >&2
  fail=1
fi
if ! row "${body}" SKIP "Movies/Resolve Project Backups" >/dev/null; then
  echo "FAIL Resolve backups should SKIP" >&2
  fail=1
fi
if ! row "${body}" SKIP "Public/Drop Box" >/dev/null; then
  echo "FAIL Drop Box should SKIP" >&2
  fail=1
fi
if ! grep -F $'SKIP\tDesktop/Desktop - Bryan’s MacBook Pro' <<<"${body}" >/dev/null; then
  echo "FAIL iCloud Desktop copy should SKIP" >&2
  fail=1
fi
if ! grep -F $'SECRET\tDesktop/Claude-config-backup-2026-08-23\t.keys/' <<<"${body}" >/dev/null; then
  echo "FAIL Claude config backup should SECRET to .keys" >&2
  fail=1
fi

if "${SCRIPT}" --home "${tmpdir}" --execute >/dev/null 2>&1; then
  echo "FAIL --execute must refuse" >&2
  fail=1
fi

if [[ "${fail}" -eq 0 ]]; then
  echo "mac-file-hygiene-plan.test.sh: ok"
  exit 0
fi
echo "mac-file-hygiene-plan.test.sh: failed" >&2
exit 1
