#!/bin/bash
#
# mount-ai-nuc.sh — Mount the AI-NUC SMB shares if they aren't already mounted.
#
# Invoked at login and every 5 minutes by the LaunchAgent
# com.bryanwills.ai-nuc-mount, and safe to run by hand at any time.
#
# Credentials are read from the login Keychain at run time (added by
# install-mac-mount.sh) and passed to mount_smbfs directly. They are never
# written to disk and are cleared from the shell as soon as the mount call
# returns.
#
# Why mount_smbfs directly, and why ~/AI-NUC and not /Volumes:
#
# 1. `open smb://...` / AppleScript `mount volume` hand the connection to
#    Finder's NetAuthAgent, which on this machine pops an interactive
#    "Connect to Server" credential dialog instead of reading the Keychain
#    entry silently — every time, including when invoked from a background
#    LaunchAgent with no one there to answer it, where it just hangs forever.
#    mount_smbfs talks SMB directly and never involves that dialog.
#
# 2. mount_smbfs mounts onto an *existing* local directory; unlike Finder's
#    path, it does not create one for you. /Volumes is root:wheel 0755, so an
#    unprivileged mount_smbfs can't create an entry there. A directory under
#    $HOME needs no elevated privilege at all, mounts identically, and shows
#    up in Finder like any other folder (drag it into the sidebar once if you
#    want a shortcut — macOS removed the API to script that step).

set -uo pipefail

# Host/user come from ~/.config/ai-nuc/env (gitignored, machine-local) so the
# tailnet DNS name never lands in this public repo.
[[ -r "$HOME/.config/ai-nuc/env" ]] && . "$HOME/.config/ai-nuc/env"
NUC_HOST="${NUC_HOST:-ai-nuc.example.ts.net}"
NUC_USER="${NUC_USER:-$(id -un)}"
SHARES=(ai-nuc-ingest ai-nuc-office-plan)
MOUNT_ROOT="$HOME/AI-NUC"
LOG="$HOME/Library/Logs/ai-nuc-mount.log"

mkdir -p "$(dirname "$LOG")"
log() { printf '%s %s\n' "$(date -Iseconds)" "$*" >> "$LOG"; }

# Trim the log so it can't grow without bound.
if [[ -f "$LOG" && $(stat -f%z "$LOG" 2>/dev/null || echo 0) -gt 1048576 ]]; then
  tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

# Don't hang a login for 75 seconds of TCP timeout when the NUC is off or the
# tailnet is down. 445 reachable within 5s or we bail.
if ! /usr/bin/nc -z -G 5 -w 5 "$NUC_HOST" 445 >/dev/null 2>&1; then
  log "skip: $NUC_HOST:445 unreachable"
  exit 0
fi

SMB_PASSWORD="$(/usr/bin/security find-internet-password -s "$NUC_HOST" -a "$NUC_USER" -w 2>/dev/null)"
if [[ -z "$SMB_PASSWORD" ]]; then
  log "FAILED: no Keychain entry for $NUC_USER@$NUC_HOST (re-run install-mac-mount.sh)"
  exit 0
fi

mkdir -p "$MOUNT_ROOT"
mounted=0 already=0 failed=0

for share in "${SHARES[@]}"; do
  mountpoint="$MOUNT_ROOT/$share"

  # Match on host+share regardless of mountpoint naming so re-runs don't stack.
  if mount | grep -q "@${NUC_HOST}/${share} on "; then
    ((already++))
    continue
  fi

  mkdir -p "$mountpoint"

  # -N: don't fall back to an interactive/nsmb.conf prompt; the URL already
  # carries the password.
  if /sbin/mount_smbfs -N "//${NUC_USER}:${SMB_PASSWORD}@${NUC_HOST}/${share}" "$mountpoint" >/dev/null 2>>"$LOG"; then
    log "mounted $share at $mountpoint"
    ((mounted++))
  else
    log "FAILED to mount $share at $mountpoint"
    rmdir "$mountpoint" 2>/dev/null
    ((failed++))
  fi
done

unset SMB_PASSWORD
log "summary: mounted=$mounted already=$already failed=$failed"
exit 0
