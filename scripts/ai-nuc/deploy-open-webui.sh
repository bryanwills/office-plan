#!/usr/bin/env bash
#
# Recreate the existing open-webui container under /opt/stacks/open-webui.
# Keeps the named volume `open-webui` (chats stay). Does not copy data.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="${REPO_ROOT}/stacks/open-webui"
STACK="${OPENWEBUI_STACK:-/opt/stacks/open-webui}"

[[ -f "${SRC}/docker-compose.yml" ]] || { echo "missing ${SRC}/docker-compose.yml" >&2; exit 1; }
[[ -d /opt/stacks ]] || { echo "/opt/stacks missing" >&2; exit 1; }

PLUGIN="${HOME}/.docker/cli-plugins/docker-compose"
if [[ ! -x "${PLUGIN}" ]]; then
  echo "docker compose plugin missing at ${PLUGIN}" >&2
  exit 1
fi

mkdir -p "${STACK}"
install -m 644 "${SRC}/docker-compose.yml" "${STACK}/docker-compose.yml"

if [[ ! -f "${STACK}/.env" ]]; then
  secret="$(docker inspect open-webui --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | awk -F= '/^WEBUI_SECRET_KEY=/{print $2; exit}')"
  secret="${secret:-changeme}"
  cat > "${STACK}/.env" <<EOF
WEBUI_SECRET_KEY=${secret}
ENABLE_GOOGLE_DRIVE_INTEGRATION=false
GOOGLE_DRIVE_CLIENT_ID=
GOOGLE_DRIVE_API_KEY=
GOOGLE_REDIRECT_URI=http://100.73.71.29:3000
EOF
  chmod 600 "${STACK}/.env"
  echo "Wrote ${STACK}/.env (Drive off until you add Client ID + API key)."
fi

# Old container was not a compose project. Drop it, then compose up with same name + volume.
if docker inspect open-webui >/dev/null 2>&1; then
  project="$(docker inspect open-webui --format '{{index .Config.Labels "com.docker.compose.project"}}')"
  if [[ -z "${project}" ]]; then
    echo "Removing non-compose open-webui (volume kept)..."
    docker stop open-webui
    docker rm open-webui
  fi
fi

cd "${STACK}"
docker compose up -d
docker compose ps
curl -sS -m 15 -o /dev/null -w "open-webui http %{http_code}\n" http://127.0.0.1:3000/ || true
echo
echo "Drive: edit ${STACK}/.env, set ENABLE_GOOGLE_DRIVE_INTEGRATION=true and the two Google values, then: docker compose up -d"
echo "UI: http://100.73.71.29:3000  Admin → Settings → Documents → Google Drive"
