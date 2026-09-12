#!/usr/bin/env bash
#
# setup-nuc-share.sh — Configure the AI-NUC as an SMB file server for the MacBook Pro,
# plus an inotify watcher that auto-indexes files dropped into the ingest folder.
#
# Run ON THE AI-NUC, as root:
#     sudo SMB_PASSWORD_FILE=~/.smb-setup-pw bash setup-nuc-share.sh
#
# Idempotent: safe to re-run. Existing smb.conf is backed up on first run only.

set -euo pipefail

NUC_USER="${NUC_USER:-bryanwills}"
NUC_HOME="$(getent passwd "$NUC_USER" | cut -d: -f6)"
INGEST_DIR="$NUC_HOME/ingest"
REPO_DIR="$NUC_HOME/office-plan"
TAILNET="100.64.0.0/10"

# Primary LAN interface = whatever carries the default route (not a docker bridge).
LAN_IFACE="${LAN_IFACE:-$(ip -4 route show default | awk '{print $5; exit}')}"
# Connected subnet for that interface, e.g. 172.16.1.0/24 — no ipcalc needed.
LAN_SUBNET="${LAN_SUBNET:-$(ip -4 route show dev "$LAN_IFACE" scope link 2>/dev/null | awk '{print $1; exit}')}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "must run as root (use sudo)"
[[ -n "$NUC_HOME" && -d "$NUC_HOME" ]] || die "cannot resolve home dir for user '$NUC_USER'"
# Password may come from a root-only file (preferred: never hits argv or ps)
# or from the environment.
if [[ -n "${SMB_PASSWORD_FILE:-}" ]]; then
  [[ -r "$SMB_PASSWORD_FILE" ]] || die "SMB_PASSWORD_FILE '$SMB_PASSWORD_FILE' is not readable"
  SMB_PASSWORD="$(< "$SMB_PASSWORD_FILE")"
fi
[[ -n "${SMB_PASSWORD:-}" ]] || die "set SMB_PASSWORD_FILE or SMB_PASSWORD"

# ---------------------------------------------------------------- packages ---
log "Installing samba and inotify-tools"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq samba samba-common-bin smbclient inotify-tools acl >/dev/null

# ------------------------------------------------------------- directories ---
log "Creating ingest tree at $INGEST_DIR"
install -d -o "$NUC_USER" -g "$NUC_USER" -m 0755 \
  "$INGEST_DIR" \
  "$INGEST_DIR/inbox" \
  "$INGEST_DIR/processed" \
  "$INGEST_DIR/failed" \
  "$NUC_HOME/ai" \
  "$NUC_HOME/ai/scripts" \
  "$NUC_HOME/ai/logs" \
  "$NUC_HOME/.config/systemd/user"

[[ -d "$REPO_DIR" ]] || warn "$REPO_DIR does not exist; the office-plan share will be empty until you clone it"

# ------------------------------------------------------------ samba config ---
[[ -n "$LAN_IFACE" ]] || die "could not detect the LAN interface; set LAN_IFACE=..."
[[ -n "$LAN_SUBNET" ]] || die "could not detect the LAN subnet; set LAN_SUBNET=a.b.c.0/24"
log "LAN interface $LAN_IFACE, subnet $LAN_SUBNET, tailnet $TAILNET"

# Binding by interface ("interfaces = lo tailscale0 wlan0", "bind interfaces
# only = yes") does not work reliably with Tailscale: smbd's interface
# auto-detection wants a broadcast address per interface, tailscale0 is a
# point-to-point /32 (NOARP) link with none, and depending on version smbd
# either logs "open_socket_in failed: Address family not supported by
# protocol" and skips it, or — as seen on this box even after passing the
# tailscale IP as an explicit ip/32 — silently never opens that listener at
# all, with no error logged. Either way the tailnet path goes dark while smbd
# still reports "active".
#
# Fix: bind on every interface (0.0.0.0), including the docker bridges, and do
# ALL client filtering with Samba's own per-connection ACL (hosts allow/deny
# below) plus a host firewall rule. This is the standard, version-proof way to
# run Samba behind Tailscale/WireGuard. A connection from a docker0/br-*
# address is still rejected — hosts allow lists only loopback, the tailnet,
# and the LAN subnet, and hosts deny closes everything else.

if [[ -f /etc/samba/smb.conf && ! -f /etc/samba/smb.conf.orig ]]; then
  cp -a /etc/samba/smb.conf /etc/samba/smb.conf.orig
  log "Backed up stock config to /etc/samba/smb.conf.orig"
fi

