# Hermes Agent + Gmail MCP troubleshooting — 2026-08-30 evening session

Context: earlier the same day, the VaultWarden/Vault/Nginx/Traefik migration
to netcup was completed (see `docs/infrastructure/stacks/*/MIGRATION.md`) and
Buzz was newly deployed (see `docs/infrastructure/stacks/buzz/SETUP.md`). This
session picked up separately that evening to debug why Hermes's interactive
CLI on netcup couldn't reliably use its already-working Gmail MCP connection.

## Starting point
Netcup already had a `hermes-gateway` systemd service running (had been for
~1 week) with Gmail MCP authenticated and functional at the infrastructure
level — confirmed by directly invoking the Gmail MCP server standalone and
getting a real inbox result. The problem was specifically that Bryan's
**interactive** `hermes` CLI sessions couldn't reliably use that same Gmail
connection: sessions hung at "connecting," or the model answered without
ever calling a tool, or called the wrong tool entirely.

## Root causes found and fixed (all real bugs, not user error)

1. **Stale/zombie interactive sessions.** Cancelling out of an interactive
   `hermes` session does not actually terminate the process — it stays alive
   in the background (confirmed repeatedly via `ps -ef --forest` showing the
   same PID persisting across "new" attempts). These pile up over days and
   can contend with each other. **Workaround, not yet fixed upstream:** find
   and `kill -9` the PID tree
   (`hermes` → `mcp_stdio_watchdog.py` → `npx`/`gmail-mcp` children) before
   each fresh attempt.

2. **`tools.tool_search` deferral hid every Gmail tool from the model.**
   Hermes has a context-budget feature that defers (hides) tool schemas that
   don't fit a token budget, requiring the model to explicitly search for
   them. All 19 Gmail tools were being deferred every session. **Fixed**:
   added to `~/.hermes/config.yaml` on netcup:
   ```yaml
   tools:
     tool_search: false
   ```

3. **`hermes3:latest` (Nous Research's Hermes 3, a Llama-3 fine-tune —
   coincidentally same name as the Hermes Agent CLI tool, completely
   unrelated project) doesn't support the "thinking"/reasoning-effort mode**
   Hermes's config was requesting (`agent.reasoning_effort: medium`), and
   errored outright (`HTTP 400: "hermes3:latest" does not support
   thinking`). **Fixed**: set `agent.reasoning_effort: none` in config.yaml.
   Hermes's own source code (`agent/agent_init.py`) has a built-in warning
   for this exact model family: *"Nous Research Hermes 3 & 4 models are NOT
   agentic — they lack reliable tool-calling for agent workflows... Consider
   an agentic model instead (Claude, GPT, Gemini, Qwen-Coder, etc.)."*

4. **Hermes enforces a hard minimum 64,000-token context window.**
   `qwen2.5:7b-instruct` (tried as an alternative model) only has a native
   32,768-token architecture — this is baked into the model's training, not
   something any Ollama setting can override. `OLLAMA_CONTEXT_LENGTH` only
   sets the *default runtime allocation up to the model's real max* — it
   cannot extend a model past its actual trained context. Confirmed via
   Ollama's `/api/show` reporting `qwen2.context_length: 32768` even after
   setting `OLLAMA_CONTEXT_LENGTH=65536` server-wide. **Resolution**: picked
   a model that already has enough native context instead — `ornith:9b`
   (Qwen3.5 family) natively supports 262,144 tokens, comfortably clearing
   the 64K floor.

5. **Bare `search_files`/local file tools were sometimes chosen over Gmail
   tools even when visible.** This wasn't fixable via config — it's a real
   model-capability limitation (small quantized local models being
   unreliable at tool selection), matching the built-in Hermes warning
   above. **Resolution**: after all four fixes above, a clean session with
   `ornith:9b` correctly called `mcp__gmail__list_email_labels` then
   `mcp__gmail__search_emails` and produced a real, data-grounded answer
   (though it briefly also tried an unrelated `computer_use` action mid-turn
   before recovering — still not perfectly reliable, just meaningfully
   better).

## Current netcup Hermes config state (as of 2026-08-30 night)
- Model: `ornith:9b` (`~/.hermes/config.yaml` `model.default` and the two
  other places the model name is set — `providers.ollama-launch.default_model`
  and `custom_providers[0].model`)
