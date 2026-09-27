#!/usr/bin/env bash
#
# owui-tunnel.sh — Mac LaunchAgent for Open WebUI :3000. No leftover Terminal.
#
#   bash scripts/macbook/owui-tunnel.sh start
#   bash scripts/macbook/owui-tunnel.sh stop
#   bash scripts/macbook/owui-tunnel.sh status
#   bash scripts/macbook/owui-tunnel.sh install [--login]
#   bash scripts/macbook/owui-tunnel.sh uninstall
#
# start loads a KeepAlive ssh -N -L 3000:127.0.0.1:3000 to ai-nuc.
# stop unloads it. Tailscale must be up. Do not use this for xrdp
# (that is tunnel-xrdp.sh / :3389).
#
# Daily Open WebUI over Tailscale does not need this tunnel:
#   http://100.73.71.29:3000
# This tunnel is for http://localhost:3000 (Google Drive OAuth, or a
# desktop app pointed at localhost).
#
set -euo pipefail

LABEL="${OWUI_TUNNEL_LABEL:-com.bryanwills.owui-tunnel}"
HOST="${NUC_SSH_HOST:-bryanwills@100.73.71.29}"
LOCAL_PORT="${OWUI_LOCAL_PORT:-3000}"
REMOTE_PORT="${OWUI_REMOTE_PORT:-3000}"
BIN="${HOME}/bin/owui-tunnel"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
LOG_OUT="${HOME}/Library/Logs/owui-tunnel.out.log"
LOG_ERR="${HOME}/Library/Logs/owui-tunnel.err.log"

usage() {
  cat <<'EOF'
owui-tunnel.sh — start/stop the Open WebUI localhost:3000 SSH tunnel

  start              load the LaunchAgent (no Terminal window)
  stop               unload the LaunchAgent
  status             show launchd + http://127.0.0.1:3000
  install [--login]  write ~/bin + plist (optional start at login)
  uninstall          stop and remove the LaunchAgent
  --help             this text
  --print-ssh        print the ssh command (tests / dry-run)

Open http://localhost:3000 after start. Quit the Open WebUI desktop
app first if it also binds :3000. For Drive OAuth you need this
tunnel. For normal chat, Tailscale http://100.73.71.29:3000 is enough.
EOF
}

ssh_cmd() {
  printf '%s\n' ssh -N \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o BatchMode=yes \
    -L "${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" \
    "${HOST}"
}

uid_domain() {
  printf 'gui/%s' "$(id -u)"
}

need_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This command talks to launchd. Run it on the Mac." >&2
    exit 1
  fi
}

write_plist() {
  local run_at_load="$1"
  mkdir -p "${HOME}/bin" "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs"
  # Copy this script to ~/bin so launchd does not depend on a clone path.
  if [[ "${BASH_SOURCE[0]}" -ef "${BIN}" ]]; then
    :
  else
    install -m 0755 "${BASH_SOURCE[0]}" "${BIN}"
  fi
  cat > "${PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${BIN}</string>
        <string>--worker</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>NUC_SSH_HOST</key>
        <string>${HOST}</string>
        <key>OWUI_LOCAL_PORT</key>
        <string>${LOCAL_PORT}</string>
        <key>OWUI_REMOTE_PORT</key>
        <string>${REMOTE_PORT}</string>
    </dict>
    <key>RunAtLoad</key>
    <${run_at_load}/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>${LOG_OUT}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_ERR}</string>
</dict>
</plist>
EOF
}

cmd_install() {
  need_macos
  local run_at_load="false"
  if [[ "${1:-}" == "--login" ]]; then
    run_at_load="true"
  elif [[ -n "${1:-}" ]]; then
    echo "unknown install flag: $1" >&2
    exit 2
  fi
  write_plist "${run_at_load}"
  /usr/bin/plutil -lint "${PLIST}" >/dev/null
  echo "Wrote ${BIN}"
  echo "Wrote ${PLIST} (RunAtLoad=${run_at_load})"
  echo "Then: ${BIN} start   or   ${BIN} stop"
}

cmd_start() {
  need_macos
  if [[ ! -f "${PLIST}" ]]; then
    write_plist false
  fi
  local domain
  domain="$(uid_domain)"
  launchctl bootout "${domain}/${LABEL}" 2>/dev/null || true
  launchctl bootstrap "${domain}" "${PLIST}"
  launchctl enable "${domain}/${LABEL}"
  launchctl kickstart -k "${domain}/${LABEL}"
  echo "Tunnel starting: 127.0.0.1:${LOCAL_PORT} -> ${HOST}:127.0.0.1:${REMOTE_PORT}"
  echo "Open http://localhost:${LOCAL_PORT}  Logs: ${LOG_ERR}"
}

cmd_stop() {
  need_macos
  local domain
  domain="$(uid_domain)"
  launchctl bootout "${domain}/${LABEL}" 2>/dev/null || true
  echo "Tunnel stopped (${LABEL})"
}

cmd_status() {
  need_macos
  local domain
  domain="$(uid_domain)"
  if launchctl print "${domain}/${LABEL}" >/dev/null 2>&1; then
    echo "launchd: loaded (${domain}/${LABEL})"
  else
    echo "launchd: not loaded"
  fi
  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"${LOCAL_PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "listen: 127.0.0.1:${LOCAL_PORT} is open"
  else
    echo "listen: nothing on :${LOCAL_PORT}"
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -sS -m 3 -o /dev/null -w "http://127.0.0.1:${LOCAL_PORT} %{http_code}\n" \
      "http://127.0.0.1:${LOCAL_PORT}/" || echo "http://127.0.0.1:${LOCAL_PORT} not reachable"
  fi
}

cmd_uninstall() {
  need_macos
  cmd_stop
  rm -f "${PLIST}"
  echo "Removed ${PLIST}"
  echo "Left ${BIN} in place. Delete it yourself if you want it gone."
}

cmd_worker() {
  # launchd entrypoint. Stay in the foreground until ssh dies; KeepAlive restarts.
  exec $(ssh_cmd)
}

main() {
  local cmd="${1:-}"
  case "${cmd}" in
    ""|-h|--help|help)
      usage
      [[ -n "${cmd}" ]] || exit 2
      exit 0
      ;;
    --print-ssh)
      ssh_cmd
      ;;
    --worker)
      cmd_worker
      ;;
    start|stop|status|install|uninstall)
      shift
      "cmd_${cmd}" "$@"
      ;;
    *)
      echo "unknown command: ${cmd}" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
