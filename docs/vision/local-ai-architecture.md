# Local-First AI Architecture

**Status:** Draft, 2026-11-12. The GPU, gateway, and memory pieces are running.
The assistant is not wired to them yet.
**Owner:** Bryan Wills
**Scope:** Where the assistant's models run, how requests reach them, when the
cloud is allowed, and how the same design works for other users who do not own
a GPU.

---

## The principle

Run models on hardware you own when that is good enough. Use the cloud when it
is clearly better or when local hardware is not available, and say so when it
happens. Keep state (memory, captures, logs) separate from compute so any
machine can be swapped without losing anything. That is the same "stateless
compute, stateful data" rule the rest of this site follows.

---

## What exists today

| Piece | Where | State | Docs |
|---|---|---|---|
| RTX 3090 Ti 24 GB eGPU on a Minisforum MS-01 (ai-nuc) | Home | Working since 2026-09-08 | [Build log](../infrastructure/eGPU/ai-rig-build-log.md), [Recovery](../infrastructure/eGPU/ai-nuc-egpu-buildlog.md) |
| Ollama with Qwen-class models up to about 32B at Q4 | ai-nuc | Working; benchmarked | [Build log](../infrastructure/eGPU/ai-rig-build-log.md) |
| Public HTTPS gateway for Ollama with a bearer key | netcup, then Tailscale to ai-nuc | Working | [Ollama HTTPS](../infrastructure/ollama-public-https.md) |
| Self-hosted Honcho (agent memory) | ai-nuc | Running | [Honcho on ai-nuc](../infrastructure/honcho-ai-nuc-setup.md) |
| Hermes Agent (24/7 gateway) | netcup | Running | [VPS Hermes & Buzz](../infrastructure/vps-hermes-buzz-setup.md) |
| Open WebUI, SearXNG, Paperless | ai-nuc | Deployed or in progress (see each stack page) | [ai-nuc stacks](../infrastructure/stacks/ai-nuc-stacks-setup.md), [SearXNG](../infrastructure/searxng-ai-nuc.md) |
| Starter voice web app (FastAPI, Whisper, swappable LLM) | Not deployed yet | Built | [The assistant](assistant.md) |

---

## Request path

```text
 capture device / phone / watch / web page
            |
            |  HTTPS or Tailscale
            v
 assistant backend (FastAPI)  ----->  speech to text (Whisper on GPU)
            |
            |  model router
            +---------> local:  Ollama on ai-nuc (3090 Ti), over Tailscale
            |
            +---------> cloud:  OpenAI-compatible API, only when the policy allows
            |
            v
 state: inbox, memory (Honcho), decision log, benchmark logs  (separate disk, backed up)
```

The backend already speaks to every LLM through one interface (mock, Ollama,
or OpenAI-compatible), so moving a request from local to cloud is a
configuration change, not a rewrite.

---

## Routing policy (first draft)

| Request type | Default | Cloud allowed? |
|---|---|---|
| Speech to text | Local Whisper on the GPU | Only if the GPU is down, and the user is told |
| Capture filing and tagging | Small local model (3B to 8B class) | No |
| First step, re-entry, morning brief | Mid-size local model (about 27B to 32B class) | Fallback only, marked in the reply |
| Long documents or heavy reasoning | Local first; cloud if the context does not fit | Yes, with the user's setting turned on |
| Anything holding another person's private data | Local | No |

Every routed request is logged with the model, where it ran, latency, and token
counts. Those logs feed the benchmarks.

---

## Reachability

- Personal devices reach ai-nuc over Tailscale.
- Where Tailscale is not available, devices use the HTTPS gateway on netcup,
  which proxies over Tailscale to the GPU box. No home router port forwarding.
- If ai-nuc is offline (it can travel), the router falls back to the next
  available node, then to cloud if the user allows it.

The longer-term idea of routing each task to the best-fit node (big GPU for
heavy work, Pi or VPS CPU for small work) is the inference scheduler research
track noted in `PROJECT_STATE.md` section 4d. It is separate from this page.

---

## How this works for other users

Most people will not own a 3090 Ti. The product supports four modes, set per
user and visible in settings:

| Mode | Who it fits | Where models run |
|---|---|---|
| On-device | Privacy-first users with recent phones or laptops | Small models on the device; fewer features |
| Self-hosted | Technical users with their own GPU box or homelab | The user's own Ollama endpoint |
| Hosted private | Most users | A managed instance run by the business, with no training on user data |
| Bring your own key | Users who already pay for a cloud model | Their own API key, their own provider |

The same backend code serves all four. Only the router's endpoint list changes.

---

## Security baseline

- No personal data leaves the user's devices or the chosen backend except for
  cloud calls the user has allowed.
- A gatekeeper layer (API gateway with keys and rate limits) sits in front of
  every model endpoint that is reachable from outside the tailnet.
- Secrets live in Vaultwarden or HashiCorp Vault, never in a repo.
- Regular end-to-end tests, including a "local mode sends nothing out" test
  that watches outbound traffic during a full capture and brief cycle.
- Security testing tools run from a separate VPS, not from the production
  host.

---

## Open questions

- Which Whisper model size gives the best accuracy per second on the 3090 Ti
  alongside a 27B chat model in the same 24 GB.
- Whether to serve chat models through Ollama long term or move to vLLM for
  better throughput once there are multiple users.
- How the hosted private mode is isolated per user (separate keys and stores at
  minimum).
- Docker Compose today, Kubernetes later: when the move is worth it.
