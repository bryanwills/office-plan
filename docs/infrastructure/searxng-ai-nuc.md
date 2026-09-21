# SearXNG on ai-nuc (Open WebUI web search)

**Date:** 2026-09-19  
**Where:** `/opt/stacks/searxng` — **NUC, not netcup.** Public SearXNG is an open proxy.

Listen: `127.0.0.1:8888` and `100.73.71.29:8888` only.  
JSON probe: `http://127.0.0.1:8888/search?q=test&format=json`

Open WebUI uses `SEARXNG_QUERY_URL=http://host.docker.internal:8888/search?q=<query>`.  
Admin → Settings → Web Search → engine `searxng`. Chat globe / web-search toggle.

Do not publish this on `bryanwills.dev`. Search queries leave the house to Google/Bing/etc.; the **aggregator** stays on-prem. Ring photos, address, customer data stay on the NUC models and never go through this path if you leave web search off for that chat.
