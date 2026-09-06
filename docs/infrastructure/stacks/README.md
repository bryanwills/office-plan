# netcup Docker stacks (as-deployed)

Canonical path on the server: `/opt/stacks/<name>/`. Backups:
`/opt/backups/<name>/`. Do not invent `/home/bryan/docker` or
`/home/bryanwi09/docker` for netcup.

Every stack on this host routes through Traefik's **file provider**
(`traefik/dynamic/*.yml`) over the shared `proxy` Docker network. Traefik's
Docker provider is disabled: Docker Engine 29.x and Traefik's bundled Docker
client do not agree on API versions. Copy that pattern for anything new.

Real secrets live in server-side `.env` files only. This repo may contain
`.env.example` templates and compose/config that is safe to publish.

| Stack | Role | Docs |
|---|---|---|
| Traefik | TLS + reverse proxy | [compose](traefik/docker-compose.yml), [dynamic](traefik/dynamic/) |
| Nginx + php-fpm | bryanwills.dev + bigbraincoding.com | [MIGRATION](nginx/MIGRATION.md) |
| Vaultwarden | Bitwarden-compatible vault | [MIGRATION](vaultwarden/MIGRATION.md) |
| Hashicorp Vault | secrets engine (`keys.bryanwills.dev`) | [MIGRATION](hashicorp/MIGRATION.md) |
| Buzz | agentic workspace (`buzz.bryanwills.dev`) | [SETUP](buzz/SETUP.md) |

Little Creek decommission timing for the stacks that already cut over is
**not decided**. Ask before deleting anything there.
