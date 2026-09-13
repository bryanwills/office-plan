# Self-Hosted Honcho on ai-nuc

**Status:** running on ai-nuc as of 2026-09-13  
**API:** `http://127.0.0.1:8000` (healthy). Tailscale: `http://100.73.71.29:8000`  
**Data:** `/opt/stacks/honcho` → `/mnt/ai-data/stacks/honcho` on the `ai-data` disk  
**Inference:** host Ollama only. Deriver/summary/dream/dialectic = `qwen3.5:9b`. Embeddings = `nomic-embed-text` (768-d). No cloud key.

The earlier elkimek `setup.sh` path (clone into `~/honcho`, cloud embeddings) is **superseded**. We used the current [plastic-labs/honcho](https://github.com/plastic-labs/honcho) config format (`model_config` + `embedding.vector_dimensions`) and the `/opt/stacks` convention.

Overlay in this repo: `stacks/honcho/`. Deploy script: `scripts/ai-nuc/deploy-honcho.sh`.

---

## What is running

```
Hermes (Mac) ──Tailscale──► ai-nuc:8000  Honcho API
                                 │
                                 ├── PostgreSQL + pgvector   (127.0.0.1:5432, on ai-data)
                                 ├── Redis                   (127.0.0.1:6379, on ai-data)
                                 └── Deriver worker
                                         │
                                         └── host Ollama :11434
                                              ├── qwen3.5:9b          (every-message work)
                                              └── nomic-embed-text    (vectors)
```

| Service | Container | Notes |
|---|---|---|
| API | `honcho-api-1` | `0.0.0.0:8000`, `/health` → `{"status":"ok"}` |
| Deriver | `honcho-deriver-1` | Small model so it does not evict `qwen3.8:27b-hermes` |
| Database | `honcho-database-1` | pgvector/pg15, bind mount `./data/pgdata` |
| Redis | `honcho-redis-1` | bind mount `./data/redis` |
| MCP | not started | `docker compose --profile mcp up -d` publishes **8787**, never 3000 (OpenWebUI) |

Docker network: `ai-nuc`. Compose plugin lives at `~/.docker/cli-plugins/docker-compose` (the distro Docker package on this box has no compose).

---

## Why 9B for Honcho, 27B for Hermes

Honcho's Deriver runs on **every message**. If it loaded the 27B, it would kick Hermes off the 24 GB card. `qwen3.5:9b` (~6.6 GB) is the always-on memory worker. See [tokens, context, and picking a model](tokens-context-and-picking-a-model.md).

---

## Point Hermes on the MacBook at this instance

**Done 2026-09-13.** Mac dotfiles live under `~/.config`. The tracked file is:

```
~/.config/.honcho/config.json
```

Hermes itself does not read that XDG path. It looks at `~/.honcho/config.json` (after `$HERMES_HOME/honcho.json` and `~/.hermes/honcho.json`). The install script wrote the tracked file and pointed `~/.honcho` at it:

```bash
# already run on the Mac; re-run only if the pointer is missing
bash scripts/macbook/install-honcho-config.sh
```

That copies `stacks/honcho/hermes-config.json` (baseUrl `http://100.73.71.29:8000`) and runs `ln -sfn ~/.config/.honcho ~/.honcho` if `~/.honcho` is not already a real directory.

On ai-nuc itself, `~/.honcho/config.json` still points at `http://127.0.0.1:8000` (NUC-local, not part of the Mac dotfiles repo).

Model in Hermes stays `qwen3.8:27b-hermes`, context 64000. Honcho does not replace that. It is the filing cabinet, not the desk.

---

## Deploy / update

```bash
~/office-plan/scripts/ai-nuc/deploy-honcho.sh
```

First boot creates pgvector columns at 1536 (Honcho default). The script then runs `scripts/configure_embeddings.py --yes` so they match `nomic-embed-text` (768). Do not skip that if you rebuild the database from scratch.

```bash
cd /opt/stacks/honcho
docker compose ps
docker compose logs -f api deriver
curl -s http://127.0.0.1:8000/health
```

---

## Backup

```bash
mkdir -p /opt/backups/honcho
cd /opt/stacks/honcho
docker compose exec database pg_dump -U postgres postgres \
  > /opt/backups/honcho/honcho-$(date +%Y%m%d).sql
```

---

## What this is not

- Not Buzz. `buzz.bryanwills.dev` is a separate onboarding on the MacBook.
- Not OpenWebUI chat history. That still lives in the `open-webui` Docker volume until that stack is migrated.
- Not a 262k context window. Honcho stores observations on disk. The live window is still the GPU desk.

---

## Known limits

- Deriver quality is "good enough local 9B," not Plastic Labs' Neuromancer 8B. Observations will be less sharp. Data stays on the NUC.
- `USE_AUTH = false`. Port 8000 is on all interfaces. Keep this Tailscale/LAN only until auth is on.
- Ollama sees request content in the clear at inference time (function calling). Stored rows stay on `ai-data`.
