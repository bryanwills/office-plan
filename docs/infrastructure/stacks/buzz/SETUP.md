# Buzz setup on netcup

Status as of 2026-08-30: deployed and live at `https://buzz.bryanwills.dev`.
Relay owner bootstrapped. Waiting on Bryan to install the desktop client and
import his owner identity.

## What's deployed
- Repo: `/opt/stacks/buzz` (cloned from `github.com/block/buzz`, tracking
  `main` — no semver-tagged container images exist upstream yet, confirmed
  via the ghcr.io registry API; `main`/`latest`/`sha-<7>` are the only
  options).
- Compose stack: `/opt/stacks/buzz/deploy/compose/` (relay, Postgres, Redis,
  MinIO) — the project's own production bundle, not the root
  `docker-compose.yml` (dev-only).
- Secrets: `.env` on the server only (gitignored), never committed. DB/Redis/
  S3/git-hook-hmac secrets and the relay's own signing key were all
  freshly generated (openssl/python3, no reused values).

## Identity
- `RELAY_OWNER_PUBKEY` was generated fresh (proper BIP-340/secp256k1
  derivation — Nostr pubkeys are x-only, not a plain random value) and set
  as the closed-relay owner.
- **The corresponding private key is NOT stored on the server or in this
  repo.** It's in `~/buzz-owner-nsec-DELETE-AFTER-IMPORT.txt` on Bryan's
  Mac. Bryan needs to:
  1. Install the Buzz desktop app (prebuilt, no local build needed):
     `Buzz_0.5.20_aarch64.dmg` from
     `github.com/block/buzz/releases/tag/desktop-v0.5.20` (Apple Silicon).
  2. Point it at `wss://buzz.bryanwills.dev`.
  3. Import the private key from that file as the identity.
  4. Delete the file once imported — it's a bearer secret for the owner
     identity, don't leave it sitting around.

## Routing / security fix applied
Buzz's own compose bundle publishes the relay on host port 3000 by default
(meant to be fronted by Caddy via `compose.caddy.yml`, which strips the port
publish with `ports: !reset []` when `BUZZ_COMPOSE_TLS=true`). Since this
box already runs Traefik for everything else, Caddy wasn't used — instead:

- `compose.traefik.yml` (this repo, copied to
  `/opt/stacks/buzz/deploy/compose/compose.traefik.yml`, **not part of the
  upstream repo** — survives a `git pull` in `/opt/stacks/buzz` untouched)
  applies the same `ports: !reset []` trick and joins the relay to the
  shared `proxy` Docker network instead.
- `traefik/dynamic/buzz.yml` routes `buzz.bryanwills.dev` → `http://relay:3000`
  over that network.

**Found and fixed during setup:** before this override was applied, port
3000 was reachable directly from the public internet
(`http://152.53.82.233:3000`) despite `ufw` only listing 22/80/443 —
Docker's own iptables rules bypass `ufw`'s filtering for published ports.
Verified closed after the override (`curl` to the direct port now fails;
routing through Traefik still works, `200` on `/_liveness`).

## Starting/stopping (always pass both compose files — `run.sh` doesn't know
about the Traefik override)
```bash
cd /opt/stacks/buzz/deploy/compose
docker compose --env-file .env -f compose.yml -f compose.traefik.yml up -d
docker compose --env-file .env -f compose.yml -f compose.traefik.yml down
```

## DNS
`buzz.bryanwills.dev` already had an A record pointing at netcup's IP before
this setup — likely a leftover from an earlier, incomplete Buzz attempt
(per `docs/infrastructure/vps-hermes-buzz-setup.md`, dated 2026-08-22). No
new DNS record was needed.

## Remaining
- Bryan: install desktop client, import owner key, delete the key file.
- Not yet configured: agent identities/keys for AI agents to join channels
  (`buzz-cli`, `BUZZ_PRIVATE_KEY` per-agent) — separate from the owner setup
  above, do this once Bryan has logged in as owner and has channels/projects
  to actually assign agents to.
- Consider whether `buzz.bryanwills.dev` is the final domain choice long
  term, given the open personal/business/LLC naming questions in
  `PROJECT_STATE.md` — flagged there, not re-litigated here.
