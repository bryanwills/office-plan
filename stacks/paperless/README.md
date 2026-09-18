# Paperless-ngx (ai-nuc, Tailscale only)

**Status:** compose + deploy script ready; needs to run on ai-nuc  
**URL (private):** `http://ai-nuc.taild5c0d3.ts.net:8000`  
**Not on the public internet.** Bound to Tailscale IPv4 `100.73.71.29:8000` only.

## What it is

The document library for engineering binders, family recipes, and other scans.
Tesseract OCR is on by default. olmOCR is a later GPU batch hook, not this stack.

## Layout

| Path | Role |
|---|---|
| `/opt/stacks/paperless/` | compose + `.env` |
| `/mnt/ai-data/paperless/consume` | drop folder |
| `/mnt/ai-data/paperless/{data,media,export,pgdata,redis}` | stateful data |

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
