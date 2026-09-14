#!/usr/bin/env bash
#
# install-honcho-config.sh — MacBook side.
#
# Writes the Honcho pointer into the tracked dotfiles path:
#   ~/.config/.honcho/config.json
#
# Hermes Agent does not read that XDG path. It looks at (in order):
#   $HERMES_HOME/honcho.json
#   ~/.hermes/honcho.json
#   ~/.honcho/config.json
#
# So this script also makes ~/.honcho a symlink to ~/.config/.honcho
# unless ~/.honcho already exists as a real directory.
#
# Run from the office-plan clone on the Mac:
#   bash scripts/macbook/install-honcho-config.sh
#
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${SRC_DIR}/stacks/honcho/hermes-config.json"
DEST_DIR="${HOME}/.config/.honcho"
DEST="${DEST_DIR}/config.json"
HERMES_LINK="${HOME}/.honcho"

[[ -f "${SRC}" ]] || {
  echo "missing ${SRC}" >&2
  exit 1
}

mkdir -p "${DEST_DIR}"
cp "${SRC}" "${DEST}"
chmod 600 "${DEST}"

if [[ -L "${HERMES_LINK}" ]]; then
  ln -sfn "${DEST_DIR}" "${HERMES_LINK}"
elif [[ -e "${HERMES_LINK}" ]]; then
  echo "NOTE: ${HERMES_LINK} already exists and is not a symlink."
  echo "Leave it, or replace it with: ln -sfn ${DEST_DIR} ${HERMES_LINK}"
else
  ln -sfn "${DEST_DIR}" "${HERMES_LINK}"
fi

echo "Wrote ${DEST}"
echo "Hermes will read ${HERMES_LINK}/config.json -> ${DEST}"
echo "Start a new Hermes session. Do not keep appending to an old one."
