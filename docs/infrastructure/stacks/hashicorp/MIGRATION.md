# Hashicorp Vault migration: Little Creek → netcup

Status as of 2026-08-30: migrated and deployed. Container was already stopped
on Little Creek at migration time (Exited 4 weeks) — not actively serving,
migrated for continuity/data preservation rather than live cutover.

## What moved
- Config: `/home/bryanwi09/docker/hashicorp/{vault-config.hcl,entrypoint.sh}`
  → `/opt/stacks/hashicorp/` (copied as-is, no changes)
- Data: `/home/bryanwi09/docker/hashicorp/vault-data` (20K) →
  `/opt/stacks/hashicorp/vault-data` (copied at rest, container was stopped
  on the source so no live-copy concerns)
- Secrets (`GITHUB_OAUTH_CLIENT_ID/SECRET`, `GITHUB_OIDC_CLIENT_ID/SECRET_ID`,
  etc.): pulled from the stopped container's env config and piped
  server-to-server directly into `/opt/stacks/hashicorp/.env` on netcup —
  **never touched this repo or the local machine's disk**. `.env.example`
  in this directory documents the required keys with empty values.

## Verified
- `docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault status` on
  netcup confirms `Initialized: true`, `Total Shares: 5`, `Threshold: 3` —
  matches the original init parameters, confirming the migrated storage is
  intact and Vault correctly refused to re-initialize.
- Currently **sealed** (expected after any restart) — needs Bryan to run
  `vault operator unseal` with his existing key shares (3-of-5) manually;
  the AI agent does not have and should not handle these.

## Known pre-existing quirk (not introduced by migration)
`entrypoint.sh` runs `vault status`; if that call fails for **any** reason
(including a merely-sealed vault, not just an uninitialized one) it attempts
`vault operator init`. On this restart it triggered because `VAULT_ADDR=
https://keys.bryanwills.dev` wasn't resolvable yet (DNS still points to
Little Creek) — the resulting `vault operator init` call safely no-op'd
because Vault refuses to double-initialize existing storage. Worth revisiting
the script to check `Sealed` vs `Initialized` explicitly, but not changed
here per "don't modify existing configs without asking."

## Remaining
- ~~DNS: `keys.bryanwills.dev`~~ — cut over 2026-08-30, verified propagated
  and serving a valid Let's Encrypt cert on netcup.
- Bryan needs to manually unseal on netcup before use (his existing 3-of-5
  key shares — not something the AI agent has or should handle).
