# OpenJarvis Command Center — product direction

**Status:** Direction locked 2026-09-06. Implementation starts on the 3090 Ti eGPU
once first power-on and local inference are confirmed.
**Owner:** Bryan Wills
**Working fork:** [github.com/bryanwills/OpenJarvis](https://github.com/bryanwills/OpenJarvis)
(from [open-jarvis/OpenJarvis](https://github.com/open-jarvis/OpenJarvis))
**Local checkout:** `/Users/bryanwills/code/ai/OpenJarvis`

This page is the standing brief for what Bryan is building. It is **not** a
license to copy Marvel branding, Peter Mach's product, or anyone else's voice.
Read it before proposing UI, names, greetings, or agent roles.

---

## What this is

A **local-first, voice-driven command center** that helps Bryan run his life
and businesses, then becomes a product for other neurodivergent people.

The daily loop, in one sentence: walk in, speak the way you already speak to
Claude in conversation mode, get a spoken brief, see the right dashboard on
the wall and the desk, approve or veto work that happened overnight, then go
do the rest of the day.

That is a working solution first. Content and a public demo come later, if
they earn a place. The system has to actually help ADHD executive function,
not just look like a movie.

---

## Two reference systems (and where Bryan sits)

Bryan is building **between** these two, with his own twist. Credit both. Copy
neither.

| | [Peter Mach / jarvis-agent.tech](https://jarvis-agent.tech/) | [Stanford OpenJarvis](https://github.com/open-jarvis/OpenJarvis) | This project |
|---|---|---|---|
| What it is | Paid "AI chief of staff" kit ($169 founder). HUD, five Slack agents, voice, playbooks. Runs on the ChatGPT or Claude plan you already pay for. | Apache-2.0 local-first personal AI stack. On-device agents, skills, energy/cost evals, morning-digest presets. Paper: [arXiv:2605.17172](https://arxiv.org/abs/2605.17172). | Fork of OpenJarvis, plus a voice + multi-monitor command center aimed at ND life and Bryan's real products. |
| Brain | Cloud subscription (Claude / ChatGPT). API key is optional. | Local models by default (Ollama), cloud only when needed. | **Local on the 3090 Ti.** No hosted-model bill to "make agents work." Hermes on netcup already proved 8-9B CPU models fail at tool-calling. The GPU is the fix. |
| Branding | Iron Man HUD, "Good evening, sir," walk-in greeting. Site disclaims Marvel, but the aesthetic is still that universe. | Research / Stanford. Neutral product name. | **Independent.** Different voice, different words, different greeting. Candidate consumer brand: Neuro Inclusion AI (`neuroinclusiveai.com`). Product name still open with the LLC. |
| Org model | Jarvis (chief of staff) plus Sarah / Tom / Bobby / Scout in Slack channels, handoffs, overnight work. | Built-in agents: morning digest, research, orchestrator, ReAct, operative, CodeAct. Skills from agentskills.io. | Keep the **org idea** (specialists + a brief + approvals). Staff it for Bryan's stack: ND assistant, trading (paper only), infra, content, community. Do not reuse their character names or copy. |

Peter's system is a useful existence proof that a morning walk-in, a spoken
brief, a wall HUD, and specialist agents can feel like one product. OpenJarvis
is the stack Bryan actually owns and can run locally. The work is to meet in
the middle: local inference, real dashboards, conversation-mode voice, ND-first
behavior, no House of Mouse.

---

## What the promo video actually does

Local copy (gitignored, do not commit): `media/ScreenRecording_Jarvis_AI_Agent.MP4`.
83-second Facebook vertical, captured 2026-09-06 from
[jarvis-agent.tech](https://jarvis-agent.tech/).

Physical setup in the clip:

- Sit-stand desk, three landscape monitors at eye level, one large wall display
  above the center (1-over-3).
- Wall screen is the HUD: dark blue, circular "core," side telemetry panels.
- Desk screens show specialist work: code / PRs, analytics, content, logs.
- Small always-on box on the desk (Mac Mini class). Voice in, voice out.

Spoken loop in the clip (paraphrased from captions, not a script to reuse):

1. Walk in. Ask how the business is doing.
2. Brief answers with numbers already gathered: last-7-day signups, organic
   posting cadence, ad spend and ROAS, support tickets auto-resolved vs
   escalated, a change ready for review, next content angles from research.
3. HUD stays up while the specialists' screens keep working.

That loop is the useful part. **Do not reuse the walk-in line from the Iron Man
films.** Bryan may want a tongue-in-cheek beat in a *promotional* video if this
ever ships that far. Daily use is a different voice, different words, nothing
that sounds like Tony Stark. The joke, if it exists, is original.

Bryan **does** want that many monitors on his desk. That is not a joke and not
optional in the long-term office plan.

---

## What Bryan's system has to show and do

Voice:

- Two-way conversation, closer to Claude conversation mode than a single
  "press a key and get a paragraph" prompt.
- Push-to-talk is acceptable for v1 if always-on wake-word is unreliable.
- TTS voice is original. No "sir." No borrowed catchphrases.

Surfaces (wall + desk, not one overloaded browser tab):

| Surface | Job |
|---|---|
| Wall HUD | Live brief: targets, health, what happened overnight, what needs a human. |
| ND assistant | The neurodivergent executive-function app: plans, prompts, body-doubling, therapist/psychiatrist *summary* research (HIPAA path is a later, separate track). |
| Trading | IBKR / Alpaca **paper** dashboards only. Human approval gate. No live orders from an agent. |
| Infra | netcup stacks, Hermes, Buzz, Tailscale, eGPU / Ollama health. |
| Content / community | Build-in-public notes, local ND contacts, later the public blog. |

Approvals stay gated. Agents may draft, escalate, and open PRs. Bryan approves
external messages, money, deletions, and anything that leaves the machine.

---

## Hardware this runs on (now)

Purchased 2026-09-05, documented in
[Local AI Inference Rig](eGPU/ai-rig-build-log.md):

- EVGA GeForce RTX 3090 Ti FTW3 Ultra (24 GB). Ti uses a single 12V-2x6, not
  dual 8-pin.
- Corsair RM1000x (1000 W) with the matching Corsair 12V-2x6 Type 4 cable.
- Minisforum DEG2 V2 eGPU dock, Thunderbolt 5 into the MacBook Pro.
- Models live on `/Volumes/OllamaDrive`.

This is the bridge while the 870 Glacial and office builds are still planning.
First power-on of the dock + GPU is **not done yet**. Do not assume CUDA or
tinygrad is working until the build log says so.

Why this GPU matters for the product: the 2026-08-30 Hermes session showed
that small **CPU-only** local models cannot reliably do agentic tool-calling.
Bryan's standing constraint is still **do not buy a hosted-model subscription
to paper over that**. The 3090 Ti is how local agents become usable.

Hermes on netcup remains the existing 24/7 gateway. OpenJarvis is the new
local product stack. How they share memory, voice, and Slack/Buzz channels is
an open architecture question. Do not silently retire Hermes.

---

## Branding and legal constraints (standing)

- Not affiliated with Marvel, Disney, or Stark Industries. Do not lean on
  that universe for marketing, voice, or chrome.
- Do not name agents Sarah / Tom / Bobby / Scout or clone their prompts.
- Do not ship a "Good evening, sir" greeting.
- OpenJarvis upstream is Apache-2.0. Keep license and attribution clean on
  the fork.
- Peter's site is a paid product with a 14-day refund. Treat it as inspiration
  and a competitor note, not a source tree.

---

## Community and "why this has to work"

Bryan is making more contacts in the local neurodivergent community. The
command center is not only a personal HUD. If it reduces his own load
(briefs, dashboards, overnight drafts, fewer tabs), it is also the demo for
Neuro Inclusion AI and for people who cannot run their lives from a pile of
apps.

Document the build in public once the local loop works. Do not promise a
product name or domain until the LLC decision lands.

---

## Next steps (do not reorder without asking)

1. Finish eGPU first power-on and prove a local model on the 3090 Ti
   (see the [build log](eGPU/ai-rig-build-log.md)).
2. Point Ollama / OpenJarvis at that GPU. Confirm tool-calling is better than
   the CPU 8-9B failure mode before designing the HUD.
3. Morning brief v0: one spoken summary from local sources Bryan already has
   (calendar, mail counts, stack health). No ad-account playbooks yet.
4. Split that brief across monitors: HUD on the wall, one product dashboard
   per desk screen.
5. Wire specialist agents to **Bryan's** products (ND app, paper trading,
   infra). Keep the approval gate.
6. Only then: promo-style video with an original tongue-in-cheek beat, if
   Bryan still wants one.

Prior art already on disk, separate from the fork: `/Users/bryanwills/code/jarvisai`
(older jarvisAI experiments). Do not merge it into the OpenJarvis fork without
a review.
