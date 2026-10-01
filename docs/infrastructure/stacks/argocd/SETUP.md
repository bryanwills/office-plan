# Argo CD lab (`argo.bryanwills.dev`)

**Status:** Deployed 2026-09-30  
**Cluster:** k3d `gitops` on ai-nuc  
**Public TLS:** netcup Traefik → Tailscale `100.73.71.29:8081`  
**Upstream:** [Argo CD getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/)

This is a **practice cluster**. It does not manage netcup Compose stacks (Vault, Buzz, OneDev, nginx).

---

## Why the NUC, with a netcup hostname

Argo CD needs Kubernetes. netcup is Docker + Traefik for live sites. Same pattern as `ollama.bryanwills.org`:

```
browser  --443-->  argo.bryanwills.dev (netcup Traefik, Let's Encrypt)
                        │
                        │  Tailscale, not the AT&T WAN
                        ▼
                   ai-nuc 100.73.71.29:8081  (k3d load balancer, Tailscale bind only)
                        │
                        ▼
                   Ingress → argocd-server (HTTP insecure inside the cluster)
```

`:8081` is bound to the Tailscale address only. It is not on `0.0.0.0`.

---

## What's running on ai-nuc

| Piece | Detail |
|-------|--------|
| k3d | `~/.local/bin/k3d` v5.9.0, cluster name `gitops` |
| kubectl | `~/.local/bin/kubectl`, kubeconfig `~/.kube/config` |
| Argo CD | official `stable` manifests, namespace `argocd` |
| Ingress | `docs/infrastructure/stacks/argocd/ingress.yaml` |
| Insecure HTTP | `argocd-cmd-params-cm` `server.insecure=true` so Traefik can terminate TLS |
| `url` | `https://argo.bryanwills.dev` in `argocd-cm` |

---

## First login

1. Open `https://argo.bryanwills.dev`
2. User: `admin`
3. Password (do not store this in git):

```bash
export PATH="$HOME/.local/bin:$PATH"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

4. Change the password in the UI, then delete the bootstrap secret:

```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```

---

## Useful commands

```bash
export PATH="$HOME/.local/bin:$PATH"
kubectl -n argocd get pods
k3d cluster list
k3d cluster stop gitops
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

No Traefik restart. If the NUC or k3d is down, the name will 502 until the backend is back.

---

## What this is not

- Not GitOps for netcup `/opt/stacks`.
- Not a second production control plane on the VPS.
- Do not install k3s on netcup next to Traefik without a separate decision.

---

*Last updated: 2026-09-30*
