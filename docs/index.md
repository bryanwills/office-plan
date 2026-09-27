# Business Formation & Operations Documentation

This site is the running record of standing up the LLC — every decision, filing, account, server, build log, and cost, documented as it happens so nothing has to be reconstructed from memory later.

!!! note "Status"
    Live at [docs.bryanwills.dev](https://docs.bryanwills.dev). Legal name, brand name, and company domain are still being decided — see [Entity & Name Decision](formation/entity-decision.md). The site name stays personal until that lands.

## Sections

- **[Formation](formation/entity-decision.md)** — the legal entity itself: name decision, KY Articles of Organization, EIN, banking, operating agreement.
- **[Finance & Compliance](finance/annual-compliance.md)** — annual report / LLET deadlines, and the tax research behind purchasing decisions.
- **[Infrastructure](infrastructure/email-and-domain.md)** — email/domain, VPS & hosting decisions (Little Creek → netcup migration), the netcup Docker stacks (Buzz, Vaultwarden, HashiCorp Vault, Nginx), local AI tooling (Cursor/Ollama, Claude Code, Honcho), Hermes troubleshooting history, and the local AI-NUC eGPU rig build.
- **[Equipment](equipment/index.md)** — office build plan plus the 3090 Ti eGPU bridge that is live-in-progress now.
- **[Trading Bot](trading/apexalgo-evaluation.md)** — ApexAlgo evaluation/architecture plan and the broader product & multi-agent architecture notes.
- **[Founder Notes](resources/disability-entrepreneur-resources.md)** — state/self-employment resources worth tracking, plus the documentation and build philosophy behind why everything here is logged this thoroughly.

**Current build focus (2026-09-16):** get the EVGA RTX 3090 Ti eGPU online, then run a local-first OpenJarvis command center on it, and keep this docs site current with everything already shipped instead of trailing behind it. Direction and branding constraints: [OpenJarvis command center](infrastructure/openjarvis-command-center.md). Hardware log: [eGPU rig](infrastructure/eGPU/ai-rig-build-log.md).

## How this site is built

- [MkDocs](https://www.mkdocs.org/) content and config, built with [ProperDocs](https://pypi.org/project/properdocs/) (a maintained, drop-in successor to classic `mkdocs`), styled with [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) plus a custom stylesheet (`docs/stylesheets/furo-style.css`) that reproduces the clean, minimal look of the [Furo](https://github.com/pradyunsg/furo) Sphinx theme — Furo itself can't run on this MkDocs-based pipeline, so this restyles Material to match its look instead of switching toolchains. See [Documentation Tooling Risk](infrastructure/docs-tooling.md) for why ProperDocs was chosen over staying on classic MkDocs or moving to Zensical.
- Built on the netcup VPS and served at `docs.bryanwills.dev` by nginx/Traefik.
- GitHub Actions workflow still builds Pages as a secondary copy on every push to `main` (`.github/workflows/docs.yml`).
- Every Markdown file under `docs/` is wired into the nav in `mkdocs.yml` — if you add a new doc, add it there too or it won't show up on the site.
- Custom domain set in the `docs/CNAME` file.
