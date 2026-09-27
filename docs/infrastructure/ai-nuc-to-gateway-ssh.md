# Why ai-nuc could not SSH to gateway (and the git "up to date" mix-up)

**Date:** 2026-09-19  
**This is two different problems that felt like one.**

## Problem 1: the apply script is on the NUC, not on GitHub yet

`office-plan` on the Mac / GitHub can say **Already up to date** and still be missing `scripts/macbook/apply-ollama-traefik.sh`.

That file was committed **only on ai-nuc**:

```
738ea6a docs: explain why ollama.bryanwills.org points at netcup, not AT&T
e72c4fe docs: last-mile Traefik apply script and record live Paperless stack
```

`git push` from the NUC failed: this box has no GitHub HTTPS credentials and no `gh`. The Mac `git pull` talks to GitHub, not to the NUC. GitHub never received those two commits, so the Mac clone has nothing new to pull.

The script is already here:

```
/home/bryanwills/office-plan/scripts/macbook/apply-ollama-traefik.sh
```

You do **not** need to pull it on the Mac to finish Ollama HTTPS. After SSH works (problem 2), run that path **on this NUC**.

To unstick the Mac clone later, from a terminal that can auth to GitHub (Mac, or NUC after `gh auth login`):

```bash
# on ai-nuc, after GitHub auth exists
cd ~/office-plan
git push origin main
# then on the Mac
git pull
```

## Problem 2: SSH only went one way

There **was** an SSH key involving gateway, but it is the **wrong direction**.

| Key comment | Lives where | What it does |
|---|---|---|
| `bryan@gateway-to-ai-nuc` | `~/.ssh/authorized_keys` **on the NUC** | gateway is allowed to SSH **into** ai-nuc |
| `bryan@ai-nuc-to-gateway` | created 2026-09-19 on the NUC | ai-nuc is allowed to SSH **into** gateway (after you install the pubkey) |

SSH keys are not a shared password. The **private** key stays on the machine that starts the connection. The **public** key goes on the machine that accepts it.

ai-nuc had **no private keys at all** (`~/.ssh/` had only `authorized_keys` and `known_hosts`). So this box could not open a session to gateway, even though gateway can already come here.

Created on the NUC (do not copy the private key anywhere):

```
~/.ssh/id_ed25519_gateway
~/.ssh/config          # Host gateway → 100.90.171.127, user bryan
```

Public key (this is the only line you add on gateway):

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUrGbPRKwtaeWx4Qf0vBciLbi4KsuoFYaN9TsIgQ9U3 bryan@ai-nuc-to-gateway
```

### Install that pubkey on gateway (from the Mac, which already has SSH there)

```bash
ssh bryan@100.90.171.127
# or whatever host you already use for netcup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUrGbPRKwtaeWx4Qf0vBciLbi4KsuoFYaN9TsIgQ9U3 bryan@ai-nuc-to-gateway' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Then **on ai-nuc**:

```bash
ssh gateway 'hostname && ls /opt/stacks/traefik/dynamic'
bash ~/office-plan/scripts/macbook/apply-ollama-traefik.sh
```

If `ssh gateway` asks about the host key the first time, that is normal. Check it once, then type yes.
