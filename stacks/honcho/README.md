# Honcho stack (ai-nuc)

Stateful memory backend for Hermes. Lives on the `ai-data` disk:

```
/opt/stacks/honcho   →  /mnt/ai-data/stacks/honcho
```

Upstream clone: [plastic-labs/honcho](https://github.com/plastic-labs/honcho).  
This directory in `office-plan` is the **overlay** (compose, config, Hermes pointer). The clone itself is not committed.

## What runs

| Service | Port | Notes |
|---|---|---|
| `api` | `8000` on all interfaces | Hermes on the Mac uses `http://100.73.71.29:8000` over Tailscale |
| `deriver` | none | Extracts observations on every message via `qwen3.5:9b` |
| `database` | `127.0.0.1:5432` | pgvector, bind-mounted at `./data/pgdata` |
| `redis` | `127.0.0.1:6379` | bind-mounted at `./data/redis` |
| `mcp` | off by default | `docker compose --profile mcp up -d` publishes `8787` (not 3000) |

Embeddings: local `nomic-embed-text` (768-d) through host Ollama. No cloud key.

## Deploy / update

```bash
~/office-plan/scripts/ai-nuc/deploy-honcho.sh
```

## Hermes on the MacBook

```bash
mkdir -p ~/.honcho
# copy stacks/honcho/hermes-config.json from this repo
cp hermes-config.json ~/.honcho/config.json
# then start a new Hermes session
```

Do not point Hermes at `api.honcho.dev` if you want memory to stay on this disk.

## Backup

```bash
cd /opt/stacks/honcho
docker compose exec database pg_dump -U postgres postgres > /opt/backups/honcho/honcho-$(date +%Y%m%d).sql
```

## Why not the elkimek one-liner

`elkimek/honcho-self-hosted` installs into `~/honcho` and assumes a cloud embedding key. This overlay keeps `/opt/stacks`, local embeddings, and the current Honcho `model_config` format.
