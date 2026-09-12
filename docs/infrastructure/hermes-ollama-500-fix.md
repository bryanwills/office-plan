# Hermes + Ollama HTTP 500 — "no user query found in messages"

**Status:** Diagnosed 2026-09-12 on ai-nuc  
**Symptom:** Open Cowork / plain Ollama chat works. Hermes queries fail with HTTP 500.

---

## What it is (and is not)

This is **not** Tailscale, UFW, or a missing API key. The NUC received the Hermes request and rejected the **message shape**.

Confirmed in `journalctl -u ollama` at 2026-09-12 04:17:

```
level=ERROR source=routes.go:2706 msg="chat prompt error" error="no user query found in messages"
```

Hermes (agent harness) sends a tool-loop continuation after the first tool call. Typical shape:

```
[system, assistant(tool_calls), tool(result)]
```

or a user turn whose `content` is `[]` (empty list).

`qwen3.8:27b` uses `RENDERER qwen3.8`. That renderer’s `validateMessages()` requires a plain user message that is **not** a `<tool_response>` wrapper. Same weights with `RENDERER qwen3.5` accept the request.

Upstream:

- [ollama#17778](https://github.com/ollama/ollama/issues/17778) — qwen3.8 renderer rejects tool-loop continuations
- [ollama#18107](https://github.com/ollama/ollama/issues/18107) — context truncation can also drop the user turn and produce the same 500

A second, related failure: Hermes reports the model’s **max** context (262144) from `/api/show`, but Ollama’s default runtime window is often 4096. Truncation then drops the user message. Hermes docs say set context length to **64000** and match `num_ctx` on the server.

---

## Fix on ai-nuc (done)

Created a same-weights alias:

| Name | Renderer | `num_ctx` | Purpose |
|------|----------|-----------|---------|
| `qwen3.8:27b` | qwen3.8 | default | Chat / Open Cowork |
| `qwen3.8:27b-hermes` | qwen3.5 | 65536 | Hermes agent tool loops |

Modelfile: `scripts/Modelfile.qwen3.8-27b-hermes`

```bash
ollama create qwen3.8:27b-hermes -f ~/office-plan/scripts/Modelfile.qwen3.8-27b-hermes
```

Does not re-download the 17GB weights. Disk cost is a small extra manifest.

---

## What to change in Hermes (MacBook / wherever Hermes runs)

1. Model name: `qwen3.8:27b-hermes` (not `qwen3.8:27b`)
2. Endpoint can stay `http://100.73.71.29:11434/v1`
3. Context length: **64000** (Hermes minimum; matches the alias `num_ctx`)
4. API key: any non-empty string (`ollama` is fine)

CLI equivalent:

```bash
hermes model
# Custom endpoint: http://100.73.71.29:11434/v1
# Model: qwen3.8:27b-hermes
# Context length: 64000
```

Or in `~/.hermes/config.yaml`:

```yaml
model: qwen3.8:27b-hermes
provider: custom
base_url: http://100.73.71.29:11434/v1
context_length: 64000
```

Start a **new** Hermes session after the switch. An old session still holds the failing transcript.

---

## Verify

On ai-nuc:

```bash
# Stock model fails this Hermes-like tool continuation
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:11434/api/chat -d '{
  "model":"qwen3.8:27b","stream":false,
  "messages":[
    {"role":"assistant","content":"","tool_calls":[{"function":{"name":"web_search","arguments":{"q":"ollama"}}}]},
    {"role":"tool","tool_name":"web_search","content":"{\"results\":[]}"}
  ]
}'

# Alias should return HTTP 200
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:11434/api/chat -d '{
  "model":"qwen3.8:27b-hermes","stream":false,
  "messages":[
    {"role":"assistant","content":"","tool_calls":[{"function":{"name":"web_search","arguments":{"q":"ollama"}}}]},
    {"role":"tool","tool_name":"web_search","content":"{\"results\":[]}"}
  ]
}'
```

From Hermes: send a short query that would use a tool (`check unread email`, `list files`). Expect a reply, not the 500.

---

## If it still 500s

1. Confirm Hermes is actually using `qwen3.8:27b-hermes` (`hermes config show`).
2. Confirm context is 64000, not 262144 or auto-detected max.
3. Check `journalctl -u ollama -n 30` on ai-nuc while sending the query.
4. Update Hermes — later builds sanitize empty `content: []` user turns ([hermes-agent#99234](https://github.com/NousResearch/hermes-agent/pull/99234)).

---

## Which models can hit this

The same HTTP 500 text comes from **two different failures**. Check both when you switch models.

### Cause A — `RENDERER qwen3.8` (model-family bug)

Ollama’s qwen3.8 renderer requires a plain user message that is not a `<tool_response>` wrapper. Hermes tool loops often send `[assistant(tool_calls), tool(result)]` with no user text. That 500s even when context is huge.

| Family / tag | Risk | Notes |
|--------------|------|-------|
| `qwen3.8:*` (27b, 4b, mlx, cloud, any size) | **Yes** | Confirmed. Includes `qwen3.8:27b` on this box |
| `qwen3.8:*-hermes` aliases with `RENDERER qwen3.5` | No | Same weights, different renderer |
| `qwen3.6:*` | No | Same request returns 200 ([#17778](https://github.com/ollama/ollama/issues/17778)) |
| `qwen3.5:*` | No | This is the renderer we switched to |
| Qwen3 MoE GGUFs that do **not** set `RENDERER qwen3.8` (your 35B-A3B) | Unlikely | Check with `ollama show MODEL --modelfile \| grep RENDERER` |
| Llama, Mistral, Gemma, DeepSeek, Phi, Command-R | No for Cause A | Different templates; no qwen3.8 `validateMessages` |

Future official `qwen3.8` pulls will come back with Cause A until Ollama relaxes that check (a later commit accepts user **or** tool turns; you are on 0.33.3, which still 500s).

### Cause B — context truncation (almost any model)

Ollama default live window is **4096** unless the Modelfile or `OLLAMA_CONTEXT_LENGTH` sets `num_ctx`. Hermes sends system + tool schemas + tool output (often 6k–36k tokens). Truncation can drop the user turn and keep the tool turn. Same 500.

Reported on models that are **not** qwen3.8:

| Model | Source |
|-------|--------|
| `qwen2.5-coder:14b` | [ollama#18107](https://github.com/ollama/ollama/issues/18107) |
| Any pull with no `PARAMETER num_ctx` | Same issue, their repro step 1 |
| `llama3.2:3b` (your box) | Cause A: no. Cause B: **yes** if you leave default 4096 |
| Qwythos 9B / Qwen3.6 35B on this box | Cause A: no. Cause B: **yes** without a 64k alias |

Hermes advertising 131k / 262k / 1M does not raise Ollama’s live `num_ctx`.

### Cause C — client message shape (any model)

Hermes (older builds) can send `user.content: []`. Ollama treats an empty list as “no user query.” A Hermes update that sanitizes that is [hermes-agent#99234](https://github.com/NousResearch/hermes-agent/pull/99234). Start a new session after `/model`.

---

## HuggingFace GGUFs (`hf.co/...` or `ollama pull hf.co/...`)

Ollama does **not** treat HF imports as a separate API. After import it still picks a template/renderer from GGUF metadata (`general.architecture`, chat template, family). The 500 is about **that assigned renderer + live `num_ctx`**, not about “official library vs HuggingFace.”

| What you pulled | Typical assignment | Hermes risk |
|-----------------|--------------------|-------------|
| Official `qwen3.8:27b` | `RENDERER qwen3.8` | Cause A + B |
| HF **Qwen3.8** GGUF (any quant, any uploader) | Often same qwen3.8 renderer if architecture is detected as 3.8 | **Cause A likely** |
| HF **Qwen3.6 / Qwen3.5** GGUF (your 35B-A3B, Qwythos 9B) | `qwen35` / `qwen35moe`, no `RENDERER qwen3.8` on this box | Cause A unlikely; **Cause B still yes** |
| HF Llama / Mistral / Gemma / DeepSeek GGUF | Their own template | Cause A no; **Cause B yes** |
| Fine-tunes that keep Qwen3.8 chat template in the GGUF | May still get qwen3.8 renderer | Treat as Cause A until the curl test says otherwise |
| Merges / “uncensored” / “claude-mythos” quants | Renderer follows **base architecture**, not the marketing name | Always inspect |

Your current HF models (checked 2026-09-12):

- `hf.co/empero-ai/Qwythos-9B-...` — architecture `qwen35`, no `RENDERER qwen3.8`
- `hf.co/HauhauCS/Qwen3.6-35B-A3B-...` — architecture `qwen35moe`, no `RENDERER qwen3.8`

Both can still 500 in Hermes if you leave Ollama’s default 4096 context.

After every HF pull:

```bash
ollama show hf.co/OWNER/REPO:QUANT --modelfile | grep -E '^(FROM |RENDERER |PARSER |PARAMETER num_ctx|TEMPLATE )'
```

If you see `RENDERER qwen3.8`, make a `-hermes` alias (`FROM` that HF tag, `RENDERER qwen3.5`, `PARAMETER num_ctx 65536`). If you do not see qwen3.8, still add `num_ctx 65536` before using it as a Hermes agent.

---

## Quick check before testing a new model

```bash
# 1. Renderer (Cause A)
ollama show MODEL --modelfile | grep -E '^(RENDERER|PARAMETER num_ctx)'

# 2. Hermes-shaped tool continuation (Cause A)
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:11434/api/chat -d "{
  \"model\":\"MODEL\",\"stream\":false,
  \"messages\":[
    {\"role\":\"assistant\",\"content\":\"\",\"tool_calls\":[{\"function\":{\"name\":\"web_search\",\"arguments\":{\"q\":\"test\"}}}]},
    {\"role\":\"tool\",\"tool_name\":\"web_search\",\"content\":\"{\\\"results\\\":[]}\"}
  ]
}"
```

- HTTP **500** + `no user query found` on that tiny payload → Cause A. Make a `-hermes` alias with `RENDERER qwen3.5`.
- HTTP **200** on that payload, but Hermes still 500s on a real query → Cause B. Add `PARAMETER num_ctx 65536` and set Hermes context to **64000**.

---

## Rule of thumb for Hermes testing

1. Never point Hermes at a stock `qwen3.8:*` tag. Use a `-hermes` alias.
2. Every model you use as an agent gets `num_ctx 65536` (or higher if VRAM allows) and Hermes context **64000**.
3. After `/model`, start a new session.
4. If a new Qwen 3.8-class model lands, run the curl above before trusting it in Hermes.

---

*Last updated: 2026-09-12*
