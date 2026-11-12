# Benchmarks & Case Studies

**Status:** Draft, 2026-11-12. Method defined; no assistant runs logged yet.
**Owner:** Bryan Wills
**Scope:** How the assistant and its hardware are measured, how real-life case
studies are written, and where both get published.

---

## Why this page exists

The goal is to build this the way an engineering lab would: hypothesis,
method, measurements, results, and what changed, all written down as it
happens. That is what turns "it feels faster" into something worth publishing,
and it is the evidence behind every claim the product will ever make. The
reasoning behind that standard is in
[Documentation & build philosophy](../response.md).

---

## What gets measured

### Assistant

| Metric | How it is measured | Target to beat |
|---|---|---|
| Button-to-first-word latency | Timestamp at button release and at first audio out | Set after the first baseline run |
| Transcription word error rate | Fixed script of test phrases, read in a quiet room and a noisy room | Set after baseline |
| Filing accuracy | Share of captures tagged and filed correctly, checked by hand weekly | Set after baseline |
| First-step usefulness | Did the suggested first step get done? Yes or no, logged per use | Set after baseline |
| Tool-call success rate | Share of agent tool calls that complete without a retry | Beat the CPU-only 8 to 9B baseline from the Hermes troubleshooting |
| Local-only leak test | Outbound traffic captured during a full local-mode session | Zero unexpected destinations |

### Models and hardware

| Metric | How it is measured |
|---|---|
| Tokens per second (prompt and eval) | Same benchmark script used in the [eGPU build log](../infrastructure/eGPU/ai-rig-build-log.md) |
| VRAM headroom | `nvidia-smi` while Whisper and the chat model are both loaded |
| Cold start time | Time from first request to first token after the model is unloaded |

### Capture devices

Press-to-saved latency, word error rate, battery life under a fixed schedule,
missed or accidental captures per week, and whether it got worn. See the
[hardware roadmap](wearables-and-hardware.md).

---

## Benchmark run template

Copy this block into a new page or log entry for every run.

```markdown
## Run: <short name>, <YYYY-MM-DD>

- **Hypothesis:** <what you expect and why>
- **Setup:** <machine, GPU, model and quantization, Whisper size, device, firmware version>
- **Method:** <exact steps or script, with the command>
- **Data:** <table or attached CSV>
- **Result:** <numbers, compared to the last run>
- **What changed because of this:** <config, code, or plan change, or "nothing">
- **Raw files:** <path in the repo>
```

---

## Case studies

A case study is one real situation the assistant was used for, written up
plainly: the problem, what the assistant did, what worked, what did not, and
what changed afterward. Private details stay out; the pattern is what matters.

Candidate first case studies:

| Case study | What it tests |
|---|---|
| Preparing for a work trip (packing list, outfits, documents, not forgetting items) | Capture, checklists, timely nudges |
| A week of morning briefs | Brief quality, what got suppressed, what was missed |
| Coming back to a project after a week away | Context re-entry |
| Turning stuck tasks into first steps | First-step usefulness |
| Physical routines with NFC tags | Whether a tag tap beats remembering |

### Case study template

```markdown
# Case study: <title>

**Dates:** <start> to <end>
**Surfaces used:** <web, phone, watch, device>

## The problem
<one paragraph, in plain words>

## What the assistant did
<what was captured, suggested, reminded, drafted>

## What worked
## What did not
## Numbers
<links to benchmark runs>

## What changed afterward
```

---

## Where it gets published

1. Raw runs and case studies land on this docs site first, as Markdown in the
   repo, so they are versioned.
2. The readable story goes to the blog at
   [blog.bryanwills.dev](https://blog.bryanwills.dev).
3. Anything solid enough becomes a longer write-up, and eventually a paper.

Daily logs are fine. Waiting until the end to write it all up is not.
