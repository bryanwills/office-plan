#!/usr/bin/env bash
#
# honcho-mint-hermes-key.sh — create the Hermes JWT Honcho is missing.
#
# Auth was off (USE_AUTH=false), so /opt/stacks/honcho/.env has Ollama
# placeholder keys only. This writes AUTH_JWT_SECRET, turns auth on,
# restarts the API, and mints a workspace=hermes / peer=hermes token
# to /opt/stacks/honcho/.hermes-jwt (mode 600). Never commit that file.
#
set -euo pipefail

STACK="${HONCHO_STACK:-/opt/stacks/honcho}"
ENV_FILE="${STACK}/.env"
KEY_FILE="${STACK}/.hermes-jwt"
WORKSPACE="${HONCHO_WORKSPACE:-hermes}"
PEER="${HONCHO_PEER:-hermes}"

[[ -f "${ENV_FILE}" ]] || { echo "missing ${ENV_FILE}" >&2; exit 1; }
[[ -d "${STACK}" ]] || { echo "missing ${STACK}" >&2; exit 1; }

umask 077

if ! grep -q '^AUTH_JWT_SECRET=' "${ENV_FILE}"; then
  secret="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  {
    echo
    echo "# Hermes / Honcho auth (generated $(date -Iseconds 2>/dev/null || date))"
    echo "AUTH_USE_AUTH=true"
    echo "AUTH_JWT_SECRET=${secret}"
  } >> "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  echo "Wrote AUTH_JWT_SECRET into ${ENV_FILE}"
else
  if ! grep -q '^AUTH_USE_AUTH=true' "${ENV_FILE}"; then
    if grep -q '^AUTH_USE_AUTH=' "${ENV_FILE}"; then
      sed -i 's/^AUTH_USE_AUTH=.*/AUTH_USE_AUTH=true/' "${ENV_FILE}"
    else
      echo "AUTH_USE_AUTH=true" >> "${ENV_FILE}"
    fi
  fi
  echo "AUTH_JWT_SECRET already present in ${ENV_FILE}"
fi

cd "${STACK}"
docker compose up -d api deriver

ok=0
for _ in $(seq 1 40); do
  if curl -fsS -m 2 http://127.0.0.1:8000/health >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 2
done
[[ "${ok}" -eq 1 ]] || { echo "Honcho /health failed after auth enable" >&2; exit 2; }

token="$(
  docker compose exec -T api /app/.venv/bin/python scripts/generate_jwt.py \
    --workspace "${WORKSPACE}" --peer "${PEER}" --print-only
)"
[[ -n "${token}" ]] || { echo "generate_jwt.py returned empty" >&2; exit 2; }

printf '%s\n' "${token}" > "${KEY_FILE}"
chmod 600 "${KEY_FILE}"

echo
echo "Honcho auth is on. Hermes API key is the JWT in:"
echo "  ${KEY_FILE}"
echo "Paste that value into Hermes → Honcho → API key."
echo "Base URL stays http://100.73.71.29:8000"
echo "Workspace / AI peer stay: ${WORKSPACE} / ${PEER}"
echo "Do not commit ${KEY_FILE} or ${ENV_FILE}."
