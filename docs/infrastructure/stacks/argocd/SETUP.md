# Argo CD lab (`argo.bryanwills.dev`)

**Status:** Moved 2026-10-03  
**Cluster:** single-node k3s on littlecreek (`v1.36.5+k3s1`, node IP `100.85.240.30`)  
**Public TLS:** netcup Traefik → Tailscale `100.85.240.30:8081`  
**Upstream:** [Argo CD getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/)

The 2026-09-30 k3d cluster `gitops` on ai-nuc was stopped 2026-10-03 (`0/1` servers). The littlecreek admin password was changed the same evening and the bootstrap secret was deleted.

This is a **practice cluster**. It does not manage netcup Compose stacks (Vault, Buzz, OneDev, nginx).

---

## Why littlecreek, with a netcup hostname

Argo CD needs Kubernetes. netcup is Docker + Traefik for live sites. littlecreek is the single-node k3s control plane, so GitOps stays up while the NUC travels.

```
browser  --443-->  argo.bryanwills.dev (netcup Traefik, Let's Encrypt)
                        │
                        │  Tailscale, not the public NIC
                        ▼
                   littlecreek 100.85.240.30:8081  (Service externalIP only)
                        │
                        ▼
                   argocd-server (HTTP insecure inside the cluster)
```

`:8081` is on the Tailscale address only. Public `:8081`, `:80`, `:443`, and `:6443` on littlecreek are closed.

---

## What's running on littlecreek

| Piece | Detail |
|-------|--------|
| k3s | `v1.36.5+k3s1`, Ubuntu 24.04.5, kubeconfig `/etc/rancher/k3s/k3s.yaml` |
| kubectl | `sudo k3s kubectl` |
| Argo CD | official `stable` manifests, namespace `argocd` |
| Tailnet Service | `docs/infrastructure/stacks/argocd/tailnet-service.yaml` |
| Insecure HTTP | `argocd-cmd-params-cm` `server.insecure=true` so netcup Traefik can terminate TLS |
| `url` | `https://argo.bryanwills.dev` in `argocd-cm` |

---

## First login

1. Open `https://argo.bryanwills.dev`
2. User: `admin`
3. Password (do not store this in git):

```bash
sudo k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

4. Change the password in the UI, then delete the bootstrap secret:

```bash
sudo k3s kubectl -n argocd delete secret argocd-initial-admin-secret
```

---

## Useful commands

```bash
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl -n argocd get pods
```

ai-nuc k3d `gitops` is stopped (`0/1` servers). Start it again only to inspect the old cluster:

```bash
k3d cluster start gitops
```

Guestbook practice app (in-cluster only):

```bash
kubectl config set-context --current --namespace=argocd
argocd login argo.bryanwills.dev
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
argocd app sync guestbook
```

Git source can later be OneDev (`https://onedev.bryanwills.dev/<project>`) or GitHub.

---

## Start / stop the public route

Traefik file on netcup: `/opt/stacks/traefik/dynamic/argo.yml`  
Repo copy: `docs/infrastructure/stacks/traefik/dynamic/argo.yml`

No Traefik restart. If littlecreek or the `argocd-server` pod is down, the name will 502 until the backend is back.

---

## What this is not

- Not GitOps for netcup `/opt/stacks`.
- Not a second production control plane for the netcup Compose apps.
- Do not install k3s on netcup next to Traefik without a separate decision.

---

*Last updated: 2026-10-03*
