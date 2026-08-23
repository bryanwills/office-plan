# Docs site setup

## Where these files go

Drop the contents of this delivery into `~/code/llc/office-plan/` — `mkdocs.yml`, `requirements.txt`, `README.md` at repo root, `docs/` and `.github/` as-is. Merge with any existing files rather than overwrite (this includes the equipment list file you already moved in — see `docs/equipment/index.md` for where to link it).

## Local preview

```bash
cd ~/code/llc/office-plan
pip install -r requirements.txt
mkdocs serve
```
Opens at `http://127.0.0.1:8000`.

## GitHub Pages setup (one-time)

1. Push this repo to GitHub (public or private — Pages works with both on paid plans; public repos get Pages free)
2. Repo Settings → Pages → Source: set to **Deploy from a branch**, branch **gh-pages**, folder **/ (root)**
   (The `gh-deploy` command in the workflow creates and pushes to `gh-pages` automatically — no manual branch creation needed)
3. First push to `main` (or manually run the workflow via Actions tab → "docs" → "Run workflow") triggers the build

## Custom domain (docs.example.com)

1. Replace the placeholder in `docs/CNAME` with your real subdomain, e.g. `docs.bigbraincoding.com`
2. Add a CNAME DNS record at your domain registrar: `docs` → `<your-github-username>.github.io`
3. Repo Settings → Pages → Custom domain → enter the same subdomain, enable "Enforce HTTPS" once DNS propagates (can take a few minutes to a few hours)

## Placeholders still to replace once the entity/name decision lands

- `mkdocs.yml`: `site_name`, `site_url`, `repo_url`
- `docs/CNAME`: final subdomain
- `docs/index.md`: the status note at the top
