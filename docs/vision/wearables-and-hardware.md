# Wearables & Hardware Roadmap

**Status:** Draft, 2026-11-12. Phase 1 uses devices already owned. Custom
hardware is research and prototyping only.
**Owner:** Bryan Wills
**Scope:** The devices that capture speech for the assistant, the rules they
follow, and the order they get built in.

---

## The rule that shapes everything

**Push-to-talk or trigger-based. Never always-on recording.**

Every capture device starts recording because the wearer did something on
purpose: pressed a button, squeezed, tapped, raised a wrist and pressed. When
the press ends, recording ends.

Why this is a hard rule, not a setting:

- People around the wearer did not agree to be recorded. Recording-consent laws
  vary by state and country, so the design has to hold up in the strictest case.
- Always-listening devices drain batteries and fill storage with noise nobody
  will ever review.
- An ND user who forgets a device is on is exactly the user this would hurt.
- "We only record when you press" is a promise people can understand and check.

---

## Hardware requirements (every device)

| Requirement | Why |
|---|---|
| Physical control to start capture | Intent is explicit and works without looking at a screen |
| Visible indicator while recording (LED or screen) | The wearer and anyone nearby can tell |
| Short haptic or audio confirmation when a capture is saved | The user trusts it without checking an app |
| Audio deleted from the device after a confirmed upload | Nothing piles up on a lost device |
| Works offline, then syncs | Captures are not lost in a dead zone |
| Encrypted transport to the backend (Tailscale or HTTPS) | Audio is private in transit |
| Battery that lasts days of non-continuous use | A device that dies by noon gets left in a drawer |
| Swappable or standard charging (USB-C, MagSafe, Qi) | No proprietary cable to forget on a trip |

---

## Form factors under consideration

| Form factor | Trigger | Strengths | Trade-offs |
|---|---|---|---|
| Phone | Action Button, widget, Shortcut, lock-screen control | Already carried, best mics, no new hardware | Has to come out of a pocket |
| Apple Watch | Raise and press | On the wrist, haptics built in | Not everyone wears one every day; notification fatigue is real |
| Pendant or clip with button and mics | Press and hold | Hands-free placement, close to the mouth | Must be clearly not recording by default |
| Band or bracelet | Squeeze or press | Always on the body, discreet | Small battery, small mic |
| Ring with mic | Press with the thumb | Most discreet trigger | Hardest to build; tiny battery and antenna |
| Desk unit (Pi or ESP32 screen) | Big physical button | Never runs out of power, great for home and office | Stays in one place |
| Smart knob | Press or turn | Doubles as a volume and light control | Desk only |

Reference device being evaluated: a commercial MagSafe AI note taker (Plaud).
Useful as a benchmark for capture quality and transcript output. Its need to be
switched on before use is a drawback worth designing around.

---

## Phases

### Phase 1: phone and Apple Watch

No new hardware. Fastest way to learn what people actually capture.

- iPhone Shortcut or Action Button press records a clip and posts it to the
  assistant backend.
- Apple Watch Shortcut does the same from the wrist.
- Every capture lands in the same inbox as the web app.
- Measure: press-to-saved time, transcription accuracy outdoors and in the car,
  and how often captures get used later.

### Phase 2: dev boards on hand

Boards already bought and partly working:

| Board | Current state | Planned use |
|---|---|---|
| Waveshare ESP32-S3 Touch e-Paper 1.54 (Pala Note firmware) | Working; records notes and serves WAV files over its web portal; transcription routed through a self-hosted n8n webhook | Pocket capture prototype; first test of button, battery, and upload |
| Waveshare ESP32-S3 Touch LCD 1.54 (Xiaozhi firmware) | On Wi-Fi, firmware downloaded, not yet flashed | Conversational desk or pocket device; test two-way voice |
| ESP32-S3 round knob display (1.8 inch) | On hand | Desk knob with push-to-talk |
| Fork of the open-source smartknob project | Forked; LVGL chosen for the UI | Custom desk knob, later with an enclosure |
| Raspberry Pi 5 (ai-pi) with a small touch screen | Running Ollama and a local assistant over Tailscale | Desk unit with a physical button |

Lessons already logged: battery connectors differ between boards (JST sizes do
not match across "same capacity" cells), so every build log lists the exact
battery, connector, and protection circuit used.

### Phase 3: own wearable prototypes

- One pendant or clip and one band, built on an ESP32-S3 (or a smaller
  successor) with a MEMS mic array, a button, an LED, and a haptic motor.
- Local buffer on the device; upload over Wi-Fi or Bluetooth to the phone,
  which relays to the backend.
- Multiple hardware revisions, each with its own build log and benchmark run.
- Ring stays research until the band works.

### Phase 4: product hardware

- Enclosure design (3D printed first, then a production method).
- Use pre-certified radio modules where possible. Selling a wireless device in
  the US requires FCC authorization, and other markets have their own rules.
  Check this before taking any orders.
- Battery safety, shipping rules for lithium cells, and a warranty and return
  process.
- Accessible packaging and setup: one page, large text, no app account needed
  to try the button.

---

## How capture flows

```text
[button press] -> device records -> device buffers locally
      -> upload (Wi-Fi, or Bluetooth to phone) over Tailscale or HTTPS
      -> backend: speech to text (Whisper) -> tag and file to inbox
      -> short confirmation back to the device (haptic or tone)
      -> device deletes the audio
```

---

## Benchmarks for every device revision

Logged on [Benchmarks & case studies](benchmarks-and-case-studies.md):

- Press-to-saved latency
- Word error rate on a fixed set of test phrases, quiet room and noisy room
- Battery life under a fixed capture schedule
- Missed or accidental captures per week of real use
- Weight, comfort, and whether it actually got worn
