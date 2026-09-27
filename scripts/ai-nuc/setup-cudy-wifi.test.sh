#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/scripts/ai-nuc/setup-cudy-wifi.sh"
fail=0

[[ -x "${SCRIPT}" ]] || chmod +x "${SCRIPT}"

if "${SCRIPT}" >/dev/null 2>&1; then
  echo "FAIL: must refuse without root" >&2
  fail=1
fi

help_err="$("${SCRIPT}" 2>&1 || true)"
if [[ "${help_err}" != *"sudo"* ]]; then
  echo "FAIL: should mention sudo" >&2
  fail=1
fi

if [[ "${fail}" -eq 0 ]]; then
  echo "setup-cudy-wifi.test.sh: ok"
  exit 0
fi
exit 1
