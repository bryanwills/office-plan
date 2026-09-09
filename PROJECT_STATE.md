# PROJECT_STATE.md — Read This First

**Purpose:** This file is the single source of truth for cross-tool, cross-session AI continuity on Bryan's LLC / AI infrastructure / product portfolio. Any AI agent (Claude Code, Claude Desktop, Cursor, claude.ai, whatever comes next) opening this repo should read this file FIRST, before doing anything else, to pick up exactly where things left off with zero re-explaining.

**Convention:** Whichever tool/agent touches this project last updates this file before ending its session. Keep entries factual and dated. Don't delete history, mark it superseded instead. This is a state file, not a knowledge base, keep it lean; deep detail belongs in the docs/ folder or the relevant repo.

Last updated: 2026-09-08 (Claude Code, this repo — added Claude Code on Ubuntu setup guide for the MS-01 local-AI/Ollama machine)

---

## 1. Who Bryan Is / Working Style

- Senior IT Global Operations Infrastructure Cloud Engineer & Developer at Arvato (SCS Group), remote from Spring Mill, KY
- 21+ years IT infrastructure, ~8 years self-taught dev
- AuDHD (diagnosed March 6, 2026); documenting this build publicly as neurodivergent entrepreneurship content, to show what's possible and help others in the community
- Do not change configs/setups unless necessary; ask first if in doubt
- Wants full remediation paths in every technical answer (cause, complete fix, verification), not diagnostics-then-wait
- Documentation-as-code, updated daily, not after the fact
- Standing architecture principle: **stateless compute, stateful data separation** — this file exists because of that principle

---

## 2. LLC Formation

- Forming an LLC in Kentucky, targeting Jan 1, 2027 operational deadline (moving faster where possible)
- Naming: still undecided. Rejected: personal-name, geographic, and app-name-derived options, and every "Forge/Loop/Anvil/Sovereign/Loomwork" style name tied to app branding. Candidate under consideration: Neuro-prefixed (Neuroloom, Neurapath) or something wholly disconnected from app names — **open decision, do not assume a name is locked in**
- One brand candidate specifically for the ND-assistant angle: "Neuro Inclusion AI" → neuroinclusiveai.com (kept separate from OpenJarvis product name; privacy/transparency as core values)
- Repo: `github.com/bryanwills/office-plans`, this repo, git-versioned MkDocs site

## 3. Business / Product Portfolio (all under the eventual LLC, solo dev + PM)

