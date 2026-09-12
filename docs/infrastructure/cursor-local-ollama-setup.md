# Cursor IDE — Local Ollama Model Configuration

**Status:** ✅ Ready to configure  
**Last Updated:** 2026-09-11  
**Platform:** ai-nuc (MS-01) running Ollama with RTX 3090 Ti

---

## Overview

Configure Cursor IDE to use your local Ollama instance (qwen3.8:27b) instead of cloud-hosted models for code generation and chat.

## Prerequisites

- ✅ Ollama running on `localhost:11434`
- ✅ qwen3.8:27b model loaded (17GB, Q4_K_M quantization)
- ✅ GPU acceleration working (RTX 3090 Ti, 24GB VRAM)

## Cursor Configuration

### Method 1: OpenAI-Compatible API (Recommended)

Cursor supports OpenAI-compatible endpoints. Ollama provides this at `/v1/`.

**In Cursor Settings → Models:**

1. Open Cursor Settings (Cmd/Ctrl + ,)
2. Navigate to **Models** section
3. Click **Add Model** or configure **Custom Model**
4. Set:
   - **API Base URL:** `http://localhost:11434/v1`
   - **Model Name:** `qwen3.8:27b`
   - **API Key:** `ollama` (any non-empty string works)

### Method 2: Via Environment Variable

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export OLLAMA_HOST="http://localhost:11434"
```

### Method 3: Cursor MCP Integration

If Cursor supports MCP (Model Context Protocol), you can configure Ollama as an MCP server.

**~/.cursor/mcp.json** (create if doesn't exist):
```json
{
  "servers": {
    "ollama-local": {
      "command": "curl",
      "args": ["-s", "http://localhost:11434/api/generate"],
      "env": {}
    }
  }
}
```

*Note: Native MCP support for Ollama may require additional tooling.*

---

## Available Models

| Model | Size | Context | Capabilities | Use Case |
|-------|------|---------|--------------|----------|
| `qwen3.8:27b` | 17GB | 262K | completion, tools, thinking, vision | Primary coding assistant |
| `llama3.2:3b` | 2GB | 131K | completion, tools | Fast drafts, simple tasks |
| `hf.co/HauhauCS/Qwen3.6-35B-*` | 22GB | 262K | completion, vision | Large context work |
| `hf.co/empero-ai/Qwythos-9B-*` | 6.5GB | 1M | completion, vision | Ultra-long context |

---

## Testing the Connection

### From Terminal
```bash
# Test Ollama API
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3.8:27b",
  "prompt": "Write a Python function to reverse a string",
  "stream": false
}' | jq .response

# Test OpenAI-compatible endpoint
curl http://localhost:11434/v1/chat/completions -d '{
  "model": "qwen3.8:27b",
  "messages": [{"role": "user", "content": "Hello"}]
}' | jq .choices[0].message.content
```

### From Cursor
1. Open a new file
2. Use Cmd+K (inline edit) or Cmd+L (chat)
3. Ask a coding question
4. Verify response comes from local model (check Ollama logs)

---

## Performance Expectations

| Metric | Value | Notes |
|--------|-------|-------|
| **Tokens/sec (eval)** | 25-45 tok/s | Depends on prompt length |
| **Context window** | 262,144 tokens | Full codebase context |
| **VRAM usage** | ~18-20GB | Leaves headroom for other tasks |
| **First token latency** | 500ms-2s | Cold start longer |

---

## Monitoring

### Check GPU Usage
```bash
watch -n 1 nvidia-smi
```

### Check Ollama Logs
```bash
journalctl -u ollama -f
```

### Check Loaded Models
```bash
ollama ps
```

---

## Troubleshooting

### Model Not Responding
```bash
# Restart Ollama
sudo systemctl restart ollama

# Verify GPU detection
journalctl -u ollama | grep -i "gpu\|cuda"
```

### Slow Performance
- Check if model is loaded: `ollama ps`
- Check VRAM: `nvidia-smi`
- Reduce context if hitting limits

### Connection Refused
```bash
# Check Ollama is listening
ss -tlnp | grep 11434

# Check service status
systemctl status ollama
```

---

## Network Access (for Remote Cursor Clients)

If you want to use this Ollama instance from another machine (e.g., MacBook Pro):

### 1. Update Ollama Service
Edit `/etc/systemd/system/ollama.service.d/network.conf`:
```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
```

### 2. Reload and Restart
```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### 3. Firewall (if needed)
```bash
sudo ufw allow 11434/tcp
```

### 4. Connect from Remote Cursor
Use the NUC's IP or Tailscale address:
- **API Base URL:** `http://ai-nuc:11434/v1`
- Or via Tailscale: `http://100.x.x.x:11434/v1`

---

## Related Documentation

- [`ai-rig-build-log.md`](./eGPU/ai-rig-build-log.md) — Hardware setup
- [`oculink-thunderbolt-setup.md`](./eGPU/oculink-thunderbolt-setup.md) — eGPU configuration

---

*Last updated: 2026-09-11*
