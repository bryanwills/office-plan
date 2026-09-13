#!/usr/bin/env bash
#
# deploy-honcho.sh — clone upstream Honcho into /opt/stacks/honcho and
# overlay the ai-nuc compose/config from this repo.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STACK="${HONCHO_STACK:-/opt/stacks/honcho}"
OVERLAY="${REPO_ROOT}/stacks/honcho"
UPSTREAM="https://github.com/plastic-labs/honcho.git"

if [[ ! -d "${OVERLAY}" ]]; then
  echo "Overlay missing: ${OVERLAY}" >&2
  exit 1
fi

if [[ ! -d "$(dirname "${STACK}")" ]]; then
  echo "${STACK}'s parent does not exist. Format/mount ai-data first." >&2
  exit 1
fi

# User-level Compose plugin (this host's Docker package has no compose).
PLUGIN="${HOME}/.docker/cli-plugins/docker-compose"
if [[ ! -x "${PLUGIN}" ]]; then
  echo "Installing Docker Compose plugin to ${PLUGIN}..."
  mkdir -p "$(dirname "${PLUGIN}")"
  curl -fsSL "https://github.com/docker/compose/releases/download/v2.39.2/docker-compose-linux-x86_64" -o "${PLUGIN}"
  chmod +x "${PLUGIN}"
fi
docker compose version >/dev/null

if [[ ! -d "${STACK}/.git" ]]; then
  echo "Cloning plastic-labs/honcho into ${STACK}..."
  git clone --depth 1 "${UPSTREAM}" "${STACK}"
else
  echo "Honcho clone exists at ${STACK}. Not pulling (would wipe overlay)."
fi

echo "Overlaying ai-nuc compose, config, and env..."
cp "${OVERLAY}/docker-compose.yml" "${STACK}/docker-compose.yml"
cp "${OVERLAY}/config.toml" "${STACK}/config.toml"
if [[ ! -f "${STACK}/.env" ]]; then
  cp "${OVERLAY}/.env.example" "${STACK}/.env"
  chmod 600 "${STACK}/.env"
fi

mkdir -p "${STACK}/data/pgdata" "${STACK}/data/redis"
# Postgres in the official image runs as uid 999
chmod 777 "${STACK}/data/pgdata" "${STACK}/data/redis" || true

echo "Building and starting Honcho (first build is slow)..."
cd "${STACK}"
docker compose up -d --build

# Fresh DBs migrate to vector(1536). We use nomic-embed-text (768).
# Resize empty columns once, then the API validator will accept boot.
if ! curl -fsS --max-time 3 http://127.0.0.1:8000/health >/dev/null 2>&1; then
  echo "Resizing pgvector columns to 768 (nomic-embed-text)..."
  docker compose run --rm --no-deps --entrypoint /app/.venv/bin/python \
    api scripts/configure_embeddings.py --yes || true
  docker compose up -d api deriver
fi

echo
echo "Waiting for API health..."
ok=0
for i in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 2
done

docker compose ps
if [[ "${ok}" -eq 1 ]]; then
  echo "Honcho API is up at http://127.0.0.1:8000 (Tailscale: http://100.73.71.29:8000)"
  echo "On the MacBook: mkdir -p ~/.honcho && cp ${OVERLAY}/hermes-config.json ~/.honcho/config.json"
else
  echo "API did not pass /health yet. Logs:" >&2
  docker compose logs --tail 80 api deriver || true
  exit 2
fi
