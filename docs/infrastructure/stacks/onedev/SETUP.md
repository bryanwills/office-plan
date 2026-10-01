# OneDev on netcup (`onedev.bryanwills.dev`)

**Status:** Deployed 2026-09-30  
**Host:** netcup / `gateway` (`152.53.82.233`)  
**Docs:** [Run as Docker Container](https://docs.onedev.io/installation-guide/run-as-docker-container)

---

## Why netcup (not the AI-NUC)

Public `*.bryanwills.dev` already terminates TLS on this box. Traefik file-provider routes and `/opt/stacks/<name>/` are the house style. The NUC stays the GPU / Hermes / Ollama machine.

Forgejo is already live at `https://git.bryanwills.dev`. OneDev is a second forge (git + issues + CI). Do not assume one replaces the other until you pick a single source of truth.

---

## What's on the server

| Path | Role |
|------|------|
| `/opt/stacks/onedev/docker-compose.yml` | Compose (no host publish of `:6610`) |
| `/opt/stacks/onedev/.env` | First-boot admin + URLs (server only, mode `600`) |
| `/opt/stacks/onedev/data/` | Repos, embedded DB, artifacts |
| `/opt/stacks/traefik/dynamic/onedev.yml` | `onedev.bryanwills.dev` → `http://onedev:6610` |
| `/opt/backups/onedev/` | Backup target (empty until first backup) |

DNS A `onedev` → `152.53.82.233` was created before deploy.

---

## Security choices vs the official `docker run`

Official quick-start publishes `6610` and `6611` on all interfaces. That would punch a hole past UFW the same way Buzz's old `:3000` did.

This deploy:

- Joins the shared `proxy` network.
- Leaves HTTP **unpublished**. Browser traffic is Traefik `:443` only.
- Publishes **SSH git on `6611`** so `ssh://onedev.bryanwills.dev:6611` works. UFW also allows `6611/tcp`.
- Mounts `/var/run/docker.sock` so OneDev can run Docker executors. That is root-equivalent on this host. Keep registration closed. Do not let untrusted users create projects that run CI.

---

## First login

1. Open `https://onedev.bryanwills.dev`
2. User is `bryan` (see `.env` `INITIAL_USER`)
3. Password is in `/opt/stacks/onedev/.env` as `INITIAL_PASSWORD` — change it in the UI after login
4. `initial_*` env vars are first-boot only; editing `.env` later does not rotate the account

---

## Start / stop

```bash
ssh gateway-public   # or: ssh -i ~/.ssh/id_ed25519_gateway bryan@152.53.82.233
cd /opt/stacks/onedev
docker compose --env-file .env up -d
docker compose --env-file .env down
docker compose logs -f --tail=100
```

Traefik picks up `onedev.yml` automatically (`providers.file.watch=true`). Do not restart Traefik unless the file is ignored.

---

## Git remotes

HTTPS (through Traefik):

```text
https://onedev.bryanwills.dev/<project>
```

SSH:

```text
ssh://onedev.bryanwills.dev:6611/<project>
```

---

## Backup

```bash
cd /opt/stacks/onedev
docker compose --env-file .env stop
sudo mkdir -p /opt/backups/onedev
sudo tar -C /opt/stacks/onedev -czf /opt/backups/onedev/onedev-$(date +%Y%m%d).tar.gz data
docker compose --env-file .env up -d
```

Embedded HSQL is fine for a personal instance. Move to Postgres later if the data matters more than a tarball of `./data`.

---

## Argo CD (not this stack)

OneDev is Git + CI on Docker. Argo CD needs a Kubernetes cluster. Practice path is k3s + Argo on the AI-NUC (Tailscale UI), with this OneDev (or GitHub) as the Git source. Do not install k3s on netcup next to Traefik/Compose without a separate decision.

---

*Last updated: 2026-09-30*
