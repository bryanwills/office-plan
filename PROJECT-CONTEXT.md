# Bryan Wills — AI Business & Infrastructure Context

**Purpose of this file:** This is a working context document for any AI agent (primarily Claude Code) picking up work on Bryan's AI business, homelab, and infrastructure projects. Read this in full before making changes to any system referenced here. This file will drift out of date — if something here conflicts with what you observe on a live system or in a repo, trust the live system and flag the conflict to Bryan rather than silently overwriting either.

**Last compiled:** August 29, 2026, from a chat conversation with Claude (claude.ai), corrected same day after Bryan flagged an inaccuracy. Bryan has emphasized this file needs to stay current — if he tells you something new that changes a plan below, update this file, don't just act on it and move on.

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
Executive-function AI assistant for neurodivergent people — "Pepper Potts" framing, proactive/anticipatory support rather than reactive. Hermes Agent is the preferred 24/7 gateway (NOT OpenClaw — that was configured once early on and never used further, despite what any other note might imply). Related real-world problem Bryan wants to solve: no easy way for a working professional's therapist to relay session data to a psychiatrist for medication management outside specific clinical settings; exploring AI-assisted session summary generation (HIPAA-compliant) as a therapist↔psychiatrist communication bridge, and sees a business opportunity there. Reference paper: arxiv.org/abs/2605.17172. Local repo path likely under `/Users/bryanwills/code/bbc/neuro`.

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
AI-assisted day trading using IBKR paper trading API first (hard rule: paper trading only until 30-45 days of live data gathered, human approval gate before any live order, no auto-execution ever without explicit validation). Multi-factor signal approach: quantitative/statistical, live news, geopolitical events, social sentiment, Polymarket/Kalshi data, macro factors. Two account strategies planned: realistic ($10k or less, real money) and research/benchmark ($50k max, comparison only). Also has an Alpaca account. Long-term inspiration: Humbled Trader, Ross Cameron/Warrior Trading style. Repos: github.com/bryanwills/freqtrade (fork), plus reference links to quant-trading repo and Humbled Trader's Claude+IBKR/TradingView MCP blog posts.

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
- `/Users/bryanwills/code/bbc/neuro` — likely OpenJarvis/Neuro Inclusion AI related
- `/Users/bryanwills/code/ai/translation_app` — LinguaBridge
- `/Users/bryanwills/code/bigbraincoding` — bigbraincoding.com stack
- `/Users/bryanwills/vps` — VPS/migration related work
- `/Users/bryanwills/.hermes` — Hermes Agent config
- `/Users/bryanwills/.gmail-mcp` — Gmail MCP config

**GitHub repos:**
- `github.com/bryanwills/dotfiles` — dotfiles, tracked via Git in `~/.config/`, chezmoi in no-Git mode (`sourceDir = ~/.config/chezmoi`, deliberately NOT git-initialized to avoid a submodule conflict with the parent `~/.config` repo)
- `github.com/bryanwills/docker` — Little Creek's Docker stack backup
- `github.com/bryanwills/office-plans` — docs repo for the Bullitt County office buildout, on ProperDocs
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
