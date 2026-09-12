#!/bin/bash
# Migrate open-webui from Docker volume to /opt/stacks/open-webui/
# Run as: sudo ./migrate-open-webui.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[migrate]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; exit 1; }

STACK_DIR="/opt/stacks/open-webui"
BACKUP_DIR="/opt/backups/open-webui"
COMPOSE_SRC="$HOME/office-plan/stacks/open-webui"
DATE=$(date +%Y%m%d_%H%M%S)

# Check running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    error "Please run with sudo"
fi

log "Starting open-webui migration..."

# Step 1: Create directories
log "Creating directory structure..."
mkdir -p "$STACK_DIR/data"
mkdir -p "$BACKUP_DIR"

# Step 2: Check if container is running
if docker ps --format '{{.Names}}' | grep -q '^open-webui$'; then
    log "Stopping open-webui container..."
    docker stop open-webui
fi

# Step 3: Backup current data
if docker volume inspect open-webui &>/dev/null; then
    log "Backing up current data..."
    VOLUME_PATH=$(docker volume inspect open-webui --format '{{.Mountpoint}}')
    cp -a "$VOLUME_PATH" "$BACKUP_DIR/data-$DATE"
    log "Backup saved to $BACKUP_DIR/data-$DATE"
    
    # Copy to new location
    log "Copying data to new location..."
    cp -a "$VOLUME_PATH"/* "$STACK_DIR/data/"
else
    warn "No existing volume found, starting fresh"
fi

# Step 4: Copy compose files
log "Copying compose files..."
cp "$COMPOSE_SRC/docker-compose.yml" "$STACK_DIR/"
cp "$COMPOSE_SRC/.env.example" "$STACK_DIR/"

# Step 5: Generate .env if not exists
if [ ! -f "$STACK_DIR/.env" ]; then
    log "Generating .env file..."
    SECRET=$(openssl rand -hex 32)
    echo "WEBUI_SECRET_KEY=$SECRET" > "$STACK_DIR/.env"
    chmod 600 "$STACK_DIR/.env"
fi

# Step 6: Set permissions
log "Setting permissions..."
chown -R root:docker "$STACK_DIR"
chmod -R 775 "$STACK_DIR"

# Step 7: Remove old container
if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
    log "Removing old container..."
    docker rm open-webui
fi

# Step 8: Start with new compose
log "Starting with new compose..."
cd "$STACK_DIR"
docker compose up -d

# Step 9: Wait and verify
log "Waiting for container to be healthy..."
sleep 10

if docker ps --format '{{.Names}} {{.Status}}' | grep -q 'open-webui.*healthy'; then
    log "✅ Migration complete! open-webui is healthy"
else
    warn "Container started but health check pending. Check with: docker logs open-webui"
fi

log "Stack location: $STACK_DIR"
log "Access at: http://localhost:3000"

# Reminder about cleanup
echo ""
warn "After verifying everything works, remove old volume with:"
echo "  docker volume rm open-webui"
