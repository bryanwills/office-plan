# Nginx + PHP-FPM + website data migration: Little Creek → netcup

Status as of 2026-08-30: compose/config files deployed, website data copied
(sizes verified identical: bryanwills.dev 1.7G, bigbraincoding.com 3.3G),
nginx + php-fpm up on netcup, both domains verified returning 200 via
Traefik (IP/SNI test). DNS for `bryanwills.dev`/`bigbraincoding.com` (root +
www) has **not** been cut over — Little Creek remains the live site for both
domains until Bryan verifies via `/etc/hosts` and gives the go-ahead.

**Note on transfer method:** the first attempt (tar piped through
`ssh littlecreek | ssh netcup` run locally) routed data through the local
Mac's connection twice and crawled at ~0.4MB/s. Fixed by generating a
temporary ed25519 keypair on netcup, adding it to Little Creek's
`authorized_keys` (removed again after), and running `rsync` directly
netcup→littlecreek server-to-server (~4MB/s, ~10x faster). Worth reusing
this direct-path pattern for any future large-data stack migrations instead
of relaying through the local machine.

## What moved
- Configs: `nginx.conf`, `sites/bryanwills.dev.conf`,
  `sites/bigbraincoding.com.conf`, `php-fpm/php.ini`, `php-fpm/www.conf` —
  copied as-is (no content changes) to `/opt/stacks/nginx/` and
  `/opt/stacks/php-fpm/` on netcup.
- Data: `/var/www/bryanwills.dev/html` (1.7G) and
  `/var/www/bigbraincoding.com/html` (3.3G) — tar-piped directly
  server-to-server (Little Creek → netcup) into the same absolute path,
  since website content is host-level data, not part of `/opt/stacks`.
  Source was **not** stopped for this copy (static files, no live DB/WAL
  concern like Vaultwarden had).

## Routing change (same pattern as vaultwarden/vault)
Traefik's docker provider is disabled on netcup (Docker Engine 29.x / older
Traefik client API-version incompatibility — see
`traefik/docker-compose.yml`). Routing for both domains is defined
statically in `traefik/dynamic/nginx-sites.yml`, pointing at the `nginx`
container by name over the shared `proxy` network. The original Little
Creek nginx compose had `traefik.*` labels for docker-provider discovery —
dropped since they're inert here.

## Remaining — all done as of 2026-08-30 17:50 EDT
1. ~~Confirm data copy completed~~ — done, sizes match exactly.
2. ~~Bring up `nginx` + `php-fpm`~~ — done, both containers running.
3. ~~Bryan to verify both sites via `/etc/hosts` override~~ — done, both
   sites loaded correctly in Safari.
4. ~~Cut DNS~~ — done. Bryan cut `bryanwills.dev`, `bigbraincoding.com`,
   and `keys.bryanwills.dev` all at once (root + www for both site domains).
   Verified via `dig @1.1.1.1`/`@8.8.8.8` fully propagated. A Traefik
   restart was needed to trigger the ACME requests (same pattern as
   vaultwarden). Result: one multi-SAN Let's Encrypt cert covering
   `bryanwills.dev`, `www.bryanwills.dev`, `bigbraincoding.com`,
   `www.bigbraincoding.com` (valid through 2026-11-28), plus a separate cert
   for `keys.bryanwills.dev`. All 5 hostnames verified serving 200/307 with
   full SSL chain validation (no `-k` needed).
5. Little Creek's nginx/php-fpm decommission timing — still open, don't
   delete without asking first.
