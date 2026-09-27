# Open WebUI Google Drive (Ring photos, then other connectors)

**Status:** Compose ready on ai-nuc. Waiting on Google Cloud Client ID + API key.  
**Date:** 2026-09-19

Drive is a **picker in the Open WebUI that is already running on the NUC**, not a setting inside the Mac desktop app’s Ollama box. Open `http://100.73.71.29:3000` (Tailscale). The desktop app is a second Open WebUI and will not see these env vars.

## What you get

Chat → **+** → **Google Drive** → pick photos → they attach as context. Use a **vision** model or the model is blind.

Vision already on this box (name is long; pick it in the model menu):

```
hf.co/oktayd/Qwen3.6-35B-v2-MoE-Ablit-Heretic-Uncensor-Hermes-MTP-Vision-Ollama:Q4_K_M
```

`qwen3.8:27b-hermes` is text. It will not “see” Ring stills.

**Picker patch (2026-09-19):** stock Open WebUI hides folders and only lists PDF/Docs. `scripts/ai-nuc/patch-openwebui-drive-picker.sh` turns folder browse on and adds jpeg/png/webp/heic/mp4. Bind-mounted at `/opt/stacks/open-webui/patches/CS9gMiwt.js`. Re-run the script after an image pull. You still pick **files** inside folders (picking a folder would break the download). Use Chrome at `http://localhost:3000` + the SSH tunnel. Hard-refresh after a patch.

## You do this in Google Cloud (once)

Use a project you own. Testing mode is enough. Do not publish the app.

1. [Google Cloud Console](https://console.cloud.google.com/) → new or existing project.
2. **APIs & Services → Library**: enable **Google Drive API** and **Google Picker API**.
3. **OAuth consent screen**: External, User type. App name e.g. `ai-nuc-openwebui`. Add your Gmail under **Test users**.
4. **Credentials → Create credentials → OAuth client ID** → application type **Web application** (not Desktop, not Android).
   Google will **reject** `http://100.73.71.29:3000` (“must end with a public TLD”). Use localhost and an SSH tunnel, same idea as xrdp:
   - Authorized JavaScript origins (one row only; delete the empty URI 2):
     - `http://localhost:3000`
   - Authorized redirect URIs:
     - `http://localhost:3000`
     - `http://localhost:3000/oauth/google/callback`
   On the Mac (Tailscale on; no leftover Terminal):
   `bash scripts/macbook/owui-tunnel.sh start`
   Then open Open WebUI at `http://localhost:3000`, not the `100.` URL.
   Stop with `~/bin/owui-tunnel stop`. Details: [Open WebUI Mac tunnel](openwebui-mac-tunnel.md).
5. Copy the **Client ID** (looks like `….apps.googleusercontent.com`). Leave the client secret out of Open WebUI.
6. **Credentials → Create credentials → API key**. Restrict:
   - Application: **Websites**, add those same origins.
   - APIs: **Google Drive API** + **Google Picker API** only.

Paste both values into `/opt/stacks/open-webui/.env` on the NUC:

```
ENABLE_GOOGLE_DRIVE_INTEGRATION=true
GOOGLE_DRIVE_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_DRIVE_API_KEY=AIza...
GOOGLE_REDIRECT_URI=http://localhost:3000
```

Then:

```bash
cd /opt/stacks/open-webui
docker compose up -d
```

In Open WebUI: **Admin → Settings → Documents → Google Drive** = on.

First Drive click: Google sign-in as the test user. Then pick the Ring folder.

## Why the Mac desktop app cannot take the key

That app’s **Ollama** connection is only `http://100.73.71.29:11434`. Drive is not an API key on that screen. Drive credentials are environment variables on the Open WebUI **server**. Use the NUC UI.

If you later want Drive inside the desktop app itself, that copy needs its own Client ID origins for `http://localhost:8080` (or whatever port it binds). Do the NUC UI first.

## Other connectors (later)

| Connector | Where | Now? |
|---|---|---|
| Google Drive picker | this doc | in progress |
| OneDrive | same Documents admin, different env | later |
| Upload from disk | chat **+** | already works |
| MCP / extra tools | Open WebUI Tools + MCP | still the pending NUC stack item |
| Public `openwebui.bryanwills.dev` | Traefik template exists, not applied | later; would also need HTTPS origins in GCP |

Do not put Drive client secrets in this public repo.

## Workaround until GCP is filled in

Download the Ring stills to the Mac, open `http://100.73.71.29:3000`, **+** → upload, vision model, ask about the devices.
