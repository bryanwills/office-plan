#!/usr/bin/env bash
#
# deploy-paperless.sh — install Paperless-ngx on ai-nuc, Tailscale-only.
# Run ON ai-nuc. Does not publish 0.0.0.0.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STACK="${PAPERLESS_STACK:-/opt/stacks/paperless}"
DATA="${PAPERLESS_DATA:-/opt/stacks/paperless}"
OVERLAY="${REPO_ROOT}/stacks/paperless"
TS_IP="$(tailscale ip -4)"

if [[ ! -d "${OVERLAY}" ]]; then
  echo "Overlay missing: ${OVERLAY}" >&2
  exit 1
fi

if [[ ! -d /mnt/ai-data ]]; then
  echo "/mnt/ai-data is not mounted. Stop." >&2
  exit 1
fi

if [[ "${TS_IP}" != "100.73.71.29" ]]; then
  echo "Warning: Tailscale IPv4 is ${TS_IP}, compose file binds 100.73.71.29." >&2
  echo "Edit ${STACK}/docker-compose.yml ports if this is no longer the NUC address." >&2
fi

PLUGIN="${HOME}/.docker/cli-plugins/docker-compose"
if [[ ! -x "${PLUGIN}" ]] && ! docker compose version >/dev/null 2>&1; then
  echo "Installing Docker Compose plugin to ${PLUGIN}..."
  mkdir -p "$(dirname "${PLUGIN}")"
  curl -fsSL "https://github.com/docker/compose/releases/download/v2.39.2/docker-compose-linux-x86_64" -o "${PLUGIN}"
  chmod +x "${PLUGIN}"
fi

mkdir -p "${STACK}" \
  "${DATA}/data" "${DATA}/media" "${DATA}/export" "${DATA}/consume" \
  "${DATA}/pgdata" "${DATA}/redis"

cp "${OVERLAY}/docker-compose.yml" "${STACK}/docker-compose.yml"

if [[ ! -f "${STACK}/.env" ]]; then
  umask 077
  {
    echo "PAPERLESS_SECRET_KEY=$(openssl rand -hex 32)"
    echo "PAPERLESS_DBPASS=$(openssl rand -hex 16)"
    echo "PAPERLESS_ADMIN_USER=bryan"
    echo "PAPERLESS_ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)"
    echo "PAPERLESS_UID=$(id -u)"
    echo "PAPERLESS_GID=$(id -g)"
  } > "${STACK}/.env"
  chmod 600 "${STACK}/.env"
  echo "Wrote ${STACK}/.env (mode 600). Admin password is in that file."
fi

cd "${STACK}"
docker compose pull
docker compose up -d

echo
echo "Waiting for Paperless..."
ok=0
for i in $(seq 1 60); do
  if curl -fsS --max-time 3 "http://${TS_IP}:8010/" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 3
done

docker compose ps
if [[ "${ok}" -eq 1 ]]; then
  echo "Paperless is up at http://ai-nuc.taild5c0d3.ts.net:8010"
  echo "Also: http://${TS_IP}:8010"
  echo "Drop files in ${DATA}/consume"
  echo "Admin user/password: ${STACK}/.env"
else
  echo "Did not respond on :8010 yet. Logs:" >&2
  docker compose logs --tail 80 webserver || true
  exit 2
fi
