# AI-NUC as a mounted drive on the MacBook Pro (SMB over Tailscale)

**Status:** implemented 2026-09-12
**Scripts:** `scripts/ai-nuc/`, `scripts/macbook/`

Mounts the AI-NUC's ingest folder and `office-plan` working tree as Finder
volumes on the MacBook Pro, and runs a watcher on the NUC that auto-indexes
anything dropped into ingest.

---

## 1. Why SMB and not SSHFS

SSHFS was the original plan. It is not viable on this Mac:

| Blocker | Detail |
|---|---|
| Wrong architecture | `/usr/local/bin/sshfs` is an x86_64 binary left over from the Intel Mac. On arm64 it fails with `bad CPU type in executable`. |
| macFUSE needs a kext | `kmutil showloaded` shows no FUSE kext. Loading one on Apple Silicon requires booting to Recovery, enabling **Reduced Security**, allowing user-managed kernel extensions, and rebooting — with SIP weakened permanently. |
| Unmaintained | macFUSE-based sshfs has no maintained arm64 story and breaks on macOS point releases. |

SMB needs none of that: it is native to macOS, appears in the Finder sidebar with
an eject button, survives reboots, and **SIP stays enabled**.

NFSv4 was the runner-up — faster for many small files, but UID mapping is fiddlier
and it doesn't register as a Finder volume.

## 2. Addressing: use Tailscale, not the IP

`172.16.1.232` is **not static**. It is a DHCP lease on `wlan0` (WiFi). A mount
pinned to that address breaks the first time the lease moves.

The NUC runs Tailscale with a stable MagicDNS name. Scripts read it from
`~/.config/ai-nuc/env` (mode 600, **not** in git, because this repo is public):

```sh
NUC_HOST=<hostname>.<tailnet>.ts.net
NUC_USER=bryanwills
```

This also means the mount works off-network — coffee shop, office, anywhere the
tailnet reaches.

> Optional hardening: set a DHCP reservation for the NUC on the router so the LAN
> address stops moving too. The share is reachable on the LAN as a fallback.

## 3. What gets shared

| Share | Path on NUC | Purpose |
|---|---|---|
| `ai-nuc-ingest` | `~/ingest` | Drop folder. `inbox/` is watched; `processed/` and `failed/` are the watcher's output bins. |
| `ai-nuc-office-plan` | `~/office-plan` | The NUC's git working tree, for inspection and one-off file moves. |

Samba binds to **all interfaces** (`0.0.0.0:445`), including the docker
bridges — see §4a for why interface-scoped binding was abandoned. Client
access is enforced entirely by `hosts allow` (tailnet `100.64.0.0/10` + the
local subnet), `hosts deny = 0.0.0.0/0`, SMB3 minimum, and negotiated
encryption. Guest access is off (`map to guest = never`,
`restrict anonymous = 2`). Verified: a client on `docker0` completes a raw TCP
handshake but is refused at SMB protocol negotiation
(`NT_STATUS_INVALID_NETWORK_RESPONSE`) — same as any other disallowed subnet.

On the Mac, shares land at **`~/AI-NUC/<share>`**, not `/Volumes/<share>` —
see §4b for why.

### Do not sync the repo over the mount

Both machines have `office-plan` cloned from the same GitHub origin. **Git stays
the sync channel.** Two agents writing into one working tree over SMB is how you
get index corruption and half-written files. The `ai-nuc-office-plan` share is for
looking and for occasional deliberate file drops — not for editing the same file
from both sides.

The intended workflow for work done elsewhere: **drop the file into
`ai-nuc-ingest/inbox/`**, let the watcher index it, and let the NUC-side agent
place it into the repo and commit it.

## 4. Credentials

The SMB password is **separate from both Unix login passwords** and is never typed:

- On the NUC it lives in the Samba TDB (`smbpasswd`), not in `/etc/shadow`
  (`unix password sync = no`).
- On the Mac it lives in the login Keychain as an internet password for the
  tailnet host, pre-authorised for `NetAuthAgent` so Finder mounts silently.

To retrieve it later:

```sh
security find-internet-password -s "$NUC_HOST" -a bryanwills -w
```

To rotate it: run both installers again with a new `SMB_PASSWORD_FILE`.

## 4a. Bug hit #1 — Samba silently never listens on the Tailscale interface

The first working config used `interfaces = lo tailscale0 wlan0` with
`bind interfaces only = yes` (the textbook way to keep a service off the
docker bridges). It failed two different ways:

