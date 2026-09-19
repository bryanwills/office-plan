# HTTPS name for Ollama: ollama.bryanwills.org

**Status:** DNS live (`ollama.bryanwills.org` → `152.53.82.233`). NUC Caddy gateway healthy on Tailscale `:8088`. Public HTTPS is **not** finished: Traefik answers with `CN=TRAEFIK DEFAULT CERT` and HTTP 404 until `ollama.yml` is on netcup.  
**Date:** 2026-09-18

## You were slightly wrong about `.dev`, and `.org` is still the right name

DNS is **per hostname**, not per domain.

`bryanwills.dev` (the apex) can stay on netcup forever. A subdomain can:

- share that same public IP (this is what `vault.bryanwills.dev` and `buzz.bryanwills.dev` already do), or
- point at a **different** public IP if you want.

So `ollama.bryanwills.dev → 152.53.82.233` would have been legal. It would not "move the website." It would be one extra A record.

You asked for **bryanwills.org**, and that is the cleaner split:

| Name | Public IP today | Role |
|---|---|---|
| `bryanwills.dev` / `www` / `vault` / `buzz` | `152.53.82.233` netcup | Sites and VPS apps |
| `bryanwills.org` / `www` / `ai` | `99.125.236.29` AT&T home | Leftover, no server |
| `ollama.bryanwills.org` | `152.53.82.233` netcup (set 2026-09-18) | HTTPS front door for Ollama |

The NUC never gets a public port. Home router port-forward is the wrong tool here.

## Why Squarespace gets the Netcup IP, not the AT&T IP

Squarespace is not picking Netcup. It is only the DNS panel (the phone book). When you add an A record you are publishing this sentence to the internet:

> When someone asks for `ollama.bryanwills.org`, send the TCP connection to this public IP.

That IP has to be the machine that already answers **public HTTPS on port 443** and can finish a Let's Encrypt challenge. That machine is **netcup** (`152.53.82.233`). Traefik is already listening there for `bryanwills.dev`, `vault`, `buzz`, and the rest.

The AT&T address (`99.125.236.29`) is the **home router**. If this name pointed there:

- Open Interpreter would knock on the house, not the VPS
- you would have to forward 443 to the NUC
- Ollama on the NUC has no auth, so that is a public GPU
- the AT&T address also moves

Netcup does not replace Tailscale. It is only the **front door**:

```
phone / Mac / Open Interpreter
        │
        │  public DNS: ollama.bryanwills.org → 152.53.82.233
        ▼
   netcup Traefik :443  (certificate, no port in the URL)
        │
        │  private Tailscale, not the AT&T WAN
        ▼
   ai-nuc :8088  (bearer key) → Ollama :11434
```

Write Netcup's number in the phone book so callers reach the receptionist. The receptionist already has a private line (Tailscale) to the NUC. Do not publish the house number.

`bryanwills.org` itself (`@` / `www`) can stay on AT&T. That is a different record. Only the `ollama` name points at Netcup.

## Why not CNAME to Tailscale MagicDNS

A public `CNAME ollama.bryanwills.org → ai-nuc.taild5c0d3.ts.net` does **not** give you a portless HTTPS API for Open Interpreter.

- Off-tailnet devices cannot reach `100.x` addresses.
- Let's Encrypt HTTP-01/TLS-ALPN on netcup will fail if the name does not land on netcup.
- You would still be talking to `:11434` unless something on 443 terminates TLS.

MagicDNS stays for admin (`tailscale ping ai-nuc`). Apps get a normal URL.

## Why not point `.org` at the home WAN and forward 443

That is what `bryanwills.org` already does (`99.125.236.29`). Problems:

- AT&T IP moves.
- Ollama on this box has **no auth** (`OLLAMA_HOST=0.0.0.0:11434`). A forwarded 443 is a public GPU.
- Same class of hole as Buzz's old `:3000` publish on netcup.

Do not do this.

## The path that matches the rest of this infra

```
open-interpreter  --HTTPS:443-->  ollama.bryanwills.org
                                      │
                                      │  netcup Traefik (Let's Encrypt)
                                      │
                                      └── Tailscale --> ai-nuc:8088 (Caddy bearer check)
                                                            └── 127.0.0.1:11434 Ollama
```

Same pattern as the OpenWebUI Traefik template: public TLS on the VPS, private hop to the NUC.

Clients use **no port**:

```
https://ollama.bryanwills.org/v1
```

Authorization header (required):

```
Authorization: Bearer <OLLAMA_PUBLIC_KEY>
```

Open Interpreter / OpenAI-compatible apps:

```bash
export OPENAI_BASE_URL=https://ollama.bryanwills.org/v1
export OPENAI_API_KEY='<same key as OLLAMA_PUBLIC_KEY>'
# model name, e.g. qwen3.8:27b
```

## Squarespace (bryanwills.org zone)

**Done 2026-09-18.** One record. `@` and `www` were left on the AT&T IP. `bryanwills.dev` was not touched.

| Type | Name | Value | Verified |
|---|---|---|---|
| A | `ollama` | `152.53.82.233` | `dig +short` returns this IP |

## What you do on netcup (`gateway`) — last step

ai-nuc has no SSH private key and Tailscale SSH to `gateway` waits on an interactive check. Run this **from the MacBook**:

```bash
cd /path/to/office-plan
git pull
bash scripts/macbook/apply-ollama-traefik.sh
```

That copies `docs/infrastructure/stacks/traefik/dynamic/ollama.yml` to `/opt/stacks/traefik/dynamic/ollama.yml` on netcup. Traefik's file provider has `watch=true`. Let's Encrypt uses TLS-ALPN on `:443` (same as the rest of this host).

Until that file lands, `https://ollama.bryanwills.org` presents Traefik's default self-signed cert and 404s. That is expected: DNS and the public IP are correct; the router is missing.

Confirm the cert resolver name is still `letsencrypt` (it is, in the checked-in Traefik compose).

## What is already on ai-nuc

Stack overlay: `stacks/ollama-gateway/`  
Runtime: `/opt/stacks/ollama-gateway`  
Listen: `100.73.71.29:8088` only (Tailscale).  
`/healthz` is open for Traefik. Everything else needs the bearer token.

```bash
cd /opt/stacks/ollama-gateway
# first time: openssl rand -hex 32  →  .env
docker compose up -d
curl -sS http://100.73.71.29:8088/healthz
```

Hermes and Honcho on the tailnet can keep using `http://100.73.71.29:11434/v1`. Do not move them onto the public name unless you want them to send the bearer key.

## Related

- [OpenWebUI Traefik template](openwebui-traefik-dynamic.yml) (same hop, different hostname)
- [netcup Traefik compose](stacks/traefik/docker-compose.yml)
- [cursor local Ollama](cursor-local-ollama-setup.md)
