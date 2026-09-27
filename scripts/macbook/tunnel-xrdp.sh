#!/usr/bin/env bash
#
# tunnel-xrdp.sh — run on the Mac. Do not reboot the NUC.
#
# xrdp is up on ai-nuc :3389. ufw does not allow 3389, so Microsoft
# Remote Desktop to 100.73.71.29:3389 or 172.16.1.232:3389 will hang.
# This is the same SSH -L pattern as last time. -T is not a forward.
#
#   bash scripts/macbook/tunnel-xrdp.sh
#   then Windows App / Microsoft Remote Desktop → 127.0.0.1
#   session type: Xorg    user: bryanwills
#
set -euo pipefail

HOST="${NUC_SSH_HOST:-bryanwills@100.73.71.29}"
LOCAL_PORT="${XRDP_LOCAL_PORT:-3389}"

echo "Tunnel: 127.0.0.1:${LOCAL_PORT} -> ${HOST}:127.0.0.1:3389"
echo "Leave this window open. Connect the RDP client to 127.0.0.1:${LOCAL_PORT}"
exec ssh -N -L "${LOCAL_PORT}:127.0.0.1:3389" "${HOST}"
