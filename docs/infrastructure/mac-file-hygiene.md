# Mac file hygiene with Open WebUI + Hermes (not a live NUC filesystem)

**Date:** 2026-09-20  
**Do not start this while Time Machine is still writing.**

Open WebUI runs **on the NUC**. A filesystem / terminal tool there sees `/` on ai-nuc, not the MacBook. Pointing that tool at your home folder would mean mounting the whole Mac onto the NUC and letting a model `mv` live files. Do not do that.

The split that matches this stack:

| Job | Where | Why |
|---|---|---|
| Chat desk, plan, RAG over exports | Open WebUI on the NUC | Already the local chat UI |
| Long-term Hermes memory | Honcho | Do not dump the same Claude zip here unless you want Hermes to own it |
| Infra continuity | `PROJECT_STATE.md` | Agents, not personal files |
| **Move / rename / delete Mac files** | **Hermes on the Mac** | Tools already run on that disk |
| Archive-worthy PDFs later | Paperless on Tailscale `:8010` | After you decide what to keep |

This is the same “one spine” rule as the [later tooling triage](../PROJECT_STATE.md) in `PROJECT_STATE.md` §8: one board, one memory, one chat desk. File moves are a fourth lane, and that lane is Hermes on the laptop.

## Gate 0 — Time Machine

Leave the backup alone. A mid-backup reorganize can snapshot a half-moved tree and make “yesterday” unrestorable.

1. Menu bar Time Machine → wait until it says the backup **finished**.
2. Only then run inventory or Hermes moves.
3. The inventory script is read-only. It is safe *during* a backup. Moves are not.

## Ready tools (install nothing extra tonight)

Already owned, use these:

- **Open WebUI** at `http://100.73.71.29:3000` (or `owui-tunnel start` + `http://localhost:3000` for Drive). Knowledge + Data Controls.
- **Hermes on the Mac** + `qwen3.8:27b-hermes` for file tools. New session per folder. Do not keep one immortal hygiene chat ([tokens / context](tokens-context-and-picking-a-model.md)).
- **Honcho** for Hermes facts you want to keep. Not a second Claude dump unless you choose that.
- **Paperless** (`:8010`) after you pick archive PDFs.
- **SearXNG** stays off for anything with addresses / customer / Ring data.
- **Read-only inventory:** `scripts/macbook/mac-file-inventory.sh`

Do **not** add for this project:

- An Open WebUI filesystem MCP aimed at Mac `$HOME`
- A second memory injector (claude-mem, agentmemory, graphify) — Honcho already owns Hermes memory
- Multica / Beads / Vibe Kanban — those are coding boards, not file tidy
- The broken imported Open WebUI tools that need `html2text` / `fitz` — not required for folder hygiene. Revisit only if you want in-chat PDF OCR later.

## Process

### 1. Inventory (read-only, Mac)

```bash
bash scripts/macbook/mac-file-inventory.sh
```

Default report: `~/Desktop/mac-file-inventory-YYYYMMDD.txt`. It lists sizes and counts. It skips `Library`, Trash, Time Machine locals, Photos library internals, `~/.ollama`, `~/.hermes`.

Upload that file to Open WebUI: **Workspace → Knowledge → New** (name it `mac-hygiene-2026-09`). That is the map the model should talk about. Not a live mount.

### 2. Import Claude “memory” the honest way

[Open WebUI Import / Export](https://github.com/open-webui/docs/blob/main/docs/features/chat-conversations/data-controls/import-export.md) auto-converts **ChatGPT** exports. It does **not** auto-convert Claude. A Claude zip is custom JSON; you reshape it, or you treat the export as documents.

Do both of these, they are different:

**A. Knowledge (what you actually need for hygiene)**  
Claude.ai → Settings → Privacy → Export data. Unzip on the Mac. In Open WebUI: **Workspace → Knowledge** → upload `conversations.json` plus any `projects/*.json` docs you care about. That is searchable context: “what did I tell Claude about Downloads / taxes / photos.”

Claude **Projects** are not chats. Rebuild a project as a Knowledge collection + a custom model with that project’s instructions pasted into the system prompt. The export does not keep project-to-chat links ([Jonathan Mann writeup](https://jonathanmann.tech/blog/migrate-claude-projects-open-webui/)).

**B. Chat history (optional, vanity / search in the sidebar)**  
Convert Claude JSON to Open WebUI’s message-tree, then **Settings → Data Controls → Import Chats**. Community converter: [yetanotherchris/openwebui-importer](https://github.com/yetanotherchris/openwebui-importer) `convert_claude.py`. Re-importing the same file duplicates chats.

Do **not** also pour that zip into Honcho in the same weekend unless you decide Hermes should recall it. Two copies = split brain. Default for this project: Open WebUI Knowledge only.

### 3. Plan in Open WebUI (still no moves)

New chat, attach the `mac-hygiene-2026-09` knowledge. Ask for a **folder-by-folder plan**, not a whole-disk rewrite. Hard rules to paste:

- Do not touch `~/Library`, hidden top-level dirs, Time Machine, Photos `.photoslibrary` internals, `~/.ssh`, password managers, `~/.ollama`, `~/.hermes`
- Propose `mkdir` + `mv` lists only. No `rm -rf`
- One top-level folder per plan (Downloads, then Desktop, then Documents)
- Call out iCloud / Desktop-and-Documents sync if those folders are cloud-backed
- Customer / address / Ring material stays local; no web search

You approve the list. The model does not execute from this chat.

### 4. Execute with Hermes on the Mac

New Hermes session. Paste **one** approved folder plan. Require confirmation before each batch. If the session gets weird, start another ([Hermes 500 / context](hermes-ollama-500-fix.md)).

After each folder: spot-check in Finder, then optionally start Time Machine again so you have a clean post-tidy snapshot.

### 5. Afterward

- PDFs you want archived → Paperless, not a random `Documents/archive` forever
- Ring / property photos stay in the Drive picker flow ([Google Drive](openwebui-google-drive.md)), not a second copy on the NUC unless you choose it
- Do not enable Open WebUI “full disk” tools later “to make this faster”

## Suggested folder spine (change if you already have one)

Keep it boring so the model cannot invent a new taxonomy every chat:

```
~/Documents/inbox          # unsorted, time-limited
~/Documents/llc            # formation, tax, office-plan exports
~/Documents/personal       # non-customer
~/Documents/archive        # cold, dated
~/Pictures/inbox
~/Downloads                # drain weekly into inbox, do not treat as storage
```

No “AI-sorted” folder names. No automatic delete.

## Tunnel reminder

Hygiene planning does **not** need `localhost`. Use Tailscale `http://100.73.71.29:3000`. Start the tunnel only for Drive: [Open WebUI Mac tunnel](openwebui-mac-tunnel.md).
