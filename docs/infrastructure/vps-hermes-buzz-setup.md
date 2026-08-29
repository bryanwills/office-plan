# VPS Infrastructure Setup - Hermes & Buzz

## Current VPS Status (Netcup Gateway)

| Component | Status | Notes |
|-----------|--------|-------|
| **VPS** | ✅ Running | Ubuntu 26.04, 62GB RAM, 2TB storage |
| **Tailscale** | ✅ Connected | `gateway` (100.90.171.127) |
| **Hermes Agent** | ✅ Installed | v0.20.5, gateway running as systemd service |
| **Gmail MCP** | ⚠️ Needs API Enable | OAuth credentials exist, API disabled |
| **Ollama** | ✅ Running | `ornith:9b` (Qwen 3.5), `hermes3:latest` |
| **Docker** | ❌ Not Installed | Required for Buzz |
| **Buzz** | ✅ Cloned | `~/buzz` - ready for setup |

## Required User Actions

### 1. Enable Gmail API (Required for Email Checking)

Your Gmail MCP is configured but the Gmail API is not enabled on your Google Cloud project.

**Steps:**
1. Open: https://console.developers.google.com/apis/api/gmail.googleapis.com/overview?project=370216978185
2. Click **"Enable"**
3. Wait 2-5 minutes for propagation

**After enabling, test with:**
```bash
cd ~/.gmail-mcp && echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "search_emails", "arguments": {"query": "is:unread", "maxResults": 1}}, "id": 1}' | npx -y @gongrzhe/server-gmail-autoauth-mcp
```

### 2. Install Docker (Required for Buzz)

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker bryan
newgrp docker  # or log out and back in
```

**Verify:**
```bash
docker --version
docker compose version
```

### 3. Start Buzz Relay

Once Docker is installed:

```bash
cd ~/buzz/deploy/compose
cp .env.example .env
# Edit .env and set required values (especially secrets)
./run.sh start
```

For TLS with Let's Encrypt:
```bash
BUZZ_COMPOSE_TLS=true ./run.sh start
```

## Hermes Gateway Configuration

### Current Config (`~/.hermes/config.yaml`)

- **Model**: `ornith:9b` via Ollama (local)
- **Memory**: Enabled
- **Gateway Service**: Running (systemd)
- **Gmail MCP**: Enabled but needs API activation

### Gateway Management

```bash
# Check status
hermes gateway status

# Restart gateway
sudo systemctl --user restart hermes-gateway

# View logs
journalctl --user -u hermes-gateway.service -f
```

### Multi-Device Gateway Sync

Hermes gateway doesn't sync messages across devices, but provides continuity through:

1. **Shared memory** - Memory files persist on the gateway host
2. **Named sessions** - Use `/title` to name sessions, `/resume` to continue from any platform
3. **Background tasks** - `/background` for long-running tasks that persist results
4. **Shared workspace** - Artifacts land on gateway filesystem, accessible from any platform

To set up the same Hermes profile on MacBook Pro:
1. Copy `~/.hermes/.env` and `~/.hermes/config.yaml`
2. Run `hermes setup` on MacBook
3. Configure Gmail MCP with same OAuth credentials

## Buzz Architecture

Buzz is a Nostr-based workspace where humans and AI agents collaborate.

**Components:**
- **Relay** (Rust) - WebSocket + REST, Postgres, Redis
- **Desktop App** (Tauri + React)
- **buzz-cli** - Agent-first JSON CLI
- **Workflows** - YAML automation triggers

**Default Ports:**
- Relay WebSocket: `ws://localhost:3000`
- Postgres: 5432
- Redis: 6379
- MinIO (S3): 9000

## Next Steps After Setup

1. [ ] Enable Gmail API
2. [ ] Install Docker
3. [ ] Start Buzz relay
4. [ ] Generate Nostr keypair for Buzz identity
5. [ ] Configure IBKR paper trading bot
6. [ ] Set up Buzz-Hermes integration

---
*Last updated: August 22, 2026*
