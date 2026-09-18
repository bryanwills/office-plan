# Business Formation & Operations Documentation

This site is the running record of standing up the LLC — every decision, filing, account, and cost, documented as it happens so nothing has to be reconstructed from memory later.

!!! note "Status"
    Live at [docs.bryanwills.dev](https://docs.bryanwills.dev). Legal name, brand name, and company domain are still being decided — see [Entity & Name Decision](formation/entity-decision.md). The site name stays personal until that lands.

## Sections

- **Formation** — the legal entity itself: name decision, KY Articles of Organization, EIN, banking, operating agreement
- **Finance & Compliance** — annual report / LLET deadlines, and the tax research behind purchasing decisions
- **Infrastructure** — email/domain, netcup stacks, Hermes, Buzz, and the local OpenJarvis command center
- **Equipment** — office build plan plus the 3090 Ti eGPU bridge that is live-in-progress now
- **Founder Resources** — state/self-employment resources worth tracking

**Current build focus (2026-09-06):** get the EVGA RTX 3090 Ti eGPU online, then run a local-first OpenJarvis command center on it. Direction and branding constraints: [OpenJarvis command center](infrastructure/openjarvis-command-center.md). Hardware log: [eGPU rig](infrastructure/eGPU/ai-rig-build-log.md).

## How this site is built

- [ProperDocs](https://properdocs.org/) + [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- Built on the netcup VPS and served at `docs.bryanwills.dev` by nginx/Traefik
- GitHub Actions workflow still builds Pages as a secondary copy (`.github/workflows/docs.yml`)
