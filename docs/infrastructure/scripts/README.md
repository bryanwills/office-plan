# Gmail cleanup scripts

Deterministic, one-time cleanup scripts — no LLM involved, no Gmail
filters/labels created (Bryan doesn't use Gmail filters/labels). Each has a
`--dry-run` default (prints what would happen, changes nothing) and an
`--execute` flag to actually act + email a report to bryan@bryanwills.dev.
Both reuse the existing Gmail OAuth credentials already set up for the
Hermes Gmail MCP (`~/.gmail-mcp/{credentials.json,gcp-oauth.keys.json}` on
netcup) — same account, no new auth flow needed.

Run via the venv at `~/gmail-cleanup-venv` on netcup:
```bash
~/gmail-cleanup-venv/bin/python3 ~/gmail-backlog-cleanup.py [--execute]
~/gmail-cleanup-venv/bin/python3 ~/gmail-github-mark-read.py [--execute]
```

## gmail-backlog-cleanup.py
One-time backlog cleanup: unread Honey (`joinhoney.com`) + SlickDeals
(`slickdeals.net`) emails, July 3 2026 → today, moved to Trash (not
permanently deleted — Gmail auto-purges Trash after 30 days). Run 2026-08-30,
cleared 2,037 messages. Not a recurring rule — re-run manually if backlog
piles up again.

## gmail-github-mark-read.py
One-time cleanup: unread emails from `github.com` (CI failures, Dependabot
alerts, security advisories, digests) marked as read and **left in inbox**
(not trashed — Bryan wants to keep these). Run 2026-08-30, cleared 188
messages.

## Future feature idea (not built yet)
Bryan wants GitHub's "Explore" digest emails handled differently eventually:
when a digest highlights repos he's interested in, he currently manually
copies the repo URL into an open Chrome tab on his MacBook Pro to look at
later. He'd like this automated — **not** into a Chrome tab, but instead
saved as a link into his self-hosted **Linkwarden** instance (already running
as a Docker container, part of the existing bigbraincoding/Little Creek
stack — see `docs/infrastructure/stacks/`). Needs: parsing GitHub digest
email HTML for repo links, then pushing them to Linkwarden's API. Not
scoped or built — flagged here so it doesn't get lost.

## Overnight/autonomous LLM-driven inbox actions — explicitly rejected
2026-08-30: Bryan initially wanted a similar cleanup automated via an
unattended overnight Hermes (LLM) cron job. Rejected in favor of these
deterministic scripts after the same session demonstrated `ornith:9b`
needed multiple retries, misfired into unrelated tools (file search,
write_file, computer_use), and took 1-5+ minutes per turn even under live
supervision — too unreliable to trust unattended for real inbox actions.
Any future *proactive inbox monitoring* (watching new mail as it arrives
and using judgment about what to surface, e.g. via Hermes or a future
"Jarvis") is a different, harder problem that genuinely needs an LLM's
judgment — that's a separate project, not an extension of these
rule-based bulk scripts.