| Project | What it is | Status |
|---|---|---|
| **OpenJarvis** (aka Neurodivergent Jarvis, picoclaw/tinyclaw/nanoclaw) | Local-first ND executive-function command center. Fork: `github.com/bryanwills/OpenJarvis`. Sits between Stanford OpenJarvis and the walk-in / spoken-brief / wall-HUD loop on jarvis-agent.tech, **without** Marvel branding or their agent names. Voice like Claude conversation mode. Dashboards: ND app, paper trading, infra, content. HIPAA therapist↔psychiatrist summary idea is a later, separate track. Brief: `docs/infrastructure/openjarvis-command-center.md` | Forked 2026-09-06; waiting on 3090 Ti first power-on |
| **MealForge** | Recipe-to-grocery-list app: select/scale recipes, consolidate ingredients, order via Kroger/Walmart. Spoonacular for recipe data, Kroger has a real dev API, Walmart does not (seller-only) | Prototype built (React), DB schema design in progress (unit measurement variability: pinch/tsp/tbsp/cup, quantity, ingredient, substitutions) |
| **LinguaBridge** | Live AI-translated video call app. pnpm monorepo, Next.js 16, TypeScript, Tailwind v4, Supabase, LiveKit, `TranslationProvider` abstraction | Scaffolded, delivered as zip w/ git history |
| **Day trading bot** | Multi-asset (equities/options via IBKR + Alpaca, crypto via Coinbase/CCXT, prediction markets via Kalshi/Polymarket) AI-assisted trading, paper first (30-45 days min data before real money). Two signal patterns: (1) periodic multi-factor scoring (news, geopolitics, prediction-market sentiment) via a local LLM signal service (Qwen3.8:27B), advisory only; (2) verified-news-catalyst momentum pattern (fast-moving event → multi-source credibility check → sized entry → tiered exit), still approval-gated, not autonomous. Architecture plan (ApexAlgo evaluated as reference, not reused — no OSS license, crypto/CCXT-only on its own so no IBKR/Alpaca support; CCXT itself, MIT-licensed, is reused directly for the Coinbase leg): `docs/trading/apexalgo-evaluation.md`. Explicitly **out of scope**: Schwab DCA holdings (do not touch), Roth IRA (unfunded, not for active trading), Tangem cold wallet (manual only, never automated). Hard rule: paper only, human approval gate, no auto-execution until validated | Alpaca + IBKR + Coinbase + Kalshi + Polymarket accounts open; architecture plan updated 2026-09-07 with full asset scope; **freqtrade fork should be retired** — crypto-only mismatch against the equities brokers, though its CCXT dependency is being reused for Coinbase specifically |
| **Buzz Agents** | Agentic AI coordination platform (Nostr-based, Block/Jack Dorsey's company). Correct architecture: ONE self-hosted Buzz instance with per-project channels (OpenJarvis, MealForge, LinguaBridge, trading bot, Open Brain), not separate deployments per project | Planned, not yet deployed |
| **Open Brain / Second Brain / LLM wiki** | Personal knowledge ingestion pipeline — Ollama + Supabase, "second-me" LLM wiki concept, feeds from the reading-pipeline (browser tab/article summarizer) | Planned |
| **Drone services business** | Separate planned side business | Domain naming / pre-launch practice stage |
| **Technical blog** | Public documentation of the ND-entrepreneurship build-in-public process — this is the content strategy for showing "what neurodivergent people can do." Ties to bryanwills.dev migration below | **Newly prioritized** (2026-08-25) — a manager at Arvato raised wanting AI-generated infra training material in a meeting; Bryan wants to point to this blog as a live, working example of exactly that |

## 4. AI Infrastructure (the part that runs all of the above)

### 4a. Cross-tool memory / continuity (why this file exists)
- Core realization: Claude via API key in Cursor does NOT share memory with Claude Desktop or claude.ai — separate memory stores, same underlying model. This was a real gap in understanding, now corrected.
- Goal: whatever agent Bryan is using (preference: Claude Code) picks up exactly where he left off, on whatever machine, with zero re-explaining or reindex wait.
- Researching mem0 / mempalace (GitHub) as memory architecture patterns.
- Wants to eventually run multiple local models (Ollama, LM Studio) as a MoE-style research approach, but keep each model's output separate at first, don't merge prematurely.
- Explicitly does NOT want manual export/import as the workflow — wants this closer to automatic.
- **This file is the interim, human-controlled solution to that gap** until something more automatic exists: every tool reads it first, every tool updates it last.

### 4b. Hermes Agent (24/7 gateway)
- Nous Research's Hermes Agent, config at `~/.hermes/config.yaml`
- Runs Gmail MCP, Slack, Ollama as local model provider
- Multi-device priority: whichever device is active/most powerful takes priority (ai-pi → MacBook Pro → future AI PC → server), others standby
- **Hermes is the confirmed gateway going forward, NOT OpenClaw.** OpenClaw was configured once early on and never used since — do not suggest migrating to OpenClaw or imply it was ever the plan.
- **Install method: curl, NOT pip.** pip install for Hermes is deprecated/wrong — this has been given as incorrect advice before (once by Cursor/Sonnet 4.5). Always verify current install docs before advising on this.
- Gmail integration via Hermes/himalaya was abandoned — Claude handles Gmail cleanup directly instead (see gmail-cleanup work)
- In-progress (as of Aug 22 night): connecting Claude Desktop on MacBook Pro via SSH to the netcup VPS to configure Hermes there. Last attempt accidentally used Cursor/Sonnet 5 medium instead of Claude Desktop — needs to resume via Claude Desktop once SSH config is set. OK to wipe/restart the Hermes setup on the VPS + MacBook gateway side from scratch if needed.

### 4c. ai-pi
- Raspberry Pi 5, NVMe boot, running Ollama + openclaw (legacy name only — not the active gateway, see 4b) as local AI assistant node

### 4d. AI inference scheduler research (ai-scheduler-research)
- Original idea: meta-scheduler above exo-labs — profiles compute nodes (VRAM, CPU, PCIe topology), classifies incoming tasks by demand, routes to best-fit resource (heaviest task → highest-bandwidth GPU, lightest → Pi/VPS CPU)
- Prior art to study: RouteLLM, Mixtral MoE internal routing
- Secondary/future research track: NVMe APST power-state disabling + nbd-vram kernel bypass (io_uring NBD or Linux HMM) to push VRAM-as-swap latency toward NVMe-class — graduate-level kernel work, deliberately separated from the near-term scheduler project
- Build order: prove scheduler concept with plain Ollama + exo first, THEN layer in memory innovations

### 4e. Claude Code tooling
- Private `claude-config` repo on GitHub Enterprise, symlinked into `~/.claude/`
- Two custom skills: `infra-remediation`, `nvim-dotfiles-context`
- Beads (`gastownhall/beads`, Dolt-backed) identified as a candidate for structured cross-machine task memory — worth revisiting for this same continuity problem

---

## 5. Physical / Cloud Infrastructure

### 5a. Office build-out (Bullitt County, 500-750 sq ft)
- AI inference server: AMD Ryzen AI Max 128GB Strix Halo box
- AI dev workstation/NAS: custom AMD X870E Glacial build — Ryzen 9 9950X3D, Radeon AI PRO R9700 32GB, 128GB RAM expandable to 256GB, tiered NVMe (2x Gen5 1TB RAID1 boot, 2x Gen4 4TB RAID1 active, 2x Gen4 1TB scratch) + 4x enterprise HDD RAIDZ2 archive
- OPNsense routing, two-switch aggregation, bonded 40G DAC uplinks
- Desk: multi-monitor command center is intentional (wall HUD + several desk screens), not a later nice-to-have
- Interim plan: Mac Mini M4 Pro 48GB (headless AI server) + TB4 NVMe SSD + TB4/TB5-to-10G adapters, until the custom build is complete

### 5a-now. eGPU bridge + "NUC" (as of 2026-09-07 — supersedes prior PSU/target-host detail below)
- **Minisforum MS-01** ("the NUC") — i9-13900H, 64GB RAM, 1TB SSD, will run Ubuntu 24.04 LTS. Purchased, delivery expected 2026-09-07 (today). This is the mini-PC decision that was previously open (`PROJECT_STATE.md` §7 used to list "Mini-PC after eGPU bridge, MS-01 vs MS-02 — still open"; **now resolved: MS-01**).
- EVGA GeForce RTX 3090 Ti FTW3 Ultra 24 GB (Ti = 12V-2x6, not dual 8-pin)
- **Corsair RX1000 PSU** + Corsair Type 4 special power adapter for the 3090 Ti (correction — prior note said RM1000x; RX1000 is correct per Bryan 2026-09-07)
- Minisforum DEGv2 eGPU dock, connects via **Thunderbolt 5** — target host is now the **MS-01**, not the MacBook Pro (prior note said MacBook Pro; superseded)
- **Nothing powered on yet as of 2026-09-07** — still pending the MS-01 arriving and the safety-gate/short-detection step in `docs/infrastructure/eGPU/ai-rig-build-log.md`
- Models on `/Volumes/OllamaDrive` (currently attached to the MacBook Pro; will move to the MS-01 once it's set up)
- Target model: Qwen3.8:27B via Ollama — used for OpenJarvis/Hermes tool-calling AND as the trading-bot signal service (see `docs/trading/apexalgo-evaluation.md`), same GPU serves both
- Planned dual-use: this rig will be physically transported between home and work once operational, for local-AI work on a separate work-owned homebrew app — that work is out of scope for this repo (public, personal/LLC docs only) and will not be documented here
- This is how local agents get a GPU without a hosted-model bill. See `docs/infrastructure/eGPU/ai-rig-build-log.md`.

### 5b. Domains
| Domain | Registrar | Status |
|---|---|---|
| bryanwills.dev | Squarespace, ~$12/yr | Currently → Little Creek (38.45.65.66). **Migrating A record to netcup (152.53.82.233).** Google Workspace email active via Name.com. |
| bryanwills.org | Squarespace, ~$12/yr | Points to AT&T home IP, no active server, available for reuse |
| bigbraincoding.com | Namecheap, expires 2027-06-16 | Active |
| bryanwills.xyz/.io/.net/.tech | — | Previously owned, expired |

### 5c. VPS migration: Little Creek → netcup

**Status as of 2026-08-30 (major progress, see detailed docs at `docs/infrastructure/stacks/<name>/MIGRATION.md` or `SETUP.md` per stack):**

- **Vaultwarden** — fully migrated, DNS cut over (`vault.bryanwills.dev` → netcup), real Let's Encrypt cert live, login verified via Chrome extension with Yubikey. **Known open issue:** extension logs in but vault data isn't loading — unresolved, Bryan to revisit.
- **Hashicorp Vault** — migrated (was already stopped on Little Creek, no live cutover needed), data integrity verified intact (original 5-share/3-threshold init preserved, did NOT re-initialize), DNS cut over (`keys.bryanwills.dev`), cert live. **Still sealed** — Bryan needs to unseal manually with his existing key shares.
- **Nginx + both websites** (bryanwills.dev, bigbraincoding.com) — fully migrated (data verified byte-identical: 1.7G + 3.3G), DNS cut over for root + www on both domains, one multi-SAN Let's Encrypt cert covering all 4 hostnames, verified live with full TLS chain validation.
- **Traefik** — running on netcup, but its **Docker provider is disabled**: Docker Engine 29.x enforces `MinAPIVersion 1.40` with no backward-compat shim, and Traefik (tested v3.3 and v3.5) hardcodes/defaults to API 1.24 and does not honor `DOCKER_API_VERSION` — a confirmed incompatibility, not a config mistake. All routing on this host is done via Traefik's **file provider** instead (`/opt/stacks/traefik/dynamic/*.yml`), referencing containers by name over the shared `proxy` Docker network. Apply this same pattern to every future stack on this host.
- **Buzz** (new build, not a migration) — deployed at `buzz.bryanwills.dev`, relay+Postgres+Redis+MinIO live, fresh owner Nostr identity generated and configured. **Found and fixed a real security gap during setup:** Buzz's default port 3000 was reachable directly from the public internet, bypassing both Traefik's TLS and `ufw` (Docker's iptables rules ignore `ufw` for published ports) — fixed via a netcup-specific `compose.traefik.yml` override (see `docs/infrastructure/stacks/buzz/`). **In progress as of end of session:** Bryan was mid-onboarding in the desktop app (had to fully clear leftover identity state from an old Aug-22 attempt — turned out to be cached in macOS Keychain, not just Application Support, since a plain app uninstall/reinstall didn't clear it). Last screen seen: agent-integration picker (Claude Code / Codex / Goose) — advised Claude Code, matches Bryan's stated tooling preference. **Not yet confirmed working end-to-end** — pick this up next session.
- **Transfer-method lesson learned:** the first website-data copy attempt piped through `ssh littlecreek | ssh netcup` run locally, which routes data through the local Mac's own connection twice and crawled at ~0.4MB/s. Fixed by a temporary SSH keypair enabling direct netcup→littlecreek `rsync` (~10x faster), removed after. **Reuse the direct-server-to-server pattern for any future large-data stack migration** instead of relaying through the local machine.
- **Repo hygiene finding:** `office-plan` is a **public** GitHub repo and had no `.gitignore` — added one (excludes `.env`, `acme.json`, `.DS_Store`, `site/`). Real secrets (Vault OAuth creds, Buzz DB/Redis/S3/relay keys, etc.) are kept in `.env` files on the servers only, generated fresh, never committed or printed to chat.
- **Not yet decided:** timing for decommissioning Little Creek's now-redundant Vaultwarden/Vault/Nginx — don't delete without asking first (matches Bryan's standing "ask before removing" preference).

**Old (being retired):** Little Creek Hosting, 38.45.65.66, 16 cores/32GB/320GB NVMe, ~$14/mo. Currently having OS/boot issues. Bitwarden browser extension broken (root cause: DNS/cert path, not Vaultwarden itself — `vault.bryanwills.dev` works fine via direct browser access, only the extension's connection is affected). **Superseded by DNS cutover above** — extension should reconnect to netcup now, though data-loading issue noted above is still open.

**New (target):** netcup VPS 8000 G12, Manassas VA, 152.53.82.233. 16 vCore KVM, 64GB DDR5 ECC, 2TB NVMe, 10GbE, DDoS protection. €52.82/mo, 0-month billing (no prepay trap). Deployed, being reinstalled to Ubuntu 26.04 UEFI amd64. Joins Tailscale alongside ai-pi, MacBook Pro, bryanwills.dev.

**Folder structure standard (applies to ALL Docker stacks on netcup):** `/opt/stacks/<service-name>/` — e.g. `/opt/stacks/traefik/`, `/opt/stacks/vaultwarden/`, `/opt/stacks/nautobot/`. Backups go in the parallel `/opt/backups/<service-name>/`. This convention is already proven on infrapoc (Nautobot, NetBox) — reuse it exactly on netcup.

**Docker stack being migrated (from bigbraincoding-vps framework, reused/modernized, not rebuilt):** Traefik v3, Portainer, Vaultwarden, Authentik, GitLab CE, N8N, Code-Server, Linkwarden, Forgejo.

**Migration sequence (do not skip steps or reorder):**
1. Ubuntu 26.04 installed and hardened on netcup, Tailscale joined
2. Recreate stacks under `/opt/stacks/<name>/` — start with Traefik + Portainer + Vaultwarden first (Vaultwarden is the one causing daily pain, prioritize it)
3. For each stack: copy the existing docker-compose.yml + `.env` + named volumes/bind-mount data from Little Creek to netcup (`rsync` over Tailscale, container stopped on source during final sync to avoid data drift)
4. Confirm `vault.bryanwills.dev` resolves and logs in correctly on netcup **before** touching DNS — test via a temporary `/etc/hosts` entry (`152.53.82.233 vault.bryanwills.dev`) on the MacBook
5. Lower Squarespace DNS TTL to 300s, wait ~1 hour for propagation headroom
6. Flip A records in Squarespace (see table below)
7. Confirm Bitwarden browser extension reconnects (should be automatic within minutes once DNS resolves to netcup and cert is valid there)
8. Migrate remaining stacks (Authentik, GitLab CE, N8N, Code-Server, Linkwarden, Forgejo) one at a time, same copy-then-cutover pattern
9. Once everything is confirmed stable on netcup: wipe Little Creek, rebuild fresh, repurpose as secondary/backup
10. Restore Squarespace TTL to 3600 once migration is confirmed stable

**DNS records to set in Squarespace (after netcup stacks are confirmed working, per step 6):**

| Type | Name | Value |
|---|---|---|
| A | @ (root) | 152.53.82.233 |
| A | gateway | 152.53.82.233 |
| A | vault | 152.53.82.233 |
| A | www | 152.53.82.233 |
| A | portainer | 152.53.82.233 |

Hostname on the box itself: system hostname `gateway`, FQDN `gateway.bryanwills.dev` — netcup's own SCP-assigned FQDN (`v220260840l004503315.goodsrv.de`) is irrelevant, don't try to change it there.

**Important:** verify MX records for bryanwills.dev (Google Workspace mail) survive the A-record change — they're separate records but confirm after cutover.

### 5d. infrapoc (work-adjacent NetBox/Nautobot server — separate from personal infra above, included here for the folder-structure precedent only)
- `/opt/stacks/nautobot/`, `/opt/stacks/netbox/` convention already proven here, being carried over to netcup
- Nightly config-backup pipeline: Oxidized (network devices, sourced from NetBox) + etckeeper (Pi `/etc`), pushed to Forgejo and mirrored to Azure DevOps

---

## 6. Immediate Priorities (as of 2026-09-07)

1. **MS-01 arrival + eGPU first power-on** — MS-01 delivery expected 2026-09-07; once it's in hand, safety-gate the DEGv2 ATX/EPS wiring, short detection test, then a real local model (Qwen3.8:27B via Ollama). This unblocks OpenJarvis, the Hermes tool-calling gap, AND the trading-bot signal service (see `docs/trading/apexalgo-evaluation.md`) — one GPU serves all three. Nothing powered on yet. See `docs/infrastructure/eGPU/ai-rig-build-log.md`.
1a. **Trading bot: retire the freqtrade fork, start the Alpaca-adapter backend skeleton** — see `docs/trading/apexalgo-evaluation.md` for the full plan. ApexAlgo studied and rejected as a direct base (crypto/CCXT-only, no OSS license) but its architecture patterns (async engine, node-graph evaluator, risk nodes, event-driven bot console) are worth reimplementing clean-room against Alpaca first, then IBKR.
2. **OpenJarvis command-center v0 on that GPU** — morning brief from local sources, conversation-mode voice, HUD + product dashboards. Direction: `docs/infrastructure/openjarvis-command-center.md`. Do not start by cloning Peter Mach's chrome or greetings.
3. ~~Vaultwarden/Bitwarden fix~~ — **done**, see 5c. One loose end: extension logs in but vault data isn't loading yet — pick up when it hurts.
4. **Finish Buzz onboarding** — Bryan was mid-setup in the desktop app (identity import resolved via Keychain wipe; last screen was the agent-integration picker, Claude Code recommended). Confirm it actually completes and the workspace loads. Still open as of 2026-08-30 night.
5. **Hashicorp Vault unseal** — migrated and data-verified, just needs Bryan to run `vault operator unseal` with his existing key shares when he's ready to use it.
6. ~~Hermes Agent + Gmail MCP reliability on netcup~~ — **substantially debugged**, see `docs/infrastructure/hermes-gmail-troubleshooting-2026-08-30.md`. Four real bugs found and fixed. Core finding still true on CPU: 8-9B local models are unreliable at tool-calling. GPU path above is the intended fix. Do not suggest Anthropic/OpenAI API keys.
7. ~~Gmail inbox backlog cleanup~~ — **done**, two deterministic (non-LLM) scripts: 2,037 Honey/SlickDeals emails trashed, 188 GitHub notifications marked read. See `docs/infrastructure/scripts/README.md`.
8. Little Creek decommission timing for Vaultwarden/Vault/Nginx — not yet decided, ask before deleting anything there.
9. **Technical blog stood up on bryanwills.dev** — not started. Still wanted as a live ND-entrepreneurship / infra-training example. Sequence: GPU working, then a brief that is real, then write about it.
10. **Ghost / documentation-as-code site** — also not started; Bryan chose Buzz first among the three "new builds" on 2026-08-30.
11. **Student loan deferment** — needs to go back into deferment before the 90/120-day mark (60-day mark hit Aug 30, 2026); exploring having someone else make the call due to anxiety, possibly via a signed waiver.
12. **Credit report / financial** — evaluating whether to resume Norcross Consulting ($109/mo credit repair) or handle differently now that mental-health-related accommodations may apply; looking for a financial advisor experienced with neurodivergent clients (investments, LLC/business finances, CPA help, eventual return to active day trading).
13. **Local ND community** — Bryan is making more contacts locally. Keep the product honest enough to show them; do not oversell a HUD that does not run yet.

---

## 7. Open Decisions (do not assume these are settled)

- LLC legal name — unresolved, many names rejected
- How Hermes (netcup 24/7 gateway) and the OpenJarvis fork share memory, voice, and channels. Do not silently retire Hermes.
- ~~Mini-PC after the eGPU bridge (MS-01 vs MS-02)~~ — **resolved 2026-09-07: MS-01** purchased, delivery pending
- Trading bot repo name/location (replacing the freqtrade fork), and where IB Gateway/TWS runs long-term given the NUC will physically travel between home and work — see `docs/trading/apexalgo-evaluation.md` §6
- Whether Norcross Consulting services are still needed
- Exact scope/timeline for the "someone else handles the deferment call" plan
- Server EOL audit toolkit, homepage dashboard recurring blank-grid issue, WSL2 environment — tracked in their own areas, not detailed here to keep this file lean
