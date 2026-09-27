---
id: creator-provenance-key
title: Creator Provenance Key — a physical key for the creator side of signed media
auto-mvp: false
owner: bryanwills
priority: P1
deadline: null
linked-briefs: []
---

# Creator Provenance Key

## What problem does it solve?

Apple just announced that iPhone 18 Pro Max photos carry an **embedded
digital signature** so that a photo's device-side authenticity can be
verified — to fight AI fakes. The signature binds the photo to a *device*
(the iPhone's secure element).

But the device is a *means*, not the *claim*. Three problems:

1. **Device ≠ Creator.** A photo signed by an iPhone is "an iPhone," not
   "Bryan Wills shot this on a shoot at 4 AM." Ownership of the signature
   doesn't travel to the creator, only to the hardware.
2. **Device handoff is a provenance break.** If the iPhone is sold,
   re-provisioned, or swapped, every photo "signed" by that device now lives
   on the next owner's machine. The signature survives; the creator doesn't.
3. **SD-card / memory-card workflows have no creator anchor.** Drone
   operators, field photographers, and creators working off SD/microSD/
   SDXC cards have *no* device signature at all — the card is the only
   thing that's there, and it has no identity.

The idea: a **physical, portable, per-creator key** (a Yubikey-shaped USB /
NFC / BLE token) that:

- Carries a **creator identity** (public key + attestation) independent of any
  phone or computer.
- Can be **presented to hardware** (an iPhone, a camera, a drone, an SD-card
  reader) to co-sign a capture with *both* the device's signature and the
  creator's signature.
- Survives device handoff — if the phone changes, the creator key remains the
  provenance anchor. The creator is the signature, not the phone.
- For SD-card workflows: an optional card reader / hub that accepts the key's
  co-signature at read-time and writes a creator-signed manifest into the
  card's filesystem (or a hash chain anchored to it).

## What should the finished thing do?

Minimum viable thing, in 60 days:

1. Given a capture (photo file) + a device signature (C2PA manifest, Apple
   signed-photo format, or raw EXIF) + a creator key's signature →
   produce a **verifiable provenance record** that says "creator K
   confirmed this capture from device D at time T."
2. Given a capture + no key → produce a "device-only" provenance record
   (baseline, no creator).
3. Given a device-side signature that's been tampered with →
   `verification_failed` with the specific field.
4. Given a creator key that's moved to a new device → the provenance record
   still resolves to the *creator*, not the new device.
5. A **CLI** (`creator-key sign/verify/show`) that works over USB-HID, NFC,
   and BLE.
6. A **Python SDK** (`creator_provenance.Key(...)`) for app-level integration.
7. A **docs site** (MkDocs) with a quickstart, concept doc, and a
   "what this proves and what it doesn't" page (anti-abuse, anti-creator-
   impersonation, anti-replay — all explicit).

## Inputs / Outputs

- **Inputs:**
  - A captured photo (HEIF/JPEG/RAW) or an SD card's contents.
  - A device-side signature source (Apple signed-photo, C2PA manifest, or
    EXIF `ImageSource`).
  - A creator key (token) presenting its public key + a fresh signature over
    the capture hash.
- **Outputs:**
  - A provenance record (JSON, C2PA-style manifest, or an embedded sidecar).
  - A `creator-key` CLI + Python SDK.
  - A hardware spec for the token (FPGA or secure element, USB-HID + NFC +
    BLE) — the "physical" half.
- **Out of scope (v1):** DRM, content licensing, watermarking, and any
  "block fakes" — the point is to *attest*, not to *restrict*.

## Known constraints

- **Local inference:** Not needed for signing/verification (it's crypto,
  not ML). Local-only is a feature, not a constraint.
- **Approvals required for:** none — this is a pure local, open-source
  signing/verification project. No trading, no third-party accounts.
- **Secrets / credentials:** The creator's private key lives on the token.
  Nothing secret is stored on the phone or in the repo.
- **Hardware / OS targets:** macOS 27 host, an iOS 18 Pro Max as the
  reference device, Yubikey 5 series (or equivalent FIDO2 + PIV) as the
  reference token. The token spec is hardware-agnostic in the repo.

## Success criteria (Definition of Done for THIS project)

- `creator-key verify` rejects a tampered signature and reports the exact
  field.
- `creator-key sign` over NFC on a phone works, given a phone-side hook
  (a small Swift sample that presents the signed-photo manifest to the key).
- A new device (a Mac, or a new phone) can still resolve a capture to the
  creator key — the creator identity is stable across device handoff.
- The **SD-card** path demonstrates the same flow for a capture off an SD
  card (read into a buffer, sign over its SHA-256, write a creator-signed
  manifest next to it).
- The repo has a **hardware spec** for the token (FPGA / secure element,
  USB-HID + NFC + BLE) with a BOM and a "you could also just use a
  Yubikey 5" note for the no-hardware path.
- The docs site has a **"what this proves and what it doesn't"** page,
  covering: creator attestation, device attestation, tamper detection,
  and what it can't do (block fakes, enforce licensing, resist
  social-engineered creator handoff).
