# Vaultwarden migration: Little Creek → netcup

Status as of 2026-08-30: Traefik + Vaultwarden compose files prepared and pushed to
netcup, `/opt/stacks` structure created, firewall opened for 80/443. Data has
**not yet** been copied and DNS has **not yet** been cut over — those are the
remaining, live-system-affecting steps below.

## Source (Little Creek)
- `sshl` → `bryanwi09@bryanwills.dev` (38.45.65.66)
- Data: `/home/bryanwi09/docker/vaultwarden` (19MB, sqlite3 + WAL — needs a clean
  container stop before copying for a consistent snapshot)
- Compose: `/home/bryanwi09/docker/vaultwarden/docker-compose.yml`

## Target (netcup)
- `sshn` → `bryan@152.53.82.233`
- Data: `/opt/stacks/vaultwarden/data`
- Compose: `/opt/stacks/vaultwarden/docker-compose.yml`
- Domain stays `vault.bryanwills.dev` (DNS not yet pointed here)

## Steps

1. **Stop Vaultwarden on Little Creek** (brief vault downtime, do this at a moment
   Bryan doesn't need password access):
   ```
   ssh -i ~/.ssh/littlecreek bryanwi09@bryanwills.dev "docker stop vaultwarden"
   ```
2. **rsync the data directory** to netcup:
   ```
   ssh -i ~/.ssh/littlecreek bryanwi09@bryanwills.dev \
     "tar -czf - -C /home/bryanwi09/docker/vaultwarden ." | \
   ssh -i ~/.ssh/macbook_nopasswd_netcup bryan@152.53.82.233 \
     "mkdir -p /opt/stacks/vaultwarden/data && tar -xzf - -C /opt/stacks/vaultwarden/data"
   ```
3. **Restart Vaultwarden on Little Creek** immediately (don't leave the source down
   longer than needed — it's still the production instance until DNS cuts over):
   ```
   ssh -i ~/.ssh/littlecreek bryanwi09@bryanwills.dev "docker start vaultwarden"
   ```
4. **Bring up Vaultwarden on netcup:**
   ```
   ssh -i ~/.ssh/macbook_nopasswd_netcup bryan@152.53.82.233 \
     "cd /opt/stacks/vaultwarden && docker compose up -d"
   ```
5. **Verify without touching DNS** — add a temporary entry to `/etc/hosts` on the
   Mac (`152.53.82.233 vault.bryanwills.dev`), load `https://vault.bryanwills.dev`,
   confirm cert issues (Traefik/Let's Encrypt) and login works with existing
   vault data. Remove the `/etc/hosts` line once confirmed.
6. **Cut DNS** (Squarespace): lower TTL to 300s, wait ~1hr, flip the `vault` A
   record to `152.53.82.233`, confirm resolution + Bitwarden extension
   reconnects, then restore TTL to 3600.
7. Once netcup is confirmed stable, decide whether to decommission Vaultwarden
   on Little Creek or leave it stopped as a fallback until the rest of the
   migration (Traefik-fronted sites, other stacks) completes.

## Open decision
Step 7 timing — how long to keep Little Creek's Vaultwarden as a cold fallback
before removing it — is not yet decided. Ask before deleting anything there.