cat > /etc/samba/smb.conf <<EOF
# Managed by office-plan/scripts/ai-nuc/setup-nuc-share.sh — edits will be overwritten.
[global]
   workgroup = WORKGROUP
   server string = ai-nuc
   server role = standalone server
   security = user
   map to guest = never
   restrict anonymous = 2

   # Bind on all interfaces (see the comment above this block for why
   # interface-scoped binding is unreliable with Tailscale) and enforce the
   # actual client allowlist here instead.
   bind interfaces only = no
   hosts allow = 127.0.0.1 $TAILNET $LAN_SUBNET
   hosts deny = 0.0.0.0/0

   # SMB3 only, encryption negotiated when the client supports it.
   server min protocol = SMB3
   client min protocol = SMB3
   server smb encrypt = desired

   # macOS / Finder interoperability (Apple extensions + resource forks).
   vfs objects = catia fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:posix_rename = yes
   fruit:veto_appledouble = no
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:delete_empty_adfiles = yes
   fruit:nfs_aces = no

   # Throughput tuning for a WiFi-attached host.
   use sendfile = yes
   min receivefile size = 16384
   aio read size = 16384
   aio write size = 16384
   socket options = TCP_NODELAY IPTOS_LOWDELAY

   logging = file
   log file = /var/log/samba/log.%m
   max log size = 1000
   panic action = /usr/share/samba/panic-action %d

   # We manage SMB passwords independently of the Unix account password.
   obey pam restrictions = yes
   unix password sync = no
   pam password change = yes

[ai-nuc-ingest]
   comment = Drop files here; the NUC watcher indexes them automatically
   path = $INGEST_DIR
   browseable = yes
   read only = no
   valid users = $NUC_USER
   force user = $NUC_USER
   force group = $NUC_USER
   create mask = 0644
   directory mask = 0755
   veto files = /.DS_Store/.TemporaryItems/.Spotlight-V100/.Trashes/.fseventsd/
   delete veto files = yes

[ai-nuc-office-plan]
   comment = office-plan git working tree (read-write; git remains the sync channel)
   path = $REPO_DIR
   browseable = yes
   read only = no
   valid users = $NUC_USER
   force user = $NUC_USER
   force group = $NUC_USER
   create mask = 0644
   directory mask = 0755
   # NOTE: .git is deliberately NOT vetoed — hiding it corrupts git over SMB.
   veto files = /.DS_Store/.TemporaryItems/.Spotlight-V100/.Trashes/.fseventsd/
   delete veto files = yes
EOF

log "Validating smb.conf"
testparm -s >/dev/null 2>&1 || die "testparm rejected the generated smb.conf"

# --------------------------------------------------------------- smb user ----
log "Setting SMB password for $NUC_USER"
printf '%s\n%s\n' "$SMB_PASSWORD" "$SMB_PASSWORD" | smbpasswd -s -a "$NUC_USER" >/dev/null
smbpasswd -e "$NUC_USER" >/dev/null

# ---------------------------------------------------------------- firewall ---
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  log "ufw is active — allowing SMB from tailnet and LAN only (default-deny covers everything else, including docker0/br-*)"
  ufw allow from "$TAILNET" to any port 445 proto tcp comment 'SMB from tailnet' >/dev/null
  ufw allow from "$LAN_SUBNET" to any port 445 proto tcp comment 'SMB from LAN' >/dev/null
else
  log "ufw inactive or absent — skipping firewall rules"
fi

# ------------------------------------------------------ watcher + indexer ----
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in ingest-watcher.sh index-ingest.sh; do
  [[ -f "$SRC_DIR/$f" ]] || die "missing $f next to this script — copy the whole scripts/ai-nuc/ directory over"
  install -o "$NUC_USER" -g "$NUC_USER" -m 0755 "$SRC_DIR/$f" "$NUC_HOME/ai/scripts/$f"
done
log "Installed watcher and indexer into $NUC_HOME/ai/scripts/"

install -o "$NUC_USER" -g "$NUC_USER" -m 0644 /dev/stdin \
  "$NUC_HOME/.config/systemd/user/ingest-watcher.service" <<EOF
[Unit]
Description=AI-NUC ingest folder watcher (auto-index dropped files)
Documentation=file://$NUC_HOME/ai/scripts/ingest-watcher.sh
After=default.target

[Service]
Type=simple
Environment=INGEST_DIR=$INGEST_DIR
ExecStart=$NUC_HOME/ai/scripts/ingest-watcher.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# Let the user's systemd instance run without an active login session.
loginctl enable-linger "$NUC_USER"

# ----------------------------------------------------------------- enable ----
log "Enabling smbd + nmbd"
systemctl enable --now smbd nmbd >/dev/null 2>&1 || systemctl enable --now smbd >/dev/null
systemctl restart smbd

log "Enabling ingest-watcher user service"
sudo -u "$NUC_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$NUC_USER")" \
  systemctl --user daemon-reload
sudo -u "$NUC_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$NUC_USER")" \
  systemctl --user enable --now ingest-watcher.service

# ------------------------------------------------------------ verification ---
echo
log "Verification"
printf '  smbd:    %s\n' "$(systemctl is-active smbd)"
printf '  watcher: %s\n' "$(sudo -u "$NUC_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$NUC_USER")" systemctl --user is-active ingest-watcher.service)"
printf '  shares:\n'
smbclient -L localhost -U "$NUC_USER%$SMB_PASSWORD" 2>/dev/null | sed -n '/Sharename/,/^$/p' | sed 's/^/    /'
printf '  listening on 445 (expect 0.0.0.0:445 — client filtering is via hosts allow/deny + ufw, not bind address):\n'
ss -lntp 2>/dev/null | grep ':445' | sed 's/^/    /' || echo '    (none — smbd is not listening at all, check systemctl status smbd)'
echo
log "Done. Mount from the Mac with: scripts/macbook/install-mac-mount.sh"
