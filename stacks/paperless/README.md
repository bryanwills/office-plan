# Paperless-ngx (ai-nuc, Tailscale only)

**Status:** running on ai-nuc as of 2026-09-17 (healthy).  
**URL (private):** `http://ai-nuc.taild5c0d3.ts.net:8010`  
**Not on the public internet.** Bound to Tailscale IPv4 `100.73.71.29:8010` only (Honcho already owns `:8000`).

## What it is

The document library for engineering binders, family recipes, and other scans.
Tesseract OCR is on by default. olmOCR is a later GPU batch hook, not this stack.

## Layout

| Path | Role |
|---|---|
| `/opt/stacks/paperless/` | compose + `.env` + data/media/consume/pgdata/redis (on `ai-data` via the stacks symlink) |

**Consume folder:** `/opt/stacks/paperless/consume`

## Deploy (on ai-nuc)

```bash
cd ~/office-plan   # or the NUC clone path
git pull
bash scripts/ai-nuc/deploy-paperless.sh
```

Admin credentials are generated into `/opt/stacks/paperless/.env` (mode 600).

## Gateway SSH

netcup `gateway` needs its public key in `~/.ssh/authorized_keys` on ai-nuc
before agents on the VPS can deploy this themselves. Key comment:
`bryan@gateway-to-ai-nuc`.
