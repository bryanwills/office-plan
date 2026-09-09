# Product and Architecture Notes

**Status:** Working document
**Owner:** Bryan Wills
**Scope:** Neurodivergent-focused applications, multi-agent architecture patterns,
trading analysis stack, and networking / partnership tracking.

---

## 1. Architecture Patterns Under Consideration

### 1.1 Blackboard architecture

A shared knowledge store that multiple specialist agents read from and write to,
with a control component deciding which agent acts next. Originated in speech
recognition research (Hearsay-II), widely used in systems where no single agent
has enough information to solve the problem alone.

**Why it fits this work:**

- It is inherently **stateless-friendly**. The blackboard holds state; agents do
  not. An agent can be killed and restarted without losing context, which is the
  same property the local-inference architecture is aiming for.
- It supports **heterogeneous agents**. A cheap fast model, an expensive
  reasoning model, and a plain deterministic script can all be participants.
  Nothing requires every contributor to be an LLM.
- It gives a natural **audit trail**. Every write to the blackboard is a
  timestamped record of which agent concluded what, which matters for both the
  trading use case and for any tool making recommendations to a user.

**Applied to trading analysis:**

| Agent | Reads | Writes |
|---|---|---|
| Price / technical | Market data feed | Indicator state, pattern flags |
| News | RSS, filings, press releases | Event records, materiality scores |
| Sentiment | Social APIs, forums | Sentiment deltas by ticker |
| Macro | Economic calendar, rates | Regime classification |
| Risk | Whole blackboard | Position sizing constraints, veto flags |
| Control | Whole blackboard | Which agent runs next, when to surface to human |

The human sits at the end as the execution approver. This matches the
approval-gated automation model already in use elsewhere.

**Applied to an executive-function assistant:**

| Agent | Reads | Writes |
|---|---|---|
| Calendar | Calendar connector | Time pressure, upcoming commitments |
| Task | Task store | Open items, staleness, dependencies |
| Capacity | User check-ins, time of day | Current available capacity |
| Decomposition | Blocked task + capacity | One concrete next action |
| Surface | Whole blackboard | What to show, what to suppress |

The important design property: the **Surface** agent decides what NOT to show.
An assistant for overwhelm that surfaces everything it knows is a worse
experience than no assistant at all.

### 1.2 Hierarchical Task Network (HTN) planning

HTN planning decomposes an abstract goal into subtasks recursively until every
leaf is a primitive action. This is the established literature most relevant to
executive-function support, because the core failure mode being addressed is
"I know the goal, I cannot find the first step."

Related and well-documented: **PDDL** (Planning Domain Definition Language),
the standard formalism for expressing planning domains and problems.

**Note on terminology:** "LTML" as a planning language could not be verified
against established literature. If a specific source is found, add it here.
Until then, HTN and PDDL are the searchable, documented starting points.

### 1.3 Game theory, applied correctly

Game theory is not a price prediction tool. Where it legitimately applies:

- **Mixed strategies in execution.** A deterministic entry pattern traded at
  size is exploitable. Randomizing execution timing and sizing within a
  strategy's tolerance is a defensive technique, not an edge-generating one.
- **Adverse selection.** Understanding who is on the other side of a fill, and
  why they are willing to take it, is a risk-management frame.

---

## 2. Trading Analysis Stack

### 2.1 What LLMs do and do not do here

**Do not:** predict price. No model does this. Any resource claiming otherwise
is either overfit backtesting or a sales pitch.

**Do:**

- Parse unstructured text (filings, transcripts, news) into structured records
- Classify materiality and sentiment at volume
- Generate and refactor backtest and strategy code
- Explain drawdowns and summarize parameter sweeps after the fact
- Triage anomalous bot behavior from logs

Signal generation itself stays quantitative: feature engineering, statistical
models, walk-forward validation, out-of-sample discipline.

### 2.2 Model selection criteria

Ranked by what actually matters for this workload:

1. **Context length.** Multiple documents plus price history in one prompt.
2. **Structured output reliability.** JSON out, every time, no parsing hacks.
3. **Throughput.** High-volume extraction is a latency path.
4. **Reasoning depth.** Only for periodic synthesis, not the hot path.

**Suggested split:**

- Fast extraction tier: an 8B-class model at Q4, high volume, low latency
- Synthesis tier: a 30B-class MoE model, run periodically, not per-event
- Audit tier: a reasoning model, run on demand when explaining a decision

