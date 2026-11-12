# Product Vision

**Status:** Draft, written 2026-11-12. Direction, not commitments.
**Owner:** Bryan Wills
**Scope:** The neurodivergent executive-function assistant, the push-to-talk
hardware around it, the local-first AI stack it runs on, how the business makes
money and gives back, and the personal open-source builds that sharpen the
skills behind all of it.

---

## The one-sentence version

Build an assistant that does executive-function work for neurodivergent people
(captures the thought, finds the first step, brings you back to where you left
off), make it work on the devices people already carry, run it on hardware you
own where possible, and document every step in public so others can follow.

Everything else on this site (the LLC filings, the netcup stacks, the eGPU rig,
the idea pipeline) exists to make that real.

!!! note "Naming"
    "The assistant" is a working name. The product name follows the LLC name
    decision, which is still open. See
    [Entity & Name Decision](../formation/entity-decision.md). OpenJarvis is the
    name of the open-source stack it is built on, not the product name, and
    nothing here uses Marvel branding, voices, or catchphrases.

---

## How the pieces fit

| Layer | What it is | Where it is documented |
|---|---|---|
| The assistant | Voice-first executive-function helper on web, phone, watch, desktop, and small devices | [The assistant](assistant.md) |
| Capture hardware | Push-to-talk wearables and desk units, never always-on recording | [Wearables & hardware roadmap](wearables-and-hardware.md) |
| Compute | Local models on the RTX 3090 Ti eGPU behind Tailscale, cloud only when needed | [Local-first AI architecture](local-ai-architecture.md) |
| Command center | Wall HUD, desk dashboards, spoken morning brief | [OpenJarvis command center](../infrastructure/openjarvis-command-center.md) |
| Proof | Benchmarks, case studies, and build logs written as the work happens | [Benchmarks & case studies](benchmarks-and-case-studies.md) |
| Business | App plus hardware plus service, with a share going back to the ND community | [Business model](business-model.md) |
| Personal builds | Clean-room, open-source versions of paid tools, for practice and portfolio | [Open-source builds](open-source-builds.md) |

---

## Product family

Not every idea here ships as its own product. This table keeps them in one
place so they stop living in scattered chats and notes.

| Item | Type | Status |
|---|---|---|
| The assistant (web first) | Core product | Starter voice web app built (push-to-talk, Whisper, swappable LLM) |
| Phone and Apple Watch capture | Core product surface | Planned, first hardware phase |
| Push-to-talk wearables (pendant, band, ring) | Hardware product | Research and prototyping |
| Desk unit (Raspberry Pi or ESP32 screen) | Hardware product | Boards on hand, partly flashed |
| NFC routine kits | Hardware plus app kit | Idea, testing on his own routines first |
| NeuroCrumbs (tab and idea breadcrumbs) | App | Chrome extension MVP agreed |
| Open-source builds (training video tool, sleep app, dictation, transcription) | Personal portfolio, not for sale | Planned |

---

## Design principles (carried over from the architecture notes)

These come from
[Product & Architecture Notes](../product-architecture-notes.md) section 3 and
apply to every surface listed above.

- **Suppression is a feature.** Deciding what not to show is the hard part.
- **One next action, not a list.** A list is another thing to be overwhelmed by.
- **No streaks, no guilt mechanics.** Gaps are normal, not failures.
- **Sensory-aware defaults.** Quiet, low motion, few notifications, real controls.
- **Local-first where possible.** Privacy is a real concern for this audience.
- **Capture on purpose.** A button press or a trigger starts recording. Nothing
  listens all day.
- **Approvals stay gated.** The assistant drafts. People decide what leaves the
  device, what gets sent, and what gets spent.

---

## What has to be true before this ships to anyone else

1. It works for its first user every day, not just in a demo.
2. Every claim on the product site points to a benchmark or case study on this
   site.
3. Capture hardware has a visible recording indicator and a physical control.
4. Local mode really is local, and that is tested, not assumed.
5. The LLC exists, the product has a name, and the privacy policy is written in
   plain language.

---

## Next steps

1. Run the starter voice web app against Ollama on the 3090 Ti and log the
   first latency and accuracy numbers
   (see [Benchmarks & case studies](benchmarks-and-case-studies.md)).
2. Add phone and Apple Watch push-to-talk capture into the same inbox.
3. Pick one daily loop to prove (morning brief or context re-entry) and write
   it up as the first case study.
4. Start the first wearable prototype on the ESP32 boards already on hand.
5. Revisit this page when the LLC name lands and replace the working names.
