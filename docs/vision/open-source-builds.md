# Open-Source Builds

**Status:** Draft, 2026-11-12. All planned; none started.
**Owner:** Bryan Wills
**Scope:** Personal "build my own version" projects. These are for learning,
practice, and portfolio. They are not products and are not for sale.

---

## Why these exist

When a paid tool is genuinely good, the habit here is to build an open-source
version (or improve an existing one) instead of just paying for it. Each build
teaches a skill the main product needs: speech, video, health-style data,
native apps, a new language. Each one also becomes a public repo and a build
log.

---

## Clean-room rules (apply to every build on this page)

These keep the work original and inside the vendors' terms of service.

- **Build from public behavior and open models only.** Use the product as a
  normal user would, read its public docs and marketing, and read published
  research. Then design your own version.
- **Do not decompile, disassemble, or unpack the vendor's apps or firmware.**
  Do not intercept or call their private APIs.
- **Do not copy code, UI assets, icons, text, voices, or sample content.**
- **Do not use the vendor's name or trademarks** in the project name, repo
  name, or app icon. "A Synthesia-style tool" is fine as a description in a
  README; it is not a product name.
- **Keep a sources log** in each repo: every public page, paper, and open
  model used, with dates. That log is the record that the build is clean.
- **Check every open model's license** before using it. Several popular speech
  and avatar models are non-commercial only.
- **Personal and portfolio only.** If any of these ever turns into something
  to sell, it gets a legal review first.

---

## Planned builds

### 1. AI training-video generator (Synthesia-style)

**Idea:** turn a script plus screenshots into a narrated training video, with
your own API keys or fully local models.

| Part | Open approach |
|---|---|
| Script writing | Local LLM on the 3090 Ti, or bring your own key |
| Slides and screenshots | Markdown slides rendered to images; screenshots annotated with outlines and arrows |
| Narration | Open TTS models that run locally (for example Piper or Kokoro), licenses checked |
| Optional presenter | Open talking-head or lip-sync models, only ones whose license allows the use |
| Assembly | FFmpeg: images plus narration plus captions into an MP4 |
| Captions | Whisper on the generated narration, exported as SRT |

**Skills it builds:** TTS, video pipelines, job queues on the GPU. It also
directly helps the docs-as-code goal of SOPs with annotated screenshots (see
[Capture and build spine](../infrastructure/capture-and-build-spine.md)).

### 2. Sleep timing app (Rise-style)

**Idea:** read your own sleep data from Apple Watch and show your likely energy
peaks and dips through the day, plus a suggested wind-down time.

| Part | Open approach |
|---|---|
| Data in | Apple Health data through HealthKit in a small iOS app, or a Health app export file |
| Model | Published sleep research, starting with the two-process model of sleep regulation (sleep pressure plus circadian rhythm) |
| Output | A daily energy curve and simple timing suggestions |
| Storage | On the phone or on your own server; nothing sent to third parties |

**Not medical.** It shows patterns in your own data. It does not diagnose or
treat anything.

**Skills it builds:** HealthKit, Swift or React Native, time-series modeling,
and the Apple Watch side of the [wearables roadmap](wearables-and-hardware.md).

### 3. Push-to-talk dictation app (Wispr Flow-style), in Rust

**Idea:** hold a hotkey, talk, and the text appears in whatever app has focus.
Fully local.

| Part | Open approach |
|---|---|
| Speech to text | whisper.cpp through Rust bindings, GPU when available |
| Hotkey and text insert | Native APIs per operating system |
| Cleanup | Optional local LLM pass for punctuation and filler words |

**Skills it builds:** first Rust project, cross-platform desktop work. It is
also the likely desktop capture client for [the assistant](assistant.md).

### 4. Voice memo transcriber (Plaud-style output, self-hosted)

**Idea:** bulk import old phone voice memos (M4A), get accurate transcripts
and meeting-style notes, review and fix them, all on local hardware.

| Part | Open approach |
|---|---|
| Interface | An Open WebUI plugin first (a first community plugin), standalone app later |
| Speech to text | Whisper on the 3090 Ti, model selectable |
| Notes | Local LLM summaries with a fixed template |
| Storage | Local, with the original audio kept untouched |

**Skills it builds:** plugin development, batch GPU jobs, and a chance to try a
new language or stack on purpose.

### 5. Smaller ideas, parked

- A macOS screenshot and annotation app (Shottr-style) as a native app
  learning project.
- A faster Git-style version control experiment, as a portfolio repo.

---

## How each build is run

1. New repo with a README, the sources log, and a license.
2. A short plan page on this site under this section.
3. Build logs and benchmarks in the same format as
   [Benchmarks & case studies](benchmarks-and-case-studies.md).
4. A blog post when there is something that runs.
