# Bryan Wills — AI Business & Infrastructure Context

**Purpose of this file:** This is a working context document for any AI agent (primarily Claude Code) picking up work on Bryan's AI business, homelab, and infrastructure projects. Read this in full before making changes to any system referenced here. This file will drift out of date — if something here conflicts with what you observe on a live system or in a repo, trust the live system and flag the conflict to Bryan rather than silently overwriting either.

**Last compiled:** August 29, 2026, from a chat conversation with Claude (claude.ai), corrected same day after Bryan flagged an inaccuracy. Bryan has emphasized this file needs to stay current — if he tells you something new that changes a plan below, update this file, don't just act on it and move on.

**Update 2026-08-30 (Claude Code, this repo):** See `PROJECT_STATE.md` section 5c for full current migration status — short version: Vaultwarden, Hashicorp Vault, and Nginx (both bryanwills.dev + bigbraincoding.com) are all fully migrated to netcup with DNS cut over and live. Buzz (agentic workspace, `github.com/block/buzz`) was newly deployed at `buzz.bryanwills.dev`; Bryan was mid-onboarding in the desktop app when the session ended. Traefik's Docker provider is disabled on netcup (confirmed Docker Engine 29.x / Traefik client incompatibility) — every stack routes via Traefik's file provider instead; follow that pattern for anything new. The repo was found to be public with no `.gitignore` — one was added; keep all real secrets in server-side `.env` files, never in this repo or in chat output.

**Update 2026-08-30 night (same session, later that evening):** Spent several hours debugging why Hermes Agent's interactive CLI on netcup couldn't reliably use its already-working Gmail MCP connection — found and fixed 4 real bugs (see `docs/infrastructure/hermes-gmail-troubleshooting-2026-08-30.md`), but the core remaining limitation is that small local CPU-only models (8-9B) are genuinely unreliable at agentic tool-calling — confirmed by a warning built into Hermes's own source code, not a config mistake on Bryan's part. **Bryan explicitly does not want to pay for a hosted model** to fix this ("this will be ongoing and it will require a lot of traffic... I do not want to use anything that requires me to pay for it") — respect this constraint in future sessions rather than re-suggesting Anthropic/OpenAI API keys. Separately, successfully ran two one-time deterministic (non-LLM) Gmail cleanup scripts — see `docs/infrastructure/scripts/README.md` — after Bryan's original ask (an unattended overnight LLM cron job) was talked down given the demonstrated reliability issues that same session.