- A **benchmark baseline** for sign/verify latency across USB, NFC, BLE.
- A **QA script** (`make qa`) that runs end-to-end and exits non-zero on any
  failure.

## Timeline shape

- **Rough estimate:** 2–3 weeks of agent time for a Python + CLI + docs MVP
  on the no-hardware path; hardware spec is a parallel workstream.
- **Must-haves for MVP:**
  - Signing + verification over USB.
  - Tamper detection with field-level error.
  - Creator identity that survives device handoff (a key on a token, or a
    simulated token).
  - A docs page on "what this proves and what it doesn't."
  - The hardware spec (paper-only OK).
- **Nice-to-haves (v2):**
  - BLE path.
  - An iOS app that reads the signed-photo manifest and presents it to the
    key for co-signing.
  - A C2PA manifest writer (or interop with an existing one).
  - A "card reader hub" sketch for the SD-card workflow.

## Open questions (VP should ask, in order)

1. **What's the reference signing format?** Apple's signed-photo manifest
   (if Apple exposes it in iOS 26 / an SDK), C2PA, or EXIF? This drives
   the v1 shape. (Owner's lean: C2PA for portability, Apple format as a
   second target once Apple opens it up.)
2. **What's the token substrate?** Yubikey 5 (out-of-the-box) vs. a custom
   secure-element spec (more capable, more work). (Owner's lean: Yubikey 5
   as v1, custom spec as the "physical half" that ships as a hardware doc.)
3. **Scope of "creator"** — is the key one-person-per-key, or one person
   with N keys (device-specific sub-keys, travel, shared-creator
   workflows)? (Owner's lean: one person per key with revocable sub-keys.)
4. **SD-card read-path** — do we require a card reader with co-signing
   capability, or is a plain USB reader + `creator-key sign` over the read
   buffer acceptable for v1? (Owner's lean: plain reader is fine for v1.)
5. **Anti-abuse** — should `creator-key verify` also check the
   *creator key's* attestation against a public creator registry, or is
   that out of v1 scope? (Owner's lean: out of v1, but the docs should call
   it out as a v2.)

## Notes / prior research

- Apple's announcement (iPhone 18 Pro Max) is the trigger for this brief —
  the device-side signature now exists; this brief is the *creator-side*
  half.
- Related: [Apple image signing in iOS 18+](https://developer.apple.com/) —
  owner to confirm the exact API surface when available.
- Related: C2PA (Coalition for Content Provenance and Authenticity) —
  the reference content-signing standard. The MVP should speak C2PA so
  that the provenance record is *portable* across tools.
- Related: FIDO2 / PIV on a Yubikey 5 — the reference hardware. The
  MVP can target the no-hardware path (a software key) first, and the
  Yubikey 5 path second.
- **Not in scope:** DRM, watermarking, blocking fakes, content licensing.
  The project *attests*; it does not *restrict*.
