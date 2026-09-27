#!/usr/bin/env bash
#
# apply-ollama-traefik.sh — run on the MacBook (has SSH to netcup).
#
# Copies the ollama.bryanwills.org file-provider route onto gateway.
# ai-nuc cannot do this: no SSH private key, Tailscale SSH hung on check.
#
#   bash scripts/macbook/apply-ollama-traefik.sh
#
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${SRC_DIR}/docs/infrastructure/stacks/traefik/dynamic/ollama.yml"
# Prefer Tailscale; fall back to the public netcup IP.
HOST="${GATEWAY_SSH_HOST:-bryan@100.90.171.127}"
DEST="/opt/stacks/traefik/dynamic/ollama.yml"

[[ -f "${SRC}" ]] || { echo "missing ${SRC}" >&2; exit 1; }

echo "Copying ${SRC} -> ${HOST}:${DEST}"
scp "${SRC}" "${HOST}:/tmp/ollama.yml"
ssh "${HOST}" "sudo install -m 644 /tmp/ollama.yml ${DEST} && rm -f /tmp/ollama.yml && ls -l ${DEST}"

echo
echo "Waiting for Let's Encrypt (TLS-ALPN on :443)..."
ok=0
for i in $(seq 1 30); do
  subj="$(echo | openssl s_client -connect ollama.bryanwills.org:443 -servername ollama.bryanwills.org 2>/dev/null | openssl x509 -noout -subject 2>/dev/null || true)"
  if echo "${subj}" | grep -q 'ollama.bryanwills.org'; then
    ok=1
    echo "${subj}"
    break
  fi
  sleep 3
done

if [[ "${ok}" -eq 1 ]]; then
  echo "Cert is live. Probe: curl -sS https://ollama.bryanwills.org/healthz"
  curl -sS -m 10 -w '\nHTTP %{http_code}\n' https://ollama.bryanwills.org/healthz
else
  echo "Still the Traefik default cert or no match. Check:"
  echo "  ssh ${HOST} 'docker logs traefik --tail 80'"
  exit 2
fi
