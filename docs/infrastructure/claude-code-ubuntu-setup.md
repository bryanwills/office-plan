# Claude Code on Ubuntu Linux (local AI / Ollama machine)

**Context:** This covers installing and configuring Claude Code (the CLI) on an Ubuntu Linux box that is also running Ollama for local model inference — currently the target is the **Minisforum MS-01** ("the NUC", Ubuntu 24.04 LTS), which will also host the eGPU-connected RTX 3090 Ti for local models. Claude Code itself talks to Anthropic's hosted API; it is not the thing running against the local Ollama models. Its role here is to be the terminal coding agent used to work on this `office-plan` repo (and other repos) directly on that machine, so the setup below is the same as any other dev box — the Ollama/GPU context just explains *why* this particular machine needs it.

---

## 1. Prerequisites

- Ubuntu 24.04 LTS (or 22.04 — both supported)
- A user account with sudo access
- Node.js **18 or newer** — Claude Code is distributed as an npm package
- Git (needed to work with this repo and any others)

Check what's already there:

```bash
lsb_release -a
node -v      # want >= 18
npm -v
git --version
```

## 2. Install Node.js (if missing or too old)

Ubuntu's default apt `nodejs` package is often outdated. Use NodeSource's setup script for a current LTS release:

```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v
npm -v
```

Alternative if you'd rather manage Node versions per-project (useful since this box will likely run other AI/dev tooling too): install [nvm](https://github.com/nvm-sh/nvm) instead of the system Node, then `nvm install --lts`.

## 3. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
claude doctor   # sanity-checks the install and environment
```

If `npm install -g` fails on permissions (common with a system Node install where global packages need root), don't `sudo npm install -g` — that causes ownership headaches later. Instead fix npm's global prefix once:

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code
```

## 4. First run / authentication

```bash
claude
```

On first launch it walks through auth in the browser (or paste-a-link flow if there's no local browser on this headless-ish box — the MS-01 may be run headless most of the time). Sign in with the same Anthropic account used elsewhere (Claude Pro/Max or Console/API billing, whichever this account uses).

If the MS-01 is being accessed over SSH without a browser available on the box itself, `claude` will print a URL to open on another device (e.g. the MacBook Pro) to complete login — same pattern as any CLI OAuth flow.

## 5. Point Claude Code at this repo

```bash
git clone https://github.com/bryanwills/office-plan.git ~/code/llc/office-plan
cd ~/code/llc/office-plan
claude
```

Claude Code reads `CLAUDE.md` files in the repo (and `~/.claude/CLAUDE.md` for global/user-level instructions) automatically — if there's an existing global CLAUDE.md on the Mac worth carrying over to this machine, copy it to `~/.claude/CLAUDE.md` on the Ubuntu box. Project-level instructions live in the repo itself and travel with the clone.

## 6. Relationship to Ollama on this machine

Claude Code and Ollama are independent processes that happen to share the box:

- **Ollama** serves local models (e.g. the planned Qwen3.8:27B once the eGPU rig is powered on) over its own local API, typically `http://localhost:11434`.
- **Claude Code** is a separate CLI that calls Anthropic's hosted API over the network — it does not route through Ollama and doesn't need it running to work.

They don't conflict; both can run at once. The only shared resource is machine RAM/CPU (and GPU once the eGPU is live) — Ollama serving a large local model will compete for RAM with anything else running, so keep that in mind if Claude Code (or other tooling) feels sluggish while a big Ollama model is loaded.

If a future workflow wants Claude Code to actually call the local Ollama model (e.g. as an MCP tool, or via an Ollama-compatible endpoint), that's a separate integration to design — not part of base install. Flag as a later task if/when relevant, not attempted here.

## 7. Useful day-to-day commands

```bash
claude              # start an interactive session in the current directory
claude doctor        # diagnose install/config issues
claude --version     # confirm version
claude update        # or: npm update -g @anthropic-ai/claude-code
```

## 8. Keeping it updated

```bash
npm update -g @anthropic-ai/claude-code
```

Claude Code also self-checks and can prompt for updates on launch, but running the npm update periodically (especially after not using the box for a while) avoids drift from the Mac's Claude Code version.

## Open items

- MS-01 delivery/first-boot status — see `PROJECT_STATE.md` §5a-now for current state (as of 2026-09-07, not yet powered on).
- Whether this box runs Claude Code interactively (SSH'd in from the MacBook Pro) or ends up part of the OpenJarvis command-center automation — undecided, see `docs/infrastructure/openjarvis-command-center.md`.
