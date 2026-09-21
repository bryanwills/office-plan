#!/usr/bin/env bash
#
# Patch Open WebUI's Google Picker: show folders, allow images/video.
# The upstream chunk hides folders (NAV_HIDDEN + setIncludeFolders(false))
# and only lists PDF/Docs/Sheets/Slides.
#
# Run on ai-nuc after `docker compose up` if Drive folders vanish
# (image pull changes the hashed chunk name).
#
set -euo pipefail

STACK="${OPENWEBUI_STACK:-/opt/stacks/open-webui}"
PATCH_DIR="${STACK}/patches"
mkdir -p "${PATCH_DIR}"

chunk="$(docker exec open-webui sh -c 'grep -l setIncludeFolders /app/build/_app/immutable/chunks/*.js' | head -1)"
[[ -n "${chunk}" ]] || { echo "no picker chunk in container" >&2; exit 1; }

tmp="$(mktemp)"
docker cp "open-webui:${chunk}" "${tmp}"

python3 - "${tmp}" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
t = p.read_text()
old = (
    '.enableFeature(google.picker.Feature.NAV_HIDDEN)'
    '.enableFeature(google.picker.Feature.MULTISELECT_ENABLED)'
    '.addView(new google.picker.DocsView()'
    '.setIncludeFolders(!1)'
    '.setSelectFolderEnabled(!1)'
    '.setMimeTypes("application/pdf,text/plain,'
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document,'
    'application/vnd.google-apps.document,'
    'application/vnd.google-apps.spreadsheet,'
    'application/vnd.google-apps.presentation")'
)
new = (
    '.enableFeature(google.picker.Feature.MULTISELECT_ENABLED)'
    '.addView(new google.picker.DocsView()'
    '.setIncludeFolders(!0)'
    '.setSelectFolderEnabled(!1)'
    '.setMimeTypes("application/pdf,text/plain,'
    'image/jpeg,image/jpg,image/png,image/webp,image/heic,image/heif,video/mp4,'
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document,'
    'application/vnd.google-apps.document,'
    'application/vnd.google-apps.spreadsheet,'
    'application/vnd.google-apps.presentation")'
)
if "setIncludeFolders(!0)" in t and "image/jpeg" in t and "NAV_HIDDEN" not in t:
    print("already patched")
    raise SystemExit(0)
if old not in t:
    raise SystemExit("upstream picker pattern not found; Open WebUI image may have changed")
p.write_text(t.replace(old, new, 1))
print("patched", p)
PY

name="$(basename "${chunk}")"
cp "${tmp}" "${PATCH_DIR}/${name}"
docker cp "${tmp}" "open-webui:${chunk}"
rm -f "${tmp}"
echo "Wrote ${PATCH_DIR}/${name} and updated ${chunk} in the container."
echo "Hard-refresh Chrome on http://localhost:3000 (Cmd-Shift-R)."
