# AI-NUC Docker Stacks Setup

**Status:** 🔄 In Progress  
**Last Updated:** 2026-09-11  
**Host:** ai-nuc (MS-01, Ubuntu 24.04 Desktop → Server conversion planned)

---

## Overview

Standardizing Docker deployments on ai-nuc to match the `/opt/stacks/<name>/` convention used on netcup.

## Target Structure

```
/opt/stacks/
├── open-webui/
│   ├── docker-compose.yml
│   ├── .env
│   └── data/           # bind mount for persistent data
├── ollama/
│   └── (native install, not containerized)
├── buzz/
│   ├── docker-compose.yml
│   ├── .env
│   └── data/
├── hermes/
│   └── (native install, systemd service)
└── traefik/            # (optional, if adding reverse proxy)
    ├── docker-compose.yml
    ├── dynamic/
    └── acme.json

/opt/backups/
├── open-webui/
├── buzz/
└── ...
```

---

## Current State

| Service | Current Location | Target Location | Status |
|---------|------------------|-----------------|--------|
| open-webui | Docker volume `open-webui` | `/opt/stacks/open-webui/` | 🔄 Pending |
| ollama | `/usr/local/bin/ollama` (native) | Keep native | ✅ Done |
| buzz | Not installed | `/opt/stacks/buzz/` | ⏳ Planned |
| hermes | Not installed | Native + systemd | ⏳ Planned |

---

## Migration: open-webui

### Step 1: Create Directory Structure
```bash
sudo mkdir -p /opt/stacks/open-webui/data
sudo mkdir -p /opt/backups/open-webui
sudo chown -R $USER:docker /opt/stacks /opt/backups
```

### Step 2: Create docker-compose.yml
```yaml
# /opt/stacks/open-webui/docker-compose.yml
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    volumes:
      - ./data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
      - WEBUI_AUTH=true
      - WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Step 3: Create .env File
```bash
# /opt/stacks/open-webui/.env
WEBUI_SECRET_KEY=<generate with: openssl rand -hex 32>
```

### Step 4: Migrate Data
```bash
# Stop current container
docker stop open-webui

# Backup current data
sudo cp -a /var/lib/docker/volumes/open-webui/_data /opt/backups/open-webui/data-$(date +%Y%m%d)

# Copy to new location
sudo cp -a /var/lib/docker/volumes/open-webui/_data/* /opt/stacks/open-webui/data/

# Remove old container
docker rm open-webui

# Start with new compose
cd /opt/stacks/open-webui
docker compose up -d

# Verify
docker logs -f open-webui
```

### Step 5: Cleanup (after verification)
```bash
# Remove old volume (only after confirming new setup works)
docker volume rm open-webui
```

---

## New Stack: Buzz

### Prerequisites
- Docker with compose plugin
- Access to buzz.bryanwills.dev relay (netcup) OR local deployment

### Option A: Connect to Existing Relay (netcup)
No local Buzz container needed — use `buzz-cli` to connect to `wss://buzz.bryanwills.dev`.

### Option B: Local Relay (Development)
```bash
# Clone
cd /opt/stacks
git clone https://github.com/block/buzz.git buzz
cd buzz/deploy/compose

# Configure
cp .env.example .env
# Edit .env with secrets

# Start
docker compose up -d
```

---

## New Service: Hermes Agent

### Installation
```bash
# Install via curl (NOT pip)
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes/main/install.sh | bash

# Configure
hermes setup

# Enable gateway mode
hermes gateway start
```

### Systemd Service
```ini
# /etc/systemd/system/hermes-gateway.service
[Unit]
Description=Hermes AI Gateway
After=network-online.target ollama.service
Wants=network-online.target

[Service]
Type=simple
User=bryanwills
ExecStart=/usr/local/bin/hermes gateway serve
Restart=always
RestartSec=5
Environment="OLLAMA_HOST=http://localhost:11434"

[Install]
WantedBy=multi-user.target
```

### Enable
```bash
sudo systemctl daemon-reload
sudo systemctl enable hermes-gateway
sudo systemctl start hermes-gateway
```

---

## Ubuntu Desktop → Server Conversion

See: [`ubuntu-desktop-to-server.md`](./ubuntu-desktop-to-server.md)

### Quick Summary
```bash
# Remove desktop packages (keep drivers!)
sudo apt remove --purge ubuntu-desktop gnome-shell gdm3
sudo apt autoremove

# Install server packages
sudo apt install ubuntu-server-minimal

# Set default target
sudo systemctl set-default multi-user.target

# Reboot
sudo reboot
```

**⚠️ IMPORTANT:** Before converting:
1. Document all driver versions
2. Backup `/etc/modprobe.d/`
3. Backup NVIDIA configuration
4. Test SSH access works

---

## Firewall Configuration

```bash
# Allow essential ports
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 3000/tcp    # Open WebUI
sudo ufw allow 11434/tcp   # Ollama API (if remote access needed)

# Enable
sudo ufw enable
```

---

## Backup Strategy

### Daily Backups
```bash
#!/bin/bash
# /opt/stacks/backup.sh
DATE=$(date +%Y%m%d)

for stack in /opt/stacks/*/; do
  name=$(basename "$stack")
  if [ -d "$stack/data" ]; then
    tar -czf "/opt/backups/$name/backup-$DATE.tar.gz" -C "$stack" data
  fi
done

# Keep last 7 days
find /opt/backups -name "backup-*.tar.gz" -mtime +7 -delete
```

### Cron
```bash
# Add to crontab
0 3 * * * /opt/stacks/backup.sh
```

---

## Related Documentation

- [netcup stacks README](./README.md) — Reference architecture
- [buzz/SETUP.md](./buzz/SETUP.md) — Buzz relay setup
- [vps-hermes-buzz-setup.md](../vps-hermes-buzz-setup.md) — Hermes on VPS

---

*Last updated: 2026-09-11*
