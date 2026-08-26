# PROJECT_STATE.md — Read This First

**Purpose:** This file is the single source of truth for cross-tool, cross-session AI continuity on Bryan's LLC / AI infrastructure / product portfolio. Any AI agent (Claude Code, Claude Desktop, Cursor, claude.ai, whatever comes next) opening this repo should read this file FIRST, before doing anything else, to pick up exactly where things left off with zero re-explaining.

**Convention:** Whichever tool/agent touches this project last updates this file before ending its session. Keep entries factual and dated. Don't delete history, mark it superseded instead. This is a state file, not a knowledge base, keep it lean; deep detail belongs in the docs/ folder or the relevant repo.

Last updated: 2026-08-25 (Claude, claude.ai chat, at Bryan's request)

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
| **OpenJarvis** (aka Neurodivergent Jarvis, picoclaw/tinyclaw/nanoclaw) | AI executive-function assistant for neurodivergent people — proactive/anticipatory "Pepper Potts" framing. Also exploring a HIPAA-compliant therapist↔psychiatrist communication tool (session summary relay) as a related market opportunity | Architecture/staging phase |
| **MealForge** | Recipe-to-grocery-list app: select/scale recipes, consolidate ingredients, order via Kroger/Walmart. Spoonacular for recipe data, Kroger has a real dev API, Walmart does not (seller-only) | Prototype built (React), DB schema design in progress (unit measurement variability: pinch/tsp/tbsp/cup, quantity, ingredient, substitutions) |
| **LinguaBridge** | Live AI-translated video call app. pnpm monorepo, Next.js 16, TypeScript, Tailwind v4, Supabase, LiveKit, `TranslationProvider` abstraction | Scaffolded, delivered as zip w/ git history |
| **Day trading bot** | AI-assisted day trading, IBKR paper trading first (30-45 days min data before real money), multi-factor quant signals (news, geopolitics, Polymarket/Kalshi sentiment). Hard rule: paper only, human approval gate, no auto-execution until validated | Accounts open (Alpaca + IBKR), strategy design phase |
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
- Interim plan: Mac Mini M4 Pro 48GB (headless AI server) + TB4 NVMe SSD + TB4/TB5-to-10G adapters, until the custom build is complete

### 5b. Domains
| Domain | Registrar | Status |
|---|---|---|
| bryanwills.dev | Squarespace, ~$12/yr | Currently → Little Creek (38.45.65.66). **Migrating A record to netcup (152.53.82.233).** Google Workspace email active via Name.com. |
| bryanwills.org | Squarespace, ~$12/yr | Points to AT&T home IP, no active server, available for reuse |
| bigbraincoding.com | Namecheap, expires 2027-06-16 | Active |
| bryanwills.xyz/.io/.net/.tech | — | Previously owned, expired |

### 5c. VPS migration: Little Creek → netcup (ACTIVE, this is today's priority)

**Old (being retired):** Little Creek Hosting, 38.45.65.66, 16 cores/32GB/320GB NVMe, ~$14/mo. Currently having OS/boot issues. Bitwarden browser extension broken (root cause: DNS/cert path, not Vaultwarden itself — `vault.bryanwills.dev` works fine via direct browser access, only the extension's connection is affected).

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

## 6. Immediate Priorities (as of 2026-08-25)

1. **Vaultwarden/Bitwarden fix** — get Traefik + Portainer + Vaultwarden live on netcup under `/opt/stacks/`, test via `/etc/hosts` override, then cut DNS (section 5c steps 2-7). This unblocks daily password access, which is the acute pain point right now.
2. **Full Little Creek → netcup migration** of all remaining stacks, then wipe/rebuild Little Creek as secondary.
3. **Technical blog stood up on bryanwills.dev**, live and public, documenting the build process — timing motivated by a manager at Arvato independently asking about AI-generated infra training content; Bryan wants a live example ready to point to.
4. **Student loan deferment** — needs to go back into deferment before the 90/120-day mark (60-day mark hit Aug 30, 2026); exploring having someone else make the call due to anxiety, possibly via a signed waiver.
5. **Credit report / financial** — evaluating whether to resume Norcross Consulting ($109/mo credit repair) or handle differently now that mental-health-related accommodations may apply; looking for a financial advisor experienced with neurodivergent clients (investments, LLC/business finances, CPA help, eventual return to active day trading).

---

## 7. Open Decisions (do not assume these are settled)

- LLC legal name — unresolved, many names rejected
- Whether Norcross Consulting services are still needed
- Exact scope/timeline for the "someone else handles the deferment call" plan
- Server EOL audit toolkit, homepage dashboard recurring blank-grid issue, WSL2 environment — tracked in their own areas, not detailed here to keep this file lean
