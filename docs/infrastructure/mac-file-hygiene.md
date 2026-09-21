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
bash scripts/macbook/mac-file-hygiene-plan.sh
```

The inventory only looks at the usual user folders. It does **not** list dotfiles, so the report can look “empty” even when `~/Library` is huge. That is on purpose.

The **plan** script is a dry-run of the **whole user folder**. It writes a TSV (`SECRET` / `MOVE` / `SKIP`) and **refuses `--execute`**.

- **SECRET** → you copy into `~/.keys/` (PEMs, nsec dumps, `*.bryanwills.dev` key files, Claude config backups). Then `export-keys-to-vault.sh` later. Hermes never moves these.
- **MOVE** → `Documents/inbox/...`, except tax/W-2/billing/contracts → `Documents/llc/records/`
- **SKIP** → dotfiles, `Library`, Applications, git repos, Photos / Photo Booth, iCloud MacBook copies, Movies/TV, Resolve, CyberLink, Drop Box, installers, plus names in `scripts/macbook/hygiene-force-skip.txt`

Do **not** commit the TSV or inventory. They list personal filenames. `.gitignore` covers `mac-file-hygiene-plan-*.tsv` and `mac-file-inventory-*.txt`. Do not upload the raw TSV to Open WebUI Knowledge.

### 2. You move secrets (not Hermes)

Copy every TSV `SECRET` row into `~/.keys/` yourself. Keep the filenames. Do not put `~/.keys` in git. Vault ingest is later (`~/export-keys-to-vault.sh`). Unseal Hashicorp yourself.

False positives already in `hygiene-force-skip.txt`: D&D `*tokens*` libraries, Password Safe `.deb`s, LAPS folders. SSH files named like `*macbook-pro` are keys, not iCloud copies — if the TSV SKIP’d them, copy those into `~/.keys/` by hand.

### 3. Hermes applies MOVE rows

Give Hermes `scripts/macbook/HERMES-HYGIENE.md`. One `--batch` per new session:

```bash
bash scripts/macbook/mac-file-hygiene-apply.sh --plan ~/Desktop/mac-file-hygiene-plan-YYYYMMDD.tsv
bash scripts/macbook/mac-file-hygiene-apply.sh --plan ~/Desktop/mac-file-hygiene-plan-YYYYMMDD.tsv --execute --batch home
```

Batches, in order: `home` → `desktop` → `documents` → `llc` → `movies` → `downloads`. Dry-run must look right before `--execute`. No `rm`. No overwrite. No secrets batch.

### 4. After a batch

Spot-check in Finder. Optionally start Time Machine. Next Hermes session, next `--batch`. When Downloads is drained, Paperless (`:8010`) for keepers. Ring photos stay in the Drive picker. Do not give Open WebUI a full-disk mount.

### 5. Optional Claude export (Knowledge, not Honcho)

ChatGPT zips import in Open WebUI Data Controls. Claude zips do not; treat them as Knowledge documents or convert first. Do not dump the same export into Honcho unless Hermes should own it.

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