Do not use one model for all three roles.

### 2.3 Quantization on Ampere (RTX 3090 Ti)

Hardware constraint worth recording, since it rules out several popular options:

| Format | Ampere (SM 8.6) support | Notes |
|---|---|---|
| GGUF Q4_K_M / Q5_K_M | Yes | Primary choice. Mature, good quality retention. |
| AWQ / GPTQ INT4 | Yes | Native INT4 tensor cores. Good with vLLM. |
| EXL2 | Yes | Fastest single-user option on Ampere. |
| FP8 | No native support | Requires Ada / Hopper, SM 8.9+ |
| NVFP4 | No native support | Blackwell only |

Reference material using NVFP4 or FP8 on DGX Spark / GB10 hardware is
methodologically interesting but not directly transferable.

---

## 3. Neurodivergent-Focused Product Direction

### 3.1 Positioning

The differentiator is **functional, not informational**. The space already has
good directories and good content. What is thin on the ground is tooling that
actually does the executive-function work rather than explaining it.

Design principles worth committing to early:

- **Suppression is a feature.** Deciding what not to show is the hard part.
- **One next action, not a list.** A list is another thing to be overwhelmed by.
- **No streaks, no guilt mechanics.** Gamification that punishes gaps is
  actively harmful for this audience.
- **Sensory-aware defaults.** Motion, sound, and notification density all need
  conservative defaults and real controls.
- **Local-first where possible.** Privacy is a genuine concern for this user
  base, and it aligns with the sovereign-AI direction already underway.

### 3.2 Candidate application concepts

Not committed, listed for evaluation:

| Concept | Core function | Notes |
|---|---|---|
| Task decomposer | Takes a blocked task, returns one concrete first step | Directly HTN-shaped |
| Capacity-aware planner | Adjusts the day's plan to stated current capacity | Requires honest self-report UX |
| Context re-entry | Reconstructs where you left off after an interruption | High value, underserved |
| Sensory load logger | Tracks environment against subjective load | Feeds the planner |
| Communication drafter | Turns a rough intent into a sendable message | Approval-gated |
| Decision journal | Records what was decided and why, for later recall | Also serves the trading work |

Context re-entry is worth flagging as the most differentiated idea in this
list. Existing tools help you plan; almost none help you resume.

---

## 4. Networking and Partnership Tracking

### 4.1 AuDHD Stuff — https://audhdstuff.com

Curated resource directory for ADHD, autism, and AuDHD adults. Operated by
AGI Logic LLC. Content is organized by resource type (books, websites,
podcasts, videos, tools, products, communities) and by experience (ADHD,
autism, AuDHD), plus situational guides such as "I can't start anything today."

Editorial model: dated reviews, an original editorial take per listing, and a
published editorial policy, ranking methodology, and affiliate disclosure.
Monetized through Amazon Associates.

**Relationship assessment: complementary, not competing.** The site aggregates
and evaluates existing resources. The direction in section 3 is functional
tooling. A tool that is genuinely useful is a candidate for listing there, and
the operator's stated audience focus on creators suggests openness to
partnership.

**Approach when ready:** lead with a working artifact, not a pitch. A landing
page plus a demonstrable tool is a materially stronger opening than a
description of intent.

### 4.2 Kentucky Alternative Care, Louisville KY

Staff contact expressed willingness to introduce the director for networking
purposes. Logged as a warm lead.

**Preparation before that conversation:**

- A one-page description of what is being built and who it serves
- A live URL, even if it is only a landing page
- A clear statement of what is being asked for (introductions? feedback?
  pilot users?) rather than an open-ended ask

### 4.3 Pre-outreach checklist

- [ ] Landing page live for the LLC or product
- [ ] Linktree or equivalent single-link profile
- [ ] Social accounts registered under a consistent handle
- [ ] One-paragraph description that does not require technical background
- [ ] One demonstrable artifact, however small

---

## 5. Open Questions

- Verify whether "LTML" refers to a specific documented planning language, or
  whether HTN / PDDL cover the intended concept
- Decide whether the trading stack and the assistant share a blackboard
  implementation or remain separate systems
- Determine data sources and licensing for any social sentiment input, since
  most major platforms restrict automated collection
- Establish what "capacity" means operationally in a way a user can report in
  under five seconds
