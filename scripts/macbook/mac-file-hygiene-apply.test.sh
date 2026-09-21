#!/usr/bin/env bash
#
# mac-file-hygiene-apply.test.sh — never touches the real home folder.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/scripts/macbook/mac-file-hygiene-apply.sh"
fail=0

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

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "FAIL ${label}: missing '${needle}'" >&2
    fail=1
  fi
}

[[ -x "${SCRIPT}" ]] || chmod +x "${SCRIPT}"
assert_exit 2 "no plan" "${SCRIPT}"
assert_contains "$("${SCRIPT}" --help 2>&1 || true)" "SECRET" "help mentions SECRET"

home="$(mktemp -d)"
trap 'rm -rf "${home}"' EXIT
mkdir -p "${home}/Downloads" "${home}/Documents" "${home}/.keys"
printf 'keep-secret\n' > "${home}/rui.key"
printf 'note\n' > "${home}/random_notes.txt"
printf 'dmg\n' > "${home}/Downloads/installer.dmg"
printf 'dnd\n' > "${home}/Downloads/dnd-ttrpg-battle-map-creature-tokens.excalidrawlib"
mkdir -p "${home}/AI-NUC/share"
printf 'mount\n' > "${home}/AI-NUC/share/x"
printf 'ok\n' > "${home}/Downloads/loose.pdf"

cat > "${home}/plan.tsv" <<'EOF'
action	source	destination	reason
SECRET	rui.key	.keys/rui.key	secret
MOVE	random_notes.txt	Documents/inbox/home/random_notes.txt	loose
SKIP	Downloads/installer.dmg		zip
MOVE	Downloads/dnd-ttrpg-battle-map-creature-tokens.excalidrawlib	Documents/inbox/downloads/dnd-ttrpg-battle-map-creature-tokens.excalidrawlib	false pos
MOVE	AI-NUC	Documents/inbox/home/AI-NUC	must skip
MOVE	Downloads/loose.pdf	Documents/inbox/downloads/loose.pdf	ok
EOF

dry="$("${SCRIPT}" --home "${home}" --plan "${home}/plan.tsv")"
assert_contains "${dry}" "DRY-RUN" "dry-run banner"
assert_contains "${dry}" "would MOVE" "dry-run would MOVE"
[[ -f "${home}/rui.key" ]] || { echo "FAIL dry-run moved secret" >&2; fail=1; }
[[ -f "${home}/random_notes.txt" ]] || { echo "FAIL dry-run moved notes" >&2; fail=1; }

out="$("${SCRIPT}" --home "${home}" --plan "${home}/plan.tsv" --execute --batch home)"
assert_contains "${out}" "MOVED" "execute moved home batch"
[[ -f "${home}/Documents/inbox/home/random_notes.txt" ]] || { echo "FAIL notes not moved" >&2; fail=1; }
[[ -f "${home}/rui.key" ]] || { echo "FAIL execute moved SECRET" >&2; fail=1; }
[[ -d "${home}/AI-NUC" ]] || { echo "FAIL execute moved AI-NUC" >&2; fail=1; }

out2="$("${SCRIPT}" --home "${home}" --plan "${home}/plan.tsv" --execute --batch downloads)"
assert_contains "${out2}" "MOVED" "downloads batch moved pdf"
[[ -f "${home}/Documents/inbox/downloads/loose.pdf" ]] || { echo "FAIL pdf not moved" >&2; fail=1; }
[[ -f "${home}/Downloads/dnd-ttrpg-battle-map-creature-tokens.excalidrawlib" ]] || {
  echo "FAIL dnd tokens were moved" >&2
  fail=1
}

assert_exit 2 "refuse secrets batch" "${SCRIPT}" --home "${home}" --plan "${home}/plan.tsv" --execute --batch secrets

if [[ "${fail}" -eq 0 ]]; then
  echo "mac-file-hygiene-apply.test.sh: ok"
  exit 0
fi
echo "mac-file-hygiene-apply.test.sh: failed" >&2
exit 1
