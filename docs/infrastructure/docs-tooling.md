# Documentation Tooling Risk — MkDocs Maintenance Situation

## Status: Open — needs a decision before November 2026

## What happened

- Original MkDocs (1.x) has had no releases in ~18 months and is effectively unmaintained as of 2026.
- A PyPI ownership dispute occurred in March 2026 between the original creator and a former maintainer.
- A proposed "MkDocs 2.0" rewrite would remove the plugin system entirely — incompatible with Material for MkDocs and the wider plugin ecosystem.
- Material for MkDocs (the theme this site uses) has stated its support window for classic MkDocs 1.x closes **November 2026** — no security patches after that.

## Successor options

| Option | Notes |
|---|---|
| Stay on classic `mkdocs` + `mkdocs-material` | Works today, zero config changes, but loses security-patch support after Nov 2026 |
| **ProperDocs** | Drop-in replacement by the last active MkDocs maintainer; `mkdocs.yml` config works as-is; swap CLI command only (`properdocs build`/`properdocs serve`) |
| **Zensical** | New engine from the Material for MkDocs team itself; positioned as the official forward path; compatible with MkDocs 1.x content |

## Decision

**Chosen: ProperDocs.** Lowest migration friction — `mkdocs.yml` config works as-is, only the CLI command and CI install/build steps changed. Local install via `uv tool install properdocs --with mkdocs-material`.

## Action items

- [x] Decision made — ProperDocs
- [ ] Confirm exact ProperDocs subcommands (`serve`, `build`, output directory) via `properdocs --help` once installed
- [ ] Get local preview working
- [x] `requirements.txt` updated to `properdocs` + `mkdocs-material`
- [x] `.github/workflows/docs.yml` updated — now builds via `properdocs build` and deploys through the native GitHub Actions Pages flow (`actions/upload-pages-artifact` + `actions/deploy-pages`) instead of a `gh-deploy`-style command, since ProperDocs gh-deploy parity wasn't confirmed
- [ ] Repo Settings → Pages → Source must be set to **GitHub Actions** (not "Deploy from a branch") to match the new workflow
- [ ] Revisit if ProperDocs stalls too — Zensical remains the fallback given it's from the Material for MkDocs team directly
