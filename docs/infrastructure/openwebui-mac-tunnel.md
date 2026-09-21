# Open WebUI localhost tunnel (no leftover Terminal)

**Date:** 2026-09-20  
**Run on the Mac.** Tailscale up. Do not reboot the NUC.

Open WebUI on ai-nuc listens on `127.0.0.1:3000` and `100.73.71.29:3000` only. A Google Drive sign-in still needs `http://localhost:3000`, so the Mac forwards that port over SSH. You do not need a Terminal window sitting open.

## Daily commands

From the office-plan clone on the Mac:

```bash
bash scripts/macbook/owui-tunnel.sh start
bash scripts/macbook/owui-tunnel.sh stop
bash scripts/macbook/owui-tunnel.sh status
```

First `start` copies the script to `~/bin/owui-tunnel` and loads a LaunchAgent (`com.bryanwills.owui-tunnel`). After that:

```bash
~/bin/owui-tunnel start
~/bin/owui-tunnel stop
~/bin/owui-tunnel status
```

`start` / `stop` are `launchctl bootstrap` / `bootout`. KeepAlive restarts ssh if the laptop sleeps and wakes. Logs: `~/Library/Logs/owui-tunnel.err.log`.

Optional: start the tunnel at login (still stoppable):

```bash
bash scripts/macbook/owui-tunnel.sh install --login
bash scripts/macbook/owui-tunnel.sh start
```

Remove it:

```bash
~/bin/owui-tunnel uninstall
```

## When you actually need this

| Goal | URL | Tunnel? |
|---|---|---|
| Chat, models, Knowledge import | `http://100.73.71.29:3000` | No. Tailscale is enough. |
| Google Drive picker / OAuth | `http://localhost:3000` | Yes. |
| Desktop app pointed at `localhost:3000` | `http://localhost:3000` | Yes, or change the app to the Tailscale URL. |

Quit the Open WebUI **desktop app** before `start` if it binds `:3000`. Two listeners on that port is how you get a Mac-side 500.

xrdp is a different tunnel (`scripts/macbook/tunnel-xrdp.sh`, port 3389).

## Check

```bash
~/bin/owui-tunnel status
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/
```

You want `200`. Then Chrome → `http://localhost:3000`.