- `tools.tool_search: false`
- `agent.reasoning_effort: none`
- `model.context_length: 65536` (harmless override left over from testing
  `qwen2.5:7b-instruct` — caps ornith's native 262K down to 65536, still well
  above the 64K floor, no need to remove but safe to if it's ever confusing)
- `qwen2.5:7b-instruct` was pulled to the box (4.7GB) but is no longer the
  default — left installed in case it's useful later for something within
  its 32K context budget
- Ollama systemd unit (`/etc/systemd/system/ollama.service`) now has
  `Environment="OLLAMA_CONTEXT_LENGTH=65536"` added — harmless, doesn't hurt
  anything, but doesn't meaningfully help either given point 4 above

## Honest assessment / what's still true
CPU-only local inference on this VPS (no GPU) is genuinely slow — 40 seconds
to 5+ minutes per turn depending on prompt size, worse as tool schemas and
conversation history accumulate (a request with the full Gmail tool list
loaded runs ~16-18K input tokens). Tool-selection reliability with 8-9B
local models is a real, acknowledged-by-the-tool's-own-maintainers
limitation, not something fully solvable by more config tuning. If Bryan
wants consistently reliable agentic Gmail interaction (not just "sometimes
works after enough retries"), the actual fix is a more capable model —
either a bigger local model (slower, still free) or a hosted frontier model
(faster and more reliable, but costs money — explicitly ruled out for this
use case tonight: *"I do not want to use anything that requires me to pay
for it... this will be ongoing and it will require a lot of traffic."*)

## Not yet explored (possible future directions)
- Bryan's MacBook Pro already has its own separate `~/.hermes` install,
  defaulting to `qwen3.8:27b` with several `ollama :cloud`-suffixed model
  options (`deepseek-v4-flash:cloud`, `minimax-m3:cloud`, `gemma4:cloud`,
  `kimi-k2.7-code:cloud`, `glm-5.2:cloud`). These route inference to
  Ollama's own cloud infrastructure rather than local compute — worth
  checking whether Ollama's free tier covers this (no local Ollama account
  sign-in was found configured yet) before assuming it's free; if it is,
  cloud models are likely both faster (no local CPU bottleneck) and more
  capable than anything that fits on this VPS's CPU.
- ai-pi (Raspberry Pi) has its own `~/.hermes` config too, but no active
  `hermes-gateway` systemd service was running there during this session —
  its actual reliability was never verified live, despite being assumed
  "known good" at the start of the session. Worth testing directly before
  relying on it as a reference implementation.
- Replicating the Mac's local Hermes setup with Safari for OAuth approval
  flows (instead of Chrome) was discussed as a parallel path — feasible in
  principle (copy the printed login URL from the terminal into Safari
  manually), not yet executed.

## Gmail cleanup scripts (the actual concrete win from tonight)
Given the demonstrated LLM tool-calling unreliability above, the Gmail
inbox backlog cleanup Bryan actually wanted was deliberately built as
**deterministic scripts, not an LLM-driven cron job** — see
`docs/infrastructure/scripts/README.md` for full details. Summary:
- `gmail-backlog-cleanup.py`: trashed 2,037 unread Honey/SlickDeals emails
  (July 3 → today).
- `gmail-github-mark-read.py`: marked 188 unread GitHub notification emails
  as read, left in inbox.
- Both are one-time tools (re-run manually if backlog piles up again), not
  persistent Gmail filters/rules — Bryan explicitly doesn't use Gmail's
  filter/label feature.

## Suggested future cleanup batches (not yet built — ideas for later)
Same domain-based, dry-run-first pattern as the two scripts above could be
reused for other senders once Bryan identifies them as high-volume/low-value
in his inbox. Candidates worth considering, in roughly the order they're
likely to matter:
1. **Other deal/coupon sites** if Bryan subscribes to any beyond
   Honey/SlickDeals (e.g. RetailMeNot, Rakuten, Groupon) — same trash
   treatment as the Honey/SlickDeals script, just add their sending domains.
2. **Gmail's built-in `category:promotions` search** as a first-pass
   discovery query — run a dry-run-only report (no action) grouping by
   sender domain, to see which promotional senders are actually piling up
   before deciding trash-vs-keep per sender. This avoids guessing at senders
   Bryan hasn't mentioned yet.
3. **Other "mark read, keep" candidates** similar to GitHub — other
   notification-heavy services Bryan wants to skim later rather than delete
   (LinkedIn, X/Twitter, other dev-tool notifications, Substack newsletters
   he's subscribed to but hasn't read). Same script pattern as
   `gmail-github-mark-read.py`, just swap the sender domain.
4. **The Linkwarden auto-save feature** (see
   `docs/infrastructure/scripts/README.md`) for GitHub Explore digest repo
   links — the one actual new capability requested tonight that wasn't
   built, since it needs email-body HTML parsing + a Linkwarden API
   integration, not just a sender-based bulk action.
5. Before running any of the above again unattended or in bulk, keep the
   same dry-run-first, confirm-before-execute discipline used tonight —
   it caught the correct scope both times before anything was touched.
