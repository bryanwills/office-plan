#!/usr/bin/env bash
#
# setup-cudy-wifi.sh — Cudy USB radio → wlan1, static 172.16.1.233
#
# Clones the existing 5 GHz profile for the PSK, then joins the same
# 5 GHz SSID (MooseSpencer5.0G) on a second radio. 2.4 GHz is never used.
#
# rtw88 often comes up half-dead on this stick (USB -71, empty scan).
# This script USB-resets the dongle, then locks the 5 GHz BSSID.
#
# Does not become the default route (metric 700, never-default).
# Does not reboot. Needs sudo.
#
#   sudo bash /home/bryanwills/office-plan/scripts/ai-nuc/setup-cudy-wifi.sh
#
set -euo pipefail

SRC_CON="${WIFI_SRC_CON:-MooseSpencer5.0G}"
SSID="${WIFI_SSID:-MooseSpencer5.0G}"
NEW_CON="${WIFI_NEW_CON:-MooseSpencer5.0G-cudy}"
# a = 5 GHz only. Never bg / 2.4.
BAND="${WIFI_BAND:-a}"
# Same 5 GHz AP wlan0 is on (5500 MHz / ch 100).
BSSID="${WIFI_BSSID:-28:74:F5:58:16:5C}"
MAC="${CUDY_MAC:-d4:0d:ab:70:02:58}"
IFACE="${CUDY_IFACE:-wlan1}"
ADDR="${CUDY_ADDR:-172.16.1.233/24}"
GW="${CUDY_GW:-172.16.1.254}"
DNS="${CUDY_DNS:-1.1.1.1,8.8.8.8}"
METRIC="${CUDY_METRIC:-700}"
LINK_FILE="/etc/systemd/network/10-${IFACE}.link"

mac_colon="$(printf '%s' "${MAC}" | tr '[:upper:]' '[:lower:]' | sed 's/-/:/g')"

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run with sudo: sudo bash $0" >&2
    exit 1
  fi
}

current_name() {
  local d
  for d in /sys/class/net/*; do
    [[ -e "${d}/address" ]] || continue
    if [[ "$(cat "${d}/address")" == "${mac_colon}" ]]; then
      basename "${d}"
      return 0
    fi
  done
  return 1
}

usb_device_dir() {
  local name p
  name="$(current_name)" || return 1
  p="$(readlink -f "/sys/class/net/${name}/device")"
  while [[ -n "${p}" && "${p}" != "/" ]]; do
    if [[ -f "${p}/idVendor" && -f "${p}/authorized" ]]; then
      printf '%s\n' "${p}"
      return 0
    fi
    p="$(dirname "${p}")"
  done
  return 1
}

reset_usb() {
  local usb
  usb="$(usb_device_dir)" || {
    echo "Could not find USB parent for ${mac_colon}" >&2
    return 1
  }
  echo "USB-resetting Cudy at ${usb} (clears rtw88 -71 / empty scan)"
  printf '0\n' > "${usb}/authorized"
  sleep 2
  printf '1\n' > "${usb}/authorized"
  local i
  for i in $(seq 1 20); do
    if current_name >/dev/null; then
      return 0
    fi
    sleep 1
  done
  echo "Cudy did not reappear after USB reset. Unplug, wait 10s, plug into a different rear USB port." >&2
  exit 3
}

write_link_file() {
  cat > "${LINK_FILE}" <<EOF
[Match]
MACAddress=${mac_colon}

[Link]
Name=${IFACE}
EOF
  chmod 644 "${LINK_FILE}"
}

rename_now() {
  local cur
  cur="$(current_name)" || { echo "Cudy MAC ${mac_colon} not plugged in" >&2; exit 2; }
  if [[ "${cur}" != "${IFACE}" ]]; then
    ip link set "${cur}" down
    ip link set "${cur}" name "${IFACE}"
    echo "Renamed ${cur} -> ${IFACE}"
  else
    echo "Already named ${IFACE}"
  fi
  ip link set "${IFACE}" up || true
}

ensure_connection() {
  if ! nmcli -t -f NAME connection show | grep -Fxq "${NEW_CON}"; then
    nmcli connection clone "${SRC_CON}" "${NEW_CON}"
  fi
  # 5 GHz only. Clear any leftover 2.4 GHz lock from an earlier run.
  # Do not set channel: NM rejects channel 0, and DFS ch 100 is better left to the AP.
  nmcli connection modify "${NEW_CON}" \
    connection.interface-name "${IFACE}" \
    802-11-wireless.mac-address "${mac_colon}" \
    802-11-wireless.ssid "${SSID}" \
    802-11-wireless.bssid "${BSSID}" \
    802-11-wireless.band "${BAND}" \
    ipv4.method manual \
    ipv4.addresses "${ADDR}" \
    ipv4.gateway "${GW}" \
    ipv4.dns "${DNS}" \
    ipv4.route-metric "${METRIC}" \
    ipv4.never-default yes \
    ipv6.method ignore \
    connection.autoconnect yes
}

scan_or_warn() {
  nmcli device set "${IFACE}" managed yes || true
  sleep 2
  nmcli device wifi rescan ifname "${IFACE}" || true
  sleep 5
  echo "Cudy scan (looking for 5 GHz ${SSID} ${BSSID}):"
  nmcli -f SSID,CHAN,BSSID,SIGNAL,FREQ device wifi list ifname "${IFACE}" | head -20
  if ! nmcli -t -f SSID device wifi list ifname "${IFACE}" | grep -Fq "${SSID}"; then
    echo
    echo "Scan is still empty or missing ${SSID}."
    echo "Kernel already logged: rtw88_8822bu write register 0xc4 failed with -71"
    echo "Unplug the Cudy, wait 10 seconds, plug it into a different rear USB port (not a hub), then re-run this script."
    echo "This AP is on DFS channel 100. If association still times out after a clean scan, move MooseSpencer5.0G to a non-DFS 5 GHz channel (36-48 or 149-165)."
  fi
}

main() {
  need_root
  nmcli -t -f NAME connection show | grep -Fxq "${SRC_CON}" \
    || { echo "missing source connection ${SRC_CON}" >&2; exit 2; }
  write_link_file
  rename_now
  reset_usb
  rename_now
  ensure_connection
  scan_or_warn
  nmcli connection up "${NEW_CON}" ifname "${IFACE}"
  echo
  ip -br addr show "${IFACE}"
  nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.GATEWAY device show "${IFACE}"
  echo
  echo "wlan0 stays ${SRC_CON} / 172.16.1.232 on 5 GHz (default route)."
  echo "${IFACE} is ${SSID} ${ADDR} on 5 GHz (no default route)."
}

main "$@"
