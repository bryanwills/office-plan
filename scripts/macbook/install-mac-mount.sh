#!/bin/bash
#
# install-mac-mount.sh — MacBook Pro side of the AI-NUC mount.
#
#   SMB_PASSWORD_FILE=~/.smb-setup-pw bash install-mac-mount.sh
#
# 1. Stores the SMB password in the login Keychain, readable by the `security`
#    CLI without a prompt (mount-ai-nuc.sh reads it back at mount time and
#    hands it straight to mount_smbfs — see that script for why Finder's own
#    `mount volume` / NetAuthAgent path is not used here).
# 2. Installs mount-ai-nuc.sh to ~/bin.
# 3. Installs + loads a LaunchAgent that mounts at login and self-heals
#    every 5 minutes (covers sleep/wake, WiFi drops, NUC reboots).
#
# No sudo required. No kernel extensions. SIP stays enabled. Shares land at
# ~/AI-NUC/<share>, not /Volumes — /Volumes is root-owned and mount_smbfs
# can't create an entry there without going through Finder's helper.

set -euo pipefail

[[ -r "$HOME/.config/ai-nuc/env" ]] && . "$HOME/.config/ai-nuc/env"
NUC_HOST="${NUC_HOST:?set NUC_HOST in ~/.config/ai-nuc/env or the environment}"
NUC_USER="${NUC_USER:-$(id -un)}"
LABEL="com.bryanwills.ai-nuc-mount"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/bin/mount-ai-nuc.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }

if [[ -n "${SMB_PASSWORD_FILE:-}" ]]; then
  [[ -r "$SMB_PASSWORD_FILE" ]] || die "SMB_PASSWORD_FILE '$SMB_PASSWORD_FILE' is not readable"
  SMB_PASSWORD="$(< "$SMB_PASSWORD_FILE")"
fi
[[ -n "${SMB_PASSWORD:-}" ]] || die "set SMB_PASSWORD_FILE or SMB_PASSWORD"

# ----------------------------------------------------------------- keychain --
log "Storing SMB credentials in the login Keychain"
# -r "smb " is the four-char protocol code for SMB (note the trailing space).
# -T authorises NetAuthAgent to read it without an allow/deny dialog.
# -U updates the entry in place if it already exists.
security add-internet-password \
  -a "$NUC_USER" \
  -s "$NUC_HOST" \
  -r "smb " \
  -P 445 \
  -l "$NUC_HOST ($NUC_USER)" \
  -D "network password" \
  -T /System/Library/CoreServices/NetAuthAgent.app \
  -T /usr/bin/security \
  -w "$SMB_PASSWORD" \
  -U

# -------------------------------------------------------------- mount script --
log "Installing mount script to $BIN"
mkdir -p "$HOME/bin"
install -m 0755 "$SRC_DIR/mount-ai-nuc.sh" "$BIN"

# -------------------------------------------------------------- launchagent --
log "Installing LaunchAgent $LABEL"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>NUC_HOST</key>
        <string>$NUC_HOST</string>
        <key>NUC_USER</key>
        <string>$NUC_USER</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/ai-nuc-mount.out.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/ai-nuc-mount.err.log</string>
</dict>
</plist>
EOF

plutil -lint "$PLIST" >/dev/null || die "generated plist is malformed"

UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
launchctl enable "gui/$UID_NUM/$LABEL"

# ------------------------------------------------------------- verification --
log "Kicking an immediate mount"
launchctl kickstart -k "gui/$UID_NUM/$LABEL"
sleep 6

echo
log "Verification"
mount | grep "$NUC_HOST" | sed 's/^/  /' || echo "  (nothing mounted — see ~/Library/Logs/ai-nuc-mount.log)"
echo
log "Mounted at:"
ls -d "$HOME"/AI-NUC/*/ 2>/dev/null | sed 's/^/  /' || echo "  (none)"
