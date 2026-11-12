# The Assistant

**Status:** Draft, 2026-11-12. Starter voice web app exists; everything past
that is planned.
**Owner:** Bryan Wills
**Scope:** What the executive-function assistant does, who it is for, which
platforms it runs on, and the order it gets built in.

---

## What it is

A voice-first assistant that does executive-function work, not one that
explains executive function. You talk faster than you type, so you talk to it.
It catches the thought, files it, turns a stuck task into one first step,
reminds you at the right moment, and tells you where you left off when you come
back.

It is proactive in a narrow, opt-in way: a morning brief, a nudge before a
deadline, a "you said you would do this after lunch." It is not a chatbot you
have to remember to open.

The command-center side of the same idea (wall HUD, desk dashboards, spoken
brief, overnight agent work) is documented in
[OpenJarvis command center](../infrastructure/openjarvis-command-center.md).
This page covers the personal assistant that the command center is one view of.

---

## Who it is for

- Neurodivergent adults who know what they need to do and cannot find the first
  step, lose the thread after an interruption, or forget the thing they thought
  of in the car.
- People who are tired of apps that add more lists, more streaks, and more
  notifications.
- Its first user is the person building it. If it does not help him every day,
  it is not ready for anyone else.

---

## Core jobs

| Job | What the user does | What the assistant does |
|---|---|---|
| Capture | Presses a button and talks | Transcribes, tags, files to one inbox, confirms in a few words |
| First step | Says "I can't start X" | Breaks X down until one small, concrete action is left, and offers only that |
| Context re-entry | Comes back after a break or a meeting | Says what was in progress, what changed, and the next action |
| Morning brief | Walks in, or opens the app | Short spoken summary: today, what is due, what happened overnight, what needs a decision |
| Timely nudges | Sets intent once ("remind me after lunch") | Nudges once at the right time, without nagging |
| Drafting | Gives a rough intent | Drafts the message or reply; the user sends it |
| Decision log | Makes a call | Records what was decided and why, for later recall |

Context re-entry is the most differentiated job on this list. Plenty of tools
help you plan. Very few help you resume.

---

## What it will not do

- Record all day. Capture starts with a button press or an explicit trigger.
  See [Wearables & hardware roadmap](wearables-and-hardware.md).
- Send, buy, delete, or post anything without a human yes.
- Give medical advice or act as a clinical tool. Anything clinical is a
  separate, later track with its own compliance work.
- Punish gaps. No streaks, no guilt copy, no red badges counting failures.
- Use a borrowed voice or catchphrase. The voice is calm, articulate, and
  original, or properly licensed if it is ever trained on a real person's
  recordings.

---

## Platforms

Web first because it already exists and runs anywhere. Each later surface is a
capture and playback client for the same backend, not a separate app with its
own brain.

| Platform | Role | Candidate approach (not decided) | Phase |
|---|---|---|---|
| Web | Full app: capture, inbox, brief, settings | FastAPI backend plus a plain web page (the starter app); later a richer front end | Now |
| iOS | Capture from the Action Button, Shortcuts, and widgets | Native or React Native; Shortcuts integration first because it is cheapest | 1 |
| Apple Watch | Raise and press to talk; quiet haptic confirmations | Watch app or Shortcut that records and posts audio to the backend | 1 |
| Android | Same as iOS | Same codebase as iOS if React Native wins | 2 |
| Desktop (macOS, Linux, Windows) | Global hotkey push-to-talk, tray brief | Small native shell around the web app, or the open-source dictation build | 2 |
| Raspberry Pi desk unit | Always-plugged-in desk speaker and screen with a physical button | Pi 5 with a small touch screen, building on the existing ai-pi node | 2 |
| ESP32 battery device | Pocket or wearable capture with a button | ESP32-S3 boards already on hand, firmware posting audio to the backend | 3 |

---

## Starter app (exists today)

A small voice-first web app was built on 2026-11-12 as the first working
slice:

- Hold a button (or the space bar), talk, let go.
- Speech to text with Whisper on the server (faster-whisper), or a hosted
  speech API, or a mock for testing.
- Swappable LLM backend: mock, Ollama, or any OpenAI-compatible API, chosen by
  an environment variable.
- Spoken replies with the browser's built-in voice.
- Docker image and Compose file, with an optional Ollama service.

Not yet proven: real Whisper transcription on the target machine and GPU
inference. Those are the first two benchmarks on
[Benchmarks & case studies](benchmarks-and-case-studies.md). The code is not in
a public repo yet.

---

## Build order

1. **Voice loop on local hardware.** Run the starter app against Ollama on the
   3090 Ti. Measure button-to-first-word latency and transcription accuracy.
2. **One inbox.** Every capture (web, phone, watch, device) lands in the same
   store with a timestamp and a source tag.
3. **Morning brief v0.** One spoken summary from sources that already exist:
   calendar, inbox counts, stack health. Matches step 3 of the command center
   plan.
4. **First step and context re-entry.** The two jobs that matter most, built
   on the blackboard pattern in
   [Product & Architecture Notes](../product-architecture-notes.md).
5. **Phone and watch capture.** Shortcuts first, native apps once the loop is
   worth it.
6. **Memory.** Long-term user memory through the self-hosted Honcho instance
   (see [Self-hosted Honcho on ai-nuc](../infrastructure/honcho-ai-nuc-setup.md)),
   with a clear "what do you know about me" view and a real delete.
7. **Proactive nudges.** Only after the first six are boring and reliable.

---

## Open questions

- How the assistant, Hermes (the existing 24/7 gateway), and the OpenJarvis
  fork share memory, voice, and channels. Do not silently retire Hermes.
- Native apps versus React Native for iOS and Android.
- Which TTS engine gives an original voice that sounds human and runs locally.
- How much of the brief can run fully offline on a phone.
