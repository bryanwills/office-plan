#!/usr/bin/env bash
#
# owui-tunnel.test.sh — argument and ssh-command checks.
# Runs on Linux or macOS. Does not start ssh or launchd.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/scripts/macbook/owui-tunnel.sh"
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

assert_exit 2 "no args" "${SCRIPT}"
assert_exit 2 "unknown command" "${SCRIPT}" frobnicate

help_out="$("${SCRIPT}" --help 2>&1 || true)"
assert_contains "${help_out}" "start" "help lists start"
assert_contains "${help_out}" "stop" "help lists stop"

ssh_out="$(NUC_SSH_HOST=bryanwills@100.73.71.29 "${SCRIPT}" --print-ssh)"
assert_contains "${ssh_out}" "ssh" "print-ssh invokes ssh"
assert_contains "${ssh_out}" "-N" "print-ssh is no-shell"
assert_contains "${ssh_out}" "3000:127.0.0.1:3000" "print-ssh forwards 3000"
assert_contains "${ssh_out}" "ExitOnForwardFailure=yes" "print-ssh fails if 3000 is taken"
assert_contains "${ssh_out}" "bryanwills@100.73.71.29" "print-ssh uses NUC host"

if [[ "${fail}" -eq 0 ]]; then
  echo "owui-tunnel.test.sh: ok"
  exit 0
fi
echo "owui-tunnel.test.sh: failed" >&2
exit 1
