# Self-Hosted Honcho on ai-nuc — Setup Guide

## Why this file, not a hand-written docker-compose.yml

The self-hosted Honcho project (elkimek/honcho-self-hosted) ships its own
`docker-compose.yml`, `config.toml`, and `env.example`, layered on top of the
official `plastic-labs/honcho` repo. I don't have verbatim access to those
files' exact current contents, and fabricating a compose file by hand risks
drifting from what the maintainer actually ships (which is exactly the kind
of stale/incomplete-doc problem you've flagged before). So this guide uses
the project's real, documented install path and tells you exactly what to
change for your hardware, rather than reconstructing the compose file from
memory.

Source: https://github.com/elkimek/honcho-self-hosted
Upstream: https://github.com/plastic-labs/honcho

## Prerequisites (confirmed from the project docs)

- Ubuntu 22.04+ (ai-nuc is on 24.04 — fine)
- Docker Engine + Compose plugin (you already have this on ai-nuc)
- One cloud API key for embeddings only (see "Embeddings caveat" below) —
  OpenRouter is the simplest since it's already in your stack elsewhere

## 1. Install (one-command path)

```bash
curl -sL https://raw.githubusercontent.com/elkimek/honcho-self-hosted/main/setup.sh -o /tmp/setup.sh
bash /tmp/setup.sh
```

This clones both repos, copies the config files into place, prompts for
provider info, brings the stack up, and writes `~/.honcho/config.json` so
Hermes points at your local instance instead of `api.honcho.dev`.

When it asks how you want to run LLM inference, choose the **Local / LAN**
option and give it:

```
Server URL: http://localhost:11434/v1
```

(or `http://<ai-nuc-tailscale-ip>:11434/v1` if Hermes on MacBook Pro / ai-pi
will also point at this same Honcho instance remotely — see step 4).

## 2. What actually gets deployed

```
Hermes Agent ──► localhost:8000 (Honcho API, on ai-nuc)
                      │
                      ├── PostgreSQL + pgvector  (ai-nuc)
                      ├── Redis cache            (ai-nuc)
                      │
                      └── Deriver / Dialectic / Summary / Dream workers
                              │
                              ├── Primary: your Ollama on ai-nuc
                              └── Embeddings: cloud API (see below)
```

Files land at `~/honcho/` on ai-nuc (docker-compose.yml, config.toml, .env)
and `~/honcho-self-hosted/` (the config layer you cloned).

## 3. Model choice for ai-nuc's hardware specifically

The project's own guidance for reliable function-calling at self-hosted
scale:

| Model | Params | Ollama name | Fit for ai-nuc (RTX 3090 Ti, 24GB VRAM) |
|---|---|---|---|
| GLM-4.7 Flash | 30B MoE | `glm-4.7-flash` | Good fit — MoE architecture means active params per token are much smaller than 30B, should run comfortably alongside your other Ollama use |
| Llama 3.3 | 70B | `llama3.3:70b` | Needs ~40GB VRAM for a full GPU load — your single 3090 Ti (24GB) will offload to CPU/RAM, which will be slow for a "steady-state light tier" model |

Given your goal of a small, fast, always-on model for the Deriver (runs on
every message) plus a heavier model only for hard Dialectic queries and the
~8-hour Dream consolidation pass, **GLM-4.7-Flash for the light tier is the
better match** for your single-GPU setup. Pull it first:

```bash
ollama pull glm-4.7-flash
```

If you want a distinct heavier tier for Dialectic (max) and Dream, that's
where you'd reach for a cloud model via OpenRouter instead of trying to fit
a 70B model on one 24GB card — set that in `config.toml` per-component (the
project supports mixing providers per component, e.g. Ollama for Deriver,
OpenRouter for Dream).

## 4. Embeddings caveat (be aware of this, it's a real limitation)

Local Ollama generally can't serve embedding models well enough for Honcho's
semantic search. The project's own docs are direct about this: **you need a
cloud API key just for embeddings**, even in an otherwise fully local setup.
This is set in `.env` as `LLM_EMBEDDING_API_KEY` / `LLM_EMBEDDING_BASE_URL` /
`LLM_EMBEDDING_MODEL` (default `openai/text-embedding-3-small` via
OpenRouter). Everything else — the actual conversation/observation data —
still stays on ai-nuc; only the embedding *request content* passes through
that provider, not the stored memory itself. If that's not acceptable, you
can disable embeddings entirely and Honcho still works, just without vector
semantic search (keyword-only recall).

## 5. Point Hermes on MacBook Pro and ai-pi at this same instance

Right now each device's Hermes is siloed. To make ai-nuc's Honcho the shared
memory backend for all three:

- On MacBook Pro and ai-pi, edit `~/.honcho/config.json` to point at
  `http://<ai-nuc-tailscale-ip>:8000` instead of `localhost:8000`
- Since this traffic stays inside your tailnet, you do **not** need to
  expose Honcho's port 8000 publicly or put it behind the netcup VPS
  Traefik — keep it Tailscale-only, unlike OpenWebUI which needs a public
  bryanwills.dev subdomain

## 6. Backup — fold this into your existing pipeline

The project documents a straightforward Postgres dump:

```bash
cd ~/honcho
docker compose exec database pg_dump -U honcho honcho > backup.sql
```

Rather than a one-off manual step, wire this into the same nightly pattern
you already run for Oxidized/etckeeper (see your infra-config-backup setup):
cron this dump on ai-nuc, then push it to the same Forgejo/Azure DevOps
mirror you already use for config backups, so Honcho's memory data gets the
same versioned, redundant treatment as everything else.

## 7. Verify it's running

```bash
docker compose ps
curl -s http://localhost:8000/openapi.json | head -1
```

## Known limitation worth knowing up front

Honcho's agents use function calling, which is not compatible with
end-to-end encryption — the LLM provider (Ollama locally, or your cloud
embedding provider) sees request content in the clear at inference time,
even though stored data stays on ai-nuc. Since you're seeding this with
your neurodivergent-related context from the Claude export, that's worth
being deliberate about: local Ollama inference keeps that content off any
third party's servers entirely, which is the strongest argument for doing
the heavier lift of the local-model route rather than defaulting to a cloud
provider for the Deriver/Dialectic tiers too.
