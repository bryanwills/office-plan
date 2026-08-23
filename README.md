# office-plan

Working repo for standing up the LLC — formation, compliance, infrastructure, equipment, and the docs site that tracks all of it.

## Repo layout

```
office-plan/
├── docs/                    # MkDocs source — this is what builds into the docs site
│   ├── formation/           # entity/name decision, KY Articles of Organization, EIN, operating agreement
│   ├── finance/             # annual compliance calendar, tax research notes
│   ├── infrastructure/      # email/domain decision, cloud credit programs
│   ├── equipment/           # equipment list + the AMD AI Dev/NAS PC build plan
│   └── resources/           # self-employment / disability entrepreneur resources
├── mkdocs.yml                # site config
├── requirements.txt          # properdocs + mkdocs-material dependencies (pip-format, used by CI)
├── .github/workflows/docs.yml  # builds docs/ and deploys to GitHub Pages via GitHub Actions on push to main
└── pyproject.toml            # commitizen config (conventional commits)
```

## Docs site — local preview

```bash
cd ~/code/llc/office-plan
uv tool install properdocs --with mkdocs-material   # one-time; see uv install steps if `uv` isn't on PATH yet
properdocs serve   # confirm this is the right subcommand via `properdocs --help` — not yet verified
```
Opens at `http://127.0.0.1:8000`.

## Docs site — GitHub Pages setup (one-time)

1. Push this repo to GitHub (public repos get Pages free; private repos need a paid plan)
2. Repo Settings → Pages → Source: **GitHub Actions** (not "Deploy from a branch" — the workflow now builds and deploys directly via `actions/deploy-pages`, no `gh-pages` branch needed)
3. First push to `main` triggers the build, or trigger manually via Actions tab → "docs" → "Run workflow"

## Custom domain (docs.example.com)

1. Replace the placeholder in `docs/CNAME` with the real subdomain, e.g. `docs.bigbraincoding.com`
2. Add a CNAME DNS record at the domain registrar: `docs` → `<github-username>.github.io`
3. Repo Settings → Pages → Custom domain → enter the same subdomain, enable "Enforce HTTPS" once DNS propagates

## Placeholders still to update once the entity/name decision lands

- `mkdocs.yml`: `site_name`, `site_url`, `repo_url`
- `docs/CNAME`: final subdomain
- `docs/index.md`: status note at the top
- `docs/formation/entity-decision.md`: decision log entry