**Update 2026-09-06 (Cursor, this repo):** The hosted-model constraint above still stands. The hardware path to fix the CPU tool-calling failure is now in the house: EVGA RTX 3090 Ti FTW3 Ultra (24 GB) + Corsair RM1000x + Minisforum DEG2 V2 eGPU dock on Thunderbolt 5, purchased 2026-09-05. First power-on is not done yet. Full inventory and safety gate: `docs/infrastructure/eGPU/ai-rig-build-log.md`. Bryan forked Stanford OpenJarvis to `github.com/bryanwills/OpenJarvis` (local `/Users/bryanwills/code/ai/OpenJarvis`) and is building a local-first command center between that stack and the walk-in / spoken-brief / wall-HUD loop shown on [jarvis-agent.tech](https://jarvis-agent.tech/), without Marvel branding, without their agent names, and without a "Daddy's Home" / "Good evening, sir" greeting. Daily voice should feel like Claude conversation mode. Dashboards must cover the ND assistant, the paper-trading bot, and the rest of the portfolio across a real multi-monitor desk (that many screens is intentional). He is also making more local neurodivergent-community contacts; the system has to help his life first so it can be a honest demo for that community. Standing brief: `docs/infrastructure/openjarvis-command-center.md`. Hermes on netcup stays the existing 24/7 gateway until an explicit integration decision. Do not drop OpenJarvis source into this public docs repo.

**Update 2026-09-07 (Claude Code, this repo):** Two corrections/resolutions to the entry above — Bryan confirmed the mini-PC decision (**Minisforum MS-01**, i9-13900H/64GB/1TB, Ubuntu 24.04 LTS, delivery expected today) and the PSU is a **Corsair RX1000** (not RM1000x as previously noted), with the DEGv2 dock's Thunderbolt 5 link now targeting the MS-01 as host rather than the MacBook Pro. Still nothing powered on. Separately, Bryan found `github.com/Stenvro/ApexAlgo` on Reddit as a more polished self-hosted trading-bot dashboard reference and asked for a full study + comparison against the existing IBKR/Alpaca/Humbled-Trader day-trading-bot plan. Full writeup: `docs/trading/apexalgo-evaluation.md`. Bottom line: ApexAlgo is crypto/CCXT-only (no IBKR or Alpaca support) and ships with no open-source license ("all rights reserved"), so it is being treated as a reference architecture to reimplement clean-room, not a codebase to fork — and the existing `freqtrade` fork should be retired for the identical crypto-only mismatch against Bryan's actual (equities/options) accounts. The plan keeps ApexAlgo's genuinely good ideas (async event-driven engine, node-graph visual strategy builder, WAL-mode SQLite, tiered risk nodes, per-bot log console, backtest capital-pool model) and replaces its CCXT broker layer with Alpaca (build first, has native paper trading) and IBKR (via `ib_async`, needs a persistent Gateway/TWS process — flagged as a real tension with the stateless-compute principle given the NUC will travel between home and work), plus adds a signal-service layer neither ApexAlgo nor the Humbled Trader/MCP approach has: a scheduled (not per-candle) local-LLM job on the same Qwen3.8:27B/eGPU rig that scores news/geopolitical/Polymarket-Kalshi sentiment per symbol and feeds it into the node graph as one more condition input — advisory only, never given order-placing access, consistent with the standing paper-only/human-approval-gate hard rule. Also noted: Bryan's plan to physically transport the MS-01 + eGPU rig between home and work to use local AI on a separate work-owned homebrew app is real but explicitly out of scope for this public repo — no work-app details belong here.

---

## Resolved (previously open questions, confirmed by Bryan Aug 29 2026)

1. **Docker path:** netcup VPS follows the same container structure model as the `infrapoc` work server — **`/opt/stacks/{container_name}/`**, NOT `/home/bryan/docker`. Any prior note or instruction saying `/home/bryan/docker` is wrong and should be disregarded/corrected wherever it appears (including in any older chat history or docs).
2. **Meal Forge:** Bryan wants to set up Buzz Agent to manage and help complete the MealForge app, working under an approvals-with-a-plan model (Buzz proposes, Bryan approves before execution — same approval-gated pattern as his other automation preferences). Concept/stack details for MealForge itself still not captured beyond this — ask Bryan for the app's actual scope/feature set when starting real work on it. Local repo path: `/Users/bryanwills/code/bbc/MealForge`.
3. **MkDocs replacement: ProperDocs** (`github.com/ProperDocs/properdocs`, site `properdocs.org`). Context: MkDocs' maintainer has effectively abandoned the project and is planning to repurpose the "MkDocs" name for an unrelated "MkDocs 2.0" that won't support existing themes/plugins — ProperDocs is a drop-in fork/continuation by the previous active maintainer. Migration is trivial: `pip install properdocs` (in place of `pip install mkdocs`), then use `properdocs build`/`properdocs serve` instead of the `mkdocs` command — existing `mkdocs.yml` config, plugins, and themes keep working unchanged. Config file can optionally be renamed `properdocs.yml` but doesn't have to be. Use this for the `office-plans` MkDocs repo and any other docs platform work going forward, not vanilla MkDocs.

## A Standing Frustration Bryan Wants On Record

Bryan has explicitly stated this is a recurring, significant source of frustration and wants it documented so future agents take it seriously rather than repeating the pattern:

When an AI agent (any model, not specific to one) drifts from or contradicts something already established in a prior conversation — stating a wrong file path, wrong config, wrong architecture decision, etc. as if it were settled when it isn't — it sends Bryan back into a troubleshooting loop he's already been through before. This has happened multiple times (e.g. the netcup docker path being stated as `/home/bryan/docker` when `/opt/stacks/` had already been decided and discussed; a different model making unreviewed SSH changes on Little Creek that broke Mac SSH access). The cost isn't just time — it compounds his existing frustration with troubleshooting cycles generally and is a real drain given everything else he's managing (see Working Preferences above re: ADHD, and the broader context of an already-stressful workday when this file was created).

**What this means practically for any agent working from this file:**
- Treat facts in this document as previously-established, not as something to re-derive or second-guess from general knowledge or a different heuristic
- When something you're about to say conflicts with what's written here, stop and flag the conflict explicitly rather than proceeding on your own assumption — "this file says X, I'm seeing/thinking Y, which is right?" costs one exchange; guessing wrong costs an entire troubleshooting cycle
- When you don't know something (a path, a decision, a preference), say so and ask, rather than filling the gap with a plausible-sounding guess
- If you catch yourself about to state something as settled that you're actually inferring or reconstructing from partial context, that's the moment to pause and verify first, not after Bryan corrects you

---

## Who Bryan Is

- Senior IT Global Operations Infrastructure Cloud Engineer & Developer at Arvato (SCS Group), works remotely from Spring Mill, Kentucky (America/New_York)
- 21+ years IT infrastructure experience, ~8 years self-taught development
- Stack: Linux (Ubuntu, RHEL, Arch), Windows Server, Azure, Docker, Kubernetes, Ansible, Traefik, NetBox, Nautobot, Python, TypeScript, PowerShell, React/Next.js
- GitHub: `@bryanwills` / `@bryanwi09`
- Neurodivergent (ADHD); this context shapes both his working style preferences (see Working Preferences below) and the business/product direction (ND-focused tooling and content)
- Currently living at his mom's house, wants to move out — office buildout and infrastructure projects carry real urgency tied to this goal, but he still wants things done correctly, not rushed

## Working Preferences (apply these regardless of which project you're on)

- Do not change configs/setups unless necessary; ask first if in doubt
- Bundle diagnosis and fix together — don't sequence one command at a time waiting on output unless a fix genuinely can't be determined without a missing piece of info
- Every response involving troubleshooting needs the full remediation path: likely cause, complete fix (full file contents, not partial diffs), verification steps
- Training/explanations should be hands-on, not theory-only
- Documentation he encounters is often wrong, outdated, or misplaced — verify against live systems, don't trust docs blindly
- "If I'm doing something wrong, I want to know" — direct, not softened, feedback
- Output format: Markdown or zip with multiple files, copy-paste-ready commands, full file paths
- Approval-gated automation: agents may suggest/draft, Bryan approves all external actions (messages, emails, tickets, financial actions, data deletion, sharing recordings)
- Never use em dashes in written output
- Explicit standing rule: don't make executive-decision-level changes to plans/docs without asking first

---

## The Business Vision

**Core idea:** Build AI-powered tools for the neurodivergent community, and simultaneously document the entire build-it-yourself journey as content (blog, premium content, multiple income streams from one underlying process). Coined phrase for when ideas compound: "synapses firing / lighting up a city block."

- **LLC formation:** Actively forming in Kentucky. Targeting January 1, 2027 operational deadline, moving faster where possible. Naming undecided — leaning Neuro-prefixed (Neuroloom, Neurapath) or abstract coined names (Cordant, Kestrel). Explicitly rejecting personal-name, geographic, or app-name-derived options. Candidate brand for the AI-assistant line specifically: "Neuro Inclusion AI" → neuroinclusiveai.com, kept as a separate brand from the OpenJarvis product name, with privacy/transparency as core stated values.
- **Content plan:** Public blog documenting the entire migration/build/business process as ND entrepreneurship content. Wants a dot.card QR code and Linktree pointing to a central hub showing his work and socials.
- **Domains owned:**
  - `bryanwills.dev` — Squarespace (~$12/yr), Google Workspace email configured, currently on Little Creek, migrating A record to netcup (152.53.82.233)
  - `bryanwills.org` — Squarespace (~$12/yr), pointed at AT&T home IP, no active server, available for reuse
  - `bigbraincoding.com` — Namecheap, expires 2027-06-16
  - Previously owned/expired: bryanwills.xyz, bryanwills.io, bryanwills.net, bryanwills.tech
  - `neuroinclusiveai.com` — candidate, not yet confirmed purchased

---

## Infrastructure: VPS Migration (Little Creek → netcup)

**Status as of Aug 29, 2026: actively in progress, blocked most of the day on Tailscale/SSH connectivity issues, now proceeding via direct public-IP SSH instead.**

- **Little Creek** (being retired): public IP `38.45.65.66`, Linux user `bryanwi09`, Docker stacks at `/home/bryanwi09/docker`, ~6 months of OS/console/access problems, was on a Black Friday deal (~$14/mo, 16GB RAM/16 cores/320GB NVMe — note: hardware-research notes also list it as 32GB RAM in one place, verify actual spec against provider dashboard if needed). Docker backup repo: `github.com/bryanwills/docker`.
- **netcup VPS 8000 G12** (new home): public IP `152.53.82.233`, Manassas VA, Linux user `bryan`, Docker Compose stacks go under **`/opt/stacks/{container_name}/`** — same model already used on the `infrapoc` work server, deliberately kept consistent rather than using `/home/bryan/docker`. Spec: 16 vCore KVM, 64GB DDR5 ECC RAM, 2048GB NVMe, traffic flatrate, 10GbE, DDoS protection, snapshots, remote console. Billing ~€52.82/mo (~$61 USD), 0-month rolling plan (deliberately avoided the 12-month prepay option). Hostname plan: system hostname `gateway`, FQDN `gateway.bryanwills.dev`.
- Deployed with Debian Trixie, being reinstalled to Ubuntu 26.04 UEFI amd64.
- Container strategy: Docker + Docker Compose primary (reusing the existing bigbraincoding Traefik/Portainer framework, modernizing rather than rebuilding). One LXC container planned experimentally.
- Little Creek's keycloak and authentik stacks are dead (not running) and will NOT be migrated to netcup.
- Existing bigbraincoding.com stack (separate VPS, 16 cores/32GB RAM Ubuntu) already runs: Traefik v3, Portainer, Vaultwarden, Authentik, GitLab CE, N8N, Code-Server, Linkwarden, self-hosted Forgejo, Nginx with visitor analytics. This is the framework being reused/modernized for netcup, not rebuilt from scratch. Local repo path: `/Users/bryanwills/code/bigbraincoding`.
- **Planned workload order on netcup once migration is done:** Second Brain → Open Brain (Ollama + Supabase) → Buzz agent workspace → IBKR trading bot → 5dive (5dive explicitly last).
- TCP/22 outbound is blocked on Bryan's work network — this is why Tailscale (or a fallback like Cloudflare Tunnel / SSH on 443) matters for remote access from work; from home or hotspot, direct SSH on 38.45.65.66 / 152.53.82.233 works fine.
- Documentation-as-code requirement: all migration stages should be documented daily, using ProperDocs (see Resolved section above).
- Local repo path for VPS-related work: `/Users/bryanwills/vps`.

## Tailscale / Networking State (as of Aug 29, 2026, still being stabilized)

- Tailnet devices: `ai-pi` (100.114.43.8, Pi 5, offers exit node), `bryanwills` = Little Creek (100.79.184.46, tagged `tag:ai`/`tag:prod`/`tag:vpn`, offers exit node), `gateway` = netcup (100.90.171.127, has SSH tag), plus MacBook Pro, iPad, iPhone.
- Root cause of a full afternoon of breakage: running BOTH the Homebrew CLI `tailscaled` and the GUI/pkg app simultaneously, creating two competing node identities/daemons. Resolution in progress: standardize on ONE install method only.
- Correct baseline config once stable: `sudo tailscale up --accept-routes=false --accept-dns=true` — no exit node, no subnet route acceptance, MagicDNS on for tailnet names only. Do not accept routes from `ai-pi` or `bryanwills`, both advertise themselves as exit nodes but Bryan doesn't want default-route traffic pulled through them.
- Work's guest network appears to actively detect and block Tailscale (toggle flips off instantly on connect attempt), not just port-block it. Fallback options discussed for that specific network: Cloudflare Tunnel (most durable, outbound-only HTTPS, indistinguishable from browser traffic), or running sshd on an additional port 443 listener. Not yet implemented, deferred until Tailscale itself is stable.
- Personal data / AI workloads should never leave the home network unless over VPN — standing privacy principle.
- As of this session: Tailscale was deprioritized in favor of direct public-IP SSH with passwordless key auth, to unblock the migration work today.

---

## AI Projects Portfolio

### OpenJarvis (aliases: Neurodivergent Jarvis, picoclaw, tinyclaw, nanoclaw)
Executive-function AI assistant for neurodivergent people. Proactive / anticipatory support, not a reactive chatbot. **Do not use Pepper Potts, Tony Stark, or Marvel framing in product copy or voice.** Candidate consumer brand remains "Neuro Inclusion AI" (`neuroinclusiveai.com`), kept separate from the OpenJarvis stack name.

**Repos (as of 2026-09-06):** working fork `github.com/bryanwills/OpenJarvis` from `github.com/open-jarvis/OpenJarvis`. Local checkout: `/Users/bryanwills/code/ai/OpenJarvis`. Older experiments (do not merge without review): `/Users/bryanwills/code/jarvisai`. Neuro-prefixed path `/Users/bryanwills/code/bbc/neuro` may still exist; prefer the fork above for new work.

**Product shape:** local-first command center between Stanford OpenJarvis (on-device agents, skills, morning digest) and the operational loop on [jarvis-agent.tech](https://jarvis-agent.tech/) (walk-in, spoken brief, wall HUD, specialist agents overnight). Bryan wants conversation-mode voice, a real multi-monitor desk (wall HUD + several desk screens), and live views of the ND assistant, the paper-trading bot, infra, and content. Overnight drafts are fine. Approvals stay gated. Full brief: `docs/infrastructure/openjarvis-command-center.md`.

Hermes Agent remains the preferred **existing** 24/7 gateway on netcup (NOT OpenClaw). How Hermes and OpenJarvis share memory / voice / channels is an open architecture question. Do not silently retire Hermes.

Related market idea, later and separate: HIPAA-compliant therapist↔psychiatrist session-summary relay. Reference paper: arxiv.org/abs/2605.17172.

### Open Brain
Personal "second brain" LLM system, Ollama + Supabase backend. Initial Supabase config (thoughts, memory retention, passwords) completed Aug 19, 2026. Slated as the first workload to stand up on the new netcup VPS after migration.

### ai-memory-architecture (cross-tool AI memory/context continuity)
Core goal: whatever AI agent Bryan is using (preferably Claude Code) should pick up exactly where he left off, on whatever machine he's on, with minimal/zero re-explaining. Key realized gap: Claude via API key inside Cursor does NOT share memory with Claude Desktop or claude.ai, these are separate stores despite being the same underlying model. Researching mem0 and mempalace for architecture patterns. Wants eventual multi-model (MoE-style) research separation — keep each local model's output separate at first rather than merging prematurely. Does NOT want manual export/import as the memory workflow, wants something automatic/systematic. Standing architecture principle: separate stateless compute from stateful data, applied to AI-continuity, not just infra (see homelab section below). Had a bad experience with a different model (Grok via Cursor) making unreviewed SSH config changes on Little Creek that broke Mac SSH access, reinforcing preference for one model handling continuity end-to-end. Open to a git-tracked, model-agnostic source-of-truth doc (possibly in the obsidian-journal repo) any AI tool can reference for current project state. **This file is exactly that document.**

### ai-scheduler-research (exo-labs fork, heterogeneous inference scheduler)
ECE-background-driven idea: a meta-scheduler above exo-labs that profiles all available compute nodes (VRAM, CPU bandwidth, utilization, PCIe topology), classifies incoming tasks by computational demand, and routes tasks to best-fit resource (heaviest task to biggest GPU, lightest task to Pi/VPS CPU). Prior art to study: RouteLLM, Mixtral MoE. Secondary/future research track: NVMe APST power state disabling + nbd-vram kernel bypass to reduce VRAM-as-swap latency. Planned build order: prove the scheduler concept with plain Ollama + exo first, add memory-tier research later. Full documentation planned with an eventual arxiv publication target. Timeline: start after both the netcup VPS and the 870 Glacial build are running.

### LinguaBridge
Live AI-translated video call app. Scaffolded as a pnpm monorepo. Stack: Next.js 16, TypeScript, Tailwind v4, Supabase, LiveKit. Uses a `TranslationProvider` abstraction and shared packages. TypeScript strict, includes a translation worker app. Local repo path: `/Users/bryanwills/code/ai/translation_app`.

### Meal Forge
App Bryan wants to set up a Buzz Agent to manage and help complete, under an approvals-with-a-plan model (Buzz proposes a plan, Bryan approves before execution, matching his standing approval-gated automation preference elsewhere). Feature scope/stack for the app itself not yet fully captured — confirm with Bryan before starting implementation work. Local repo path: `/Users/bryanwills/code/bbc/MealForge`.

### ai-pi (Raspberry Pi 5 local assistant)
Hostname `ai-pi`, 8GB RAM, NVMe-booting (Samsung 970 EVO 500GB, harvested from a laptop, replaced a dead ADATA LEGEND 850). Runs Ollama + Gemma 4 + Hermes over the Tailscale mesh. Has 3x SanDisk 1TB TB3/4 drives available as free model storage. Also has an offline PowerEdge 2U NAS (12Gb/s SAS) as a future larger-storage option. Plans: XFCE4 desktop, 3.5" touch LCD via GPIO already added, eventual use as a desk AI assistant at work with a dashboard display.

### day-trading-bot
AI-assisted, multi-asset trading (equities/options via IBKR + Alpaca, crypto via Coinbase, prediction markets via Kalshi/Polymarket — all already have accounts open). Hard rule: paper trading only until 30-45 days of live data gathered, human approval gate before any live order, no auto-execution ever without explicit validation. Two signal patterns in the plan: (1) periodic multi-factor scoring — quantitative/statistical, live news, geopolitical events, social sentiment, prediction-market data, macro factors — via a local LLM (Qwen3.8:27B), advisory only; (2) a verified-news-catalyst momentum pattern (fast breaking news on a symbol → multi-source credibility check → sized entry → tiered exit), inspired by a real near-miss Bryan described (XRP's overnight move on a verified Rakuten integration announcement) — still approval-gated, not autonomous, with the approval-latency tradeoff explicitly flagged as unresolved. Explicitly out of scope: Schwab (SCHD/QQQI dollar-cost-average holdings — do not touch), Roth IRA (unfunded), Tangem cold hardware wallet (manual only, never automated — a different and higher-consequence risk than an exchange API key). Long-term inspiration: Humbled Trader, Ross Cameron/Warrior Trading style, plus `github.com/Stenvro/ApexAlgo` (studied 2026-09-07 as an architecture reference — crypto/CCXT-only on its own and unlicensed, not reused directly; its CCXT dependency, MIT-licensed and separate from ApexAlgo's own code, is being reused directly for the Coinbase adapter). Full architecture plan: `docs/trading/apexalgo-evaluation.md`. **`github.com/bryanwills/freqtrade` (fork) should be retired** — crypto-only mismatch against the equities brokers, same as ApexAlgo. New repo TBD, built around Alpaca + Coinbase(CCXT) adapters first, then IBKR via `ib_async`, plus the two signal-service patterns above. Note: no specific account balances, holdings, or personal financial history are recorded in this repo or its docs — `office-plan` is public; those specifics are tracked privately elsewhere.

---

## Hardware Roadmap

### "870 Glacial" custom AI server/NAS build (primary long-term home AI machine)
- Purpose: 24/7 always-on home AI inference + dev machine, replacing $100+/mo currently spent on AI app/API subscriptions
- Case: Lian Li O11 Dynamic EVO XL White (O11DEXL-W) — already purchased
- RAM: 96GB (2×48GB) G.Skill Trident Z5 DDR5-6400 CL30 EXPO (deliberately not higher speed — AM5 drops to 2:1 mode above 6400 MT/s, adding latency)
- OS: leaning bare-metal Ubuntu + Proxmox, still deciding LXC vs Docker vs Kubernetes
- Remote management: PiKVM v4 Mini (~$175), kept separate from his existing JetKVM
- Storage plan: Gen5 NVMe (1-2TB) for OS/Proxmox; Gen4 NVMe mirror (2×4TB, already has one Samsung 990 Evo Plus 4TB) for fast pool; HDD RAIDZ2 targeting ~50TB usable for bulk/cold storage; ZFS throughout. HDDs must be CMR (hard requirement for ZFS), Seagate Exos X or WD Ultrastar DC HC series, sourced used from Homelabsales/Facebook Marketplace, verified against SMART thresholds (ID 5 = 0, ID 197 = 0, ID 198 = 0, under 30,000 power-on hours)
- GPU/inference target: 64GB VRAM total, 30-40 tok/sec, primary model Qwen3.8 32B with headroom for small background models (Gemma 4B, Bonsai 3B, Qwen2.5:2B) simultaneously
- Will need a PCIe HBA (LSI 9300-8i IT-mode) for 6+ drives in RAIDZ2
- Water-cooled build planned: drain plug at lowest point with valve, pump/reservoir mounted low, quick-disconnects at GPU/CPU/radiator for future upgrades, clear/lightly-tinted tubing

### Office buildout AI hardware (Bullitt County office plan, separate from home 870 build)
- Primary AI inference server: AMD Ryzen AI Max 128GB Strix Halo box
- AI dev workstation/NAS: custom AMD X870E Glacial build (Ryzen 9 9950X3D, Radeon AI PRO R9700 32GB, 128GB RAM expandable) — this appears to be the office's own version of the 870-class build, separate from the home 870 Glacial above
- OPNsense routing, two-switch aggregation network with bonded 40G DAC uplinks
- Documented in a git-versioned docs repo at `github.com/bryanwills/office-plans`, using ProperDocs (see Resolved section above)

### Near-term "bridge" machines (while waiting on the 870/office builds)
- **eGPU local AI rig (purchased 2026-09-05, first power-on pending):** EVGA RTX 3090 Ti FTW3 Ultra 24 GB + Corsair RM1000x + Minisforum DEG2 V2 on Thunderbolt 5 into the current MacBook Pro. This is the active local-inference path for OpenJarvis and for fixing Hermes-class tool-calling without a hosted-model bill. Details: `docs/infrastructure/eGPU/ai-rig-build-log.md`.
- **Mac Mini M4 Pro** — decided purchase as the immediate headless AI machine, plus a TB4-to-10G adapter, a TB4 NVMe SSD, and a TB5-to-10G adapter for transfer speed testing against the current MacBook Pro
- **New MacBook Pro** — mentioned as a want (current one has display issues, charger was forgotten at least once during the Tailscale incident), no confirmed spec/purchase yet
- **Mac Studio M5 Ultra (256GB)** — planning to lease around its 9/22/2026 preorder release; explicitly wants an income-generating plan lined up to help offset the cost

### Networking hardware (home)
- Phase 1: 870 Glacial → starter 10GbE RJ45 switch (5-6 port + SFP+ uplink)
- Phase 2: half-rack QNAP 16-port switch (8×RJ45 + 8×SFP+, ~$600) + NAS + new Mac devices
- Firewall requirement: 10G SFP+ WAN, SFP+-only LAN, prefers open source, minimal maintenance, no outage risk from missed updates, open to FortiNet if it fits better
- Wants a separate SSID/VLAN for IoT devices; deciding between AT&T-provided modem vs bypassing via the ONT/optics directly
- No Home Assistant / HomeKit configured yet
- Wants a self-hosted, non-subscription smart camera setup, open-source-based but not fully from-scratch DIY

---

## Documentation & Repo Structure

**Local machine paths (confirmed accessible on this Mac):**
- `/Users/bryanwills/code/llc/office-plan` — this file lives here
- `/Users/bryanwills/code/llc` — LLC formation work generally
- `/Users/bryanwills/code/bbc/MealForge` — Meal Forge app
- `/Users/bryanwills/code/ai/OpenJarvis` — working OpenJarvis fork (prefer this)
- `/Users/bryanwills/code/jarvisai` — older jarvisAI experiments, do not merge blindly
- `/Users/bryanwills/code/bbc/neuro` — possible leftover Neuro Inclusion AI path; confirm before using
- `/Users/bryanwills/code/ai/translation_app` — LinguaBridge
- `/Users/bryanwills/code/bigbraincoding` — bigbraincoding.com stack
- `/Users/bryanwills/vps` — VPS/migration related work
- `/Users/bryanwills/.hermes` — Hermes Agent config
- `/Users/bryanwills/.gmail-mcp` — Gmail MCP config

**GitHub repos:**
- `github.com/bryanwills/dotfiles` — dotfiles, tracked via Git in `~/.config/`, chezmoi in no-Git mode (`sourceDir = ~/.config/chezmoi`, deliberately NOT git-initialized to avoid a submodule conflict with the parent `~/.config` repo)
- `github.com/bryanwills/docker` — Little Creek's Docker stack backup
- `github.com/bryanwills/office-plans` — docs repo for the Bullitt County office buildout, on ProperDocs
- `github.com/bryanwills/OpenJarvis` — fork of Stanford OpenJarvis; runtime code for the local command center
- `github.com/bryanwills/obsidian-bryans-journal` — private repo, Obsidian vault, daily journal + dated life-events notes + a `Work-Notes.md` documenting workplace incidents
- Claude Code CLI already set up on infrapoc and WSL2 via a private `claude-config` repo (GitHub Enterprise), symlinked into `~/.claude/`, with a seeded CLAUDE.md and two custom skills (`infra-remediation`, `nvim-dotfiles-context`). Being installed fresh on the MacBook Pro now specifically to drive the SSH setup and Little Creek → netcup migration directly.
- Beads (`gastownhall/beads`, Dolt-backed) identified as a candidate for structured cross-machine task memory, not yet implemented.
- Main Mac dev folder: `~/code`

## Dev Environment Conventions

- mise (runtime version manager) + uv (Python, replaces pip/conda/venv/pyenv) + pnpm (Node/JS) as the standard package manager stack
- zsh + oh-my-zsh + Powerlevel10k
- `alias cat="bat"` — scripts must call `/usr/bin/cat` explicitly to avoid breakage
- Work Lenovo: Intel Core Ultra 5 125U, 48GB RAM, Windows 11 Enterprise, WSL2 with a 1TB TB4 NVMe as ext4 storage at `/mnt/data`
- OneDrive convention: `~/onedrive/{folders}` directly, not nested under a display-name folder; selective Mac→OneDrive sync; GDrive as secondary backup
