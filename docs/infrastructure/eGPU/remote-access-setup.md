# Remote Access Setup — AI-NUC + RTX 3090 Ti

**Created:** 2026-09-08  
**Status:** ✅ Working

## Quick Reference

| Service | Port | URL |
|---------|------|-----|
| SSH | 22, 443 | `ssh bryanwills@YOUR_PUBLIC_IP -p 443` |
| Open WebUI | 3000 | `http://YOUR_PUBLIC_IP:3000` |
| Ollama API | 11434 | `http://YOUR_PUBLIC_IP:11434/v1` |

## Tested Tonight
- ✅ qwen3.8:27b loaded and responding
- ✅ Open WebUI accessible from public IP
- ✅ RTX 3090 Ti inference working over Thunderbolt
- ✅ Bedtime story generated successfully
