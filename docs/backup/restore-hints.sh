#!/usr/bin/env bash
# Print restore procedures for the latest backup set (does not mutate data).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config

cat <<EOF
========================================================================
 Restore cheat-sheet (new VPS / cold standby)
========================================================================
Backup root: $BACKUP_ROOT
Docker root: $DOCKER_ROOT

1) Provision new host
   - Install Docker + Compose plugin, git, rsync
   - Create user, join Tailscale (optional but recommended)
   - Clone or copy this docker repo compose files first

2) Copy backups onto the new host
   rsync -avh user@old-or-offsite:/path/to/backups/ ./backups/

3) Restore website docroots
   sudo mkdir -p /var/www
   sudo tar -xzf backups/websites/bigbraincoding.com_XXXX.tar.gz -C /var/www
   sudo tar -xzf backups/websites/bryanwills.dev_XXXX.tar.gz -C /var/www

4) Restore docker bind-mount data
   cd $DOCKER_ROOT
   # Prefer stopping stacks first on the TARGET host
   tar -xzf backups/daily/docker-data_XXXX.tar.gz
   tar -xzf backups/daily/extra-host-data_XXXX.tar.gz -C /

5) Restore named volumes (example: ollama)
   docker volume create ollama_ollama-models
   docker run --rm \\
     -v ollama_ollama-models:/volume \\
     -v \$PWD/backups/volumes/STAMP:/backup \\
     alpine:3.20 \\
     sh -c 'cd /volume && tar -xzf /backup/ollama_ollama-models.tar.gz'

6) Restore databases (logical dumps — preferred)
   gunzip -c backups/databases/STAMP/forgejo-db_forgejo.sql.gz \\
     | docker exec -i forgejo-db psql -U forgejo -d forgejo
   # Same pattern for linkwarden / docmost / affine
   # Vaultwarden / n8n: gunzip sqlite into the bind mount path, then start container

7) Bring stacks up in dependency order
   docker network create proxy   # if missing
   cd traefik && docker compose up -d
   cd ../nginx && docker compose up -d
   # then app stacks: vaultwarden, n8n, forgejo, ...

8) Hermes on LLC VPS
   # On Mac/Pi where config is real:
   hermes backup -o hermes-llc.zip
   # On new LLC VPS:
   hermes profile create llc && hermes profile use llc
   # Restore zip per Hermes docs / extract into ~/.hermes
   hermes gateway setup
   hermes gateway install   # or run

9) DNS / Traefik
   - Point A/AAAA records at new IP when cutover-ready
   - acme.json comes from docker-data archive (or let Traefik re-issue)

Latest local archives:
EOF

echo
echo "## daily"; ls -lt "$BACKUP_ROOT/daily" 2>/dev/null | head -8 || true
echo "## websites"; ls -lt "$BACKUP_ROOT/websites" 2>/dev/null | head -8 || true
echo "## databases"; ls -lt "$BACKUP_ROOT/databases" 2>/dev/null | head -8 || true
echo "## volumes"; ls -lt "$BACKUP_ROOT/volumes" 2>/dev/null | head -8 || true
echo "## hermes"; ls -lt "$BACKUP_ROOT/hermes" 2>/dev/null | head -8 || true
echo
echo "Full inventory files: $BACKUP_ROOT/manifests/"