- **First attempt** (interface by name): smbd logged
  `smbd_open_one_socket: open_socket_in failed: Address family not supported
  by protocol` and came up listening on the LAN IP and loopback only — never
  the tailnet. Cause: Samba's interface auto-detection asks the kernel for a
  broadcast address per named interface, and `tailscale0` is a
  point-to-point `/32` (`NOARP`) link with none.
- **Second attempt** (explicit `100.x.x.x/32` instead of the interface name,
  to sidestep the broadcast lookup): smbd started with **no error logged at
  all**, `systemctl is-active smbd` said `active`, and it still never opened
  a socket on the tailscale IP (confirmed with `nc -zv` refused, run
  *locally on the NUC itself*). A healthy-looking service can still be
  silently unreachable — the log-then-trust-it check is not sufficient here.

**Fix:** stopped fighting interface-scoped binding entirely. `bind
interfaces only = no` binds `0.0.0.0:445` — every interface, docker bridges
included — and the actual security boundary moved to `hosts allow`/`hosts
deny`, which Samba evaluates per-connection during protocol negotiation,
independent of which local address received the packet. Verified with a
throwaway container attached to the `docker0` bridge: TCP connects, SMB
negotiation is refused. This is the standard, version-proof way to run
Samba behind Tailscale/WireGuard rather than relying on its interface
auto-detection.

## 4b. Bug hit #2 — the Finder mount path hangs forever, and /Volumes needs root

The first mount script used AppleScript's `mount volume "smb://..."`, which
routes through Finder's `NetAuthAgent` — the mechanism that's supposed to
read the Keychain entry silently and register a proper eject-button Finder
volume. On this machine it doesn't: it pops an interactive **"Connect to
Server"** credential dialog instead, every time — including from a
background LaunchAgent with no one there to answer it, where the call just
hangs indefinitely (confirmed hung even run directly, not only via launchd).
If you see that dialog, cancel it — the SMB password is a separate,
generated credential, **not** your NUC login password, and you should never
need to type either into it.

**Fix:** switched to `mount_smbfs` directly, which talks SMB without
involving NetAuthAgent at all. That surfaced a second, unrelated constraint:
`mount_smbfs` mounts onto an *existing* local directory — it doesn't create
one — and `/Volumes` is `root:wheel 0755`, so an unprivileged process can't
create an entry there (that directory-creation-with-elevated-privilege is
exactly what Finder's helper normally does behind the scenes). Rather than
require one-time `sudo` to pre-create and `chown` a `/Volumes` entry, shares
mount under **`~/AI-NUC/<share>`** — no privilege needed, still a normal
Finder-browsable folder, still fully read/write. The one thing it doesn't
get is the native network-volume eject icon in the sidebar; drag the folder
into Finder's sidebar once if you want a shortcut there (macOS removed the
`sfltool` API that used to script that step).

## 5. Install

### NUC (once, needs sudo)

```sh
scp scripts/ai-nuc/*.sh ai-nuc:~/nuc-share-setup/
ssh -t ai-nuc 'sudo SMB_PASSWORD_FILE=$HOME/.smb-setup-pw bash ~/nuc-share-setup/setup-nuc-share.sh'
shred -u ~/.smb-setup-pw   # on the NUC, afterwards
```

Installs `samba` + `inotify-tools`, writes `/etc/samba/smb.conf` (stock config
backed up to `smb.conf.orig` on first run), creates the ingest tree, sets the SMB
password, adds scoped `ufw` rules if ufw is active, installs the watcher as a
`systemd --user` service, and enables lingering so it runs without a login session.
Idempotent — safe to re-run.

### MacBook Pro (once, no sudo)

```sh
SMB_PASSWORD_FILE=/path/to/pw bash scripts/macbook/install-mac-mount.sh
```

Stores the Keychain entry, installs `~/bin/mount-ai-nuc.sh`, and loads the
LaunchAgent `com.bryanwills.ai-nuc-mount`, which mounts at login and re-checks
every 5 minutes. The re-check is what heals a mount after sleep/wake, a WiFi
change, or a NUC reboot.

The mount script bails in 5 seconds if port 445 is unreachable, so a login never
hangs waiting on an offline NUC.

## 6. The ingest watcher

`~/ai/scripts/ingest-watcher.sh`, run by `ingest-watcher.service`:

1. `inotifywait -m -r` on `~/ingest/inbox` for `close_write`, `moved_to`,
   `moved_from`, `delete`, `create`.
2. Filters SMB/macOS scaffolding — `.DS_Store`, `._*` AppleDouble files,
   `.smbdelete*`, `.TemporaryItems/`, `.Spotlight-V100/`, `*.part`, `*.crdownload`.
3. **Debounces.** One Finder copy fires dozens of events; everything within a 4
   second quiet window is coalesced into a single batch.
4. Hands the batch to `~/ai/scripts/index-ingest.sh`.

`index-ingest.sh` appends to `~/ai/ingest-manifest.jsonl` — one JSON object per
change with timestamp, path, sha256, size, and MIME type, plus tombstones for
deletions. **That manifest is the index right now**: an agent on the NUC can tail
it to learn what changed.

### Wiring up real embedding

`index-ingest.sh` has a marked `EMBED HOOK` block with two documented paths:

- **Open WebUI knowledge collection** — `POST /api/v1/files/` with a bearer token,
  which puts documents into the RAG store the chat UI already queries.
- **Direct Ollama embeddings** — `POST /api/embed` with `nomic-embed-text` into
  your own vector store.

Neither is enabled by default, because it needs an API key and a decision about
where vectors live.

## 7. Verification

```sh
# NUC
systemctl is-active smbd
systemctl --user is-active ingest-watcher.service
smbclient -L localhost -U bryanwills
ss -lntp | grep :445          # expect 0.0.0.0:445 — see §4a for why that's correct here

# Mac
mount | grep ts.net
ls ~/AI-NUC/
launchctl list | grep ai-nuc

# End to end
cp somefile.pdf ~/AI-NUC/ai-nuc-ingest/inbox/
ssh ai-nuc 'sleep 8; tail -3 ~/ai/ingest-manifest.jsonl'
```

Logs: `~/ai/logs/ingest-watcher.log` (NUC),
`~/Library/Logs/ai-nuc-mount.log` (Mac), `journalctl --user -u ingest-watcher -f`.

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Folder missing after wake | Mount went stale | Wait ≤5 min for the LaunchAgent, or run `~/bin/mount-ai-nuc.sh` |
| A "Connect to Server" dialog pops up | Something (Finder, a stray script) is using the AppleScript/NetAuthAgent path, not `mount_smbfs` | **Cancel it** — the SMB password is separate from your NUC login, and neither script needs it typed. See §4b. |
| `ss -lntp \| grep :445` shows only the LAN IP, tailnet is unreachable | Interface-scoped Samba binding silently dropped the tailnet socket | See §4a — fix is `bind interfaces only = no`, not re-adding `tailscale0` by name |
| `mount_smbfs: could not find mount point ... No such file or directory` | Mounting under `/Volumes` (root-owned, `0755`) as a normal user | Mount under `~/AI-NUC/<share>` instead — see §4b |
| `mount: Operation not permitted` | `hosts allow` excludes the client | Check the Mac's tailnet IP is inside `100.64.0.0/10` |
| Watcher sees nothing | Files dropped in `~/ingest`, not `~/ingest/inbox` | Only `inbox/` is watched |
| Watcher fires on junk | New macOS scaffolding filename | Extend `NOISE_RE` in `ingest-watcher.sh` |
| Very slow transfers | NUC is on **WiFi** (`wlan0`), ~65 ms tailnet RTT | Move the NUC to wired ethernet — biggest single win for many small files |
| `bad CPU type in executable` | Stale Intel sshfs | Not used any more; `brew uninstall macfuse` to clean up |

## 9. Known limitations

- The NUC is on WiFi. SMB over WiFi with ~65 ms RTT is fine for documents and
  poor for large trees of small files. Wired ethernet is the fix.
- `server smb encrypt = desired` costs CPU and is redundant inside the tailnet,
  but protects the LAN fallback path. Set to `off` if LAN access is dropped.
- The LAN fallback widens exposure to the whole local subnet at the `hosts
  allow` layer (smbd itself binds `0.0.0.0` regardless — see §4a). To go
  tailnet-only, drop the `$LAN_SUBNET` entry from `hosts allow` in
  `/etc/samba/smb.conf` and re-run `systemctl restart smbd`.
- Shares are plain folders under `~/AI-NUC/`, not native Finder network
  volumes — no eject button, no auto-listing in the sidebar. Drag the folder
  into the sidebar once if you want a shortcut (see §4b).
