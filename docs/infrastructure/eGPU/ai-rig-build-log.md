# Local AI Inference Rig — Build Log

**Status:** In progress
**Owner:** Bryan Wills
**Related area:** Office build-out / AI infrastructure

---

## 1. Overview

Temporary local-AI inference rig built around a MacBook Pro + Thunderbolt eGPU dock,
intended as a fast-path platform ahead of a dedicated mini-PC / 870 Glacial
purchase. Two jobs, in this order:

1. Make local agentic inference actually work. Hermes on netcup already
   showed that 8-9B CPU-only models fail at tool-calling. Bryan will not pay
   for a hosted model to paper over that. This 24 GB 3090 Ti is the fix.
2. Power the OpenJarvis command center (voice brief + multi-monitor HUD)
   documented in [`../openjarvis-command-center.md`](../openjarvis-command-center.md).
   The LVIS rewrite demo at work is a possible later use of the same box,
   not the primary goal of this purchase.

---

## 2. Hardware Inventory

| Component | Model | Notes |
|---|---|---|
| GPU | EVGA RTX 3090 Ti FTW3 Ultra 24GB | Purchased **2026-09-05**. **Ti variant** — single 16-pin 12V-2x6, not 8-pin like a non-Ti 3090 |
| eGPU dock | Minisforum DEG2 V2 | Thunderbolt / OCuLink switchable |
| PSU | Corsair RM1000x | Labeled for Type 4 cable sets only; currently too large to sit on the dock without covering its power ports — smaller PSU needed long-term |
| Power cable | Corsair 12V-2x6 Premium Sleeved Type 4, 2x8-pin to 12V-2x6 | Confirmed correct for the 3090 Ti |
| UPS | Anker Solix C1000 | PSU plugged in through this |
| Host machine | MacBook Pro, Apple Silicon, TB5 | Connected to dock via TB5 (right-side MBP port → dock's left TB port, marked with PC symbol) |
| Storage | SanDisk Extreme 1TB TB3 SSD | Mounted as `/Volumes/OllamaDrive`; hosts Ollama models and will host Docker's disk image |
| Work laptop | Lenovo ThinkPad PF5PNTVT | Intel, Windows 11 Pro, Hyper-V installed, no WSL2 by policy |

### Mini PC decision (pending purchase)

Requirement: certified Thunderbolt 4/5, since the DEG2 V2 is Thunderbolt-driven.

| Option | Spec | Price | Status |
|---|---|---|---|
| Minisforum MS-01 (Amazon prebuilt) | i9-13900H, 64GB/1TB | $1,559 | Leading candidate |
| Minisforum MS-01 (Micro Center) | i9-13900H, 32GB/1TB | $989 | RAM upgrade to 64GB requires replacing both sticks (both slots full) |
| Minisforum MS-01 barebone | i9-13900H | $669 + RAM | RAM pricing currently unfavorable (~$429/32GB stick) |
| ASUS NUC 14 Pro | — | — | Best-in-class TB reliability, but no PCIe x16 slot, no SFP+ |
| Minisforum MS-02 Ultra | Core Ultra 9 285HX, up to 256GB ECC | — | Better long-term machine; 4.8L/7.6lb breaks portability, CPU throttles with dGPU installed, ~50dB fan. Deferred, not rejected. |

**Decision:** 64GB RAM over 32GB — single vs. dual-channel bandwidth, concurrent load
(local model + coding agent + indexing + Docker + IDE), VRAM-offload headroom past the
3090 Ti's 24GB, and room for a local vector/embedding index.

**Not ordered yet as of this writing.**

---

## 3. Incident Log

### 2026-09-06 — Cable identification error

Assistant incorrectly flagged the correct, already-verified Corsair 12V-2x6 cable as
wrong, defaulting to generic "3090 uses 8-pin" knowledge instead of the verified
Ti-specific fact. Root cause: memory record omitted the "Ti" designation, causing a
pattern-match to the wrong GPU variant.

**Fix:** Memory record corrected to explicitly note the Ti variant and its 12V-2x6
requirement. Standing correction: verify spend- or safety-relevant technical details
against prior conversation record rather than defaulting to general knowledge.

---

## 4. Procedures Completed

### 4.1 Ollama clean reinstall (macOS)

**Problem:** Models had been split across two competing directory trees
(`/Volumes/OllamaDrive/ollama-data/` root vs. `.../ollama-data/models/`), a likely
contributor to earlier install issues.

**Steps completed:**

1. Removed all Ollama installations and state:
   ```bash
   pkill -f ollama
   rm -rf /Applications/Ollama.app
   rm -f /usr/local/bin/ollama /opt/homebrew/bin/ollama
   brew uninstall ollama
   rm -rf ~/.ollama
   rm -f ~/Library/LaunchAgents/com.ollama.*.plist
   ```
2. Identified and removed stray empty scaffolding directories at
   `/Volumes/OllamaDrive/ollama-data/blobs` and `.../manifests` (128K each, empty).
3. Confirmed canonical model directory: `/Volumes/OllamaDrive/ollama-data/models`
   (Ollama auto-creates `blobs/` and `manifests/` beneath it).
4. Set persistent environment variable:
   ```bash
   echo 'export OLLAMA_MODELS="/Volumes/OllamaDrive/ollama-data/models"' >> ~/.zshrc
   ```
5. Created a LaunchAgent so GUI-launched apps (which inherit env from launchd, not the
   shell) also see the variable:

   **File:** `~/Library/LaunchAgents/com.bryanwills.ollama-env.plist`
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
     "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
     <key>Label</key>
     <string>com.bryanwills.ollama-env</string>
     <key>ProgramArguments</key>
     <array>
       <string>/bin/launchctl</string>
       <string>setenv</string>
       <string>OLLAMA_MODELS</string>
       <string>/Volumes/OllamaDrive/ollama-data/models</string>
     </array>
     <key>RunAtLoad</key>
     <true/>
   </dict>
   </plist>
   ```
   ```bash
   launchctl load ~/Library/LaunchAgents/com.bryanwills.ollama-env.plist
   launchctl setenv OLLAMA_MODELS "/Volumes/OllamaDrive/ollama-data/models"
   ```

**Remaining for this procedure:**
- Install Ollama via the official macOS installer from ollama.com (not Homebrew, to
  avoid `brew services` fighting the custom LaunchAgent)
- Verify: `launchctl getenv OLLAMA_MODELS` and `echo $OLLAMA_MODELS`
- `ollama pull llama3.2:1b`
- Confirm files land under `/Volumes/OllamaDrive/ollama-data/models/{blobs,manifests}`
  and nothing appears in `~/.ollama`
- `ollama list`

### 4.2 macOS eGPU compute path (research complete, install pending)

Apple approved Tiny Corp's TinyGPU DriverKit extension in April 2026, enabling NVIDIA
(Ampere+) and AMD (RDNA3+) GPUs over Thunderbolt/USB4 on Apple Silicon for
compute-only workloads (no display acceleration, no SIP disabling, no kexts).
NVIDIA's CUDA compiler path requires Docker. The 3090 Ti qualifies.

**Known caveat:** open tinygrad GitHub issue reports NVIDIA driver handshake failures
specifically over Thunderbolt 5 enclosures on recent macOS (architecture recognition
errors), while USB4 enclosures pass. Relevant given the dock's TBT/OCuLink switch —
unconfirmed whether this affects the DEG2 V2 specifically.

---

## 5. Open Items — Power Wiring (safety gate)

Dock's internal power board has two separate inputs, independent of GPU power:
- 24-pin ATX connector
- 8-pin EPS/CPU-style connector

Both are standard-desktop-motherboard-style inputs powering the dock's own PCIe
switch, TB controller, and OCuLink circuitry — **separate from** the 12V-2x6 cable,
which runs PSU → GPU directly. Both dock inputs are likely required together, the same
way a desktop motherboard needs both its 24-pin and CPU power connector to boot.

Dock also has a physical **GPU TBT / OCuLink switch** — left position routes the GPU
through OCuLink, right position routes it through Thunderbolt. Must be set to
Thunderbolt for this setup.

**Status:** Cable/connector confusion on the mobo power cable was resolved by Bryan
during a live troubleshooting session (connector keying/clip orientation). Full
power-on has **not** yet occurred. Docker and TinyGPU software install can proceed
independently of this.

---

## 6. Product this rig is for (2026-09-06)

Bryan forked [OpenJarvis](https://github.com/open-jarvis/OpenJarvis) to
`github.com/bryanwills/OpenJarvis` (local: `/Users/bryanwills/code/ai/OpenJarvis`).
He is building a local-first command center between that stack and the
walk-in / spoken-brief / wall-HUD loop shown in Peter Mach's
[jarvis-agent.tech](https://jarvis-agent.tech/) promo, without Marvel
branding or their agent names. Full brief:
[`../openjarvis-command-center.md`](../openjarvis-command-center.md).

This repo (office-plan) stays the continuity and infra docs home. The
fork is where runtime code lives. Do not drop OpenJarvis source into
this public docs repo.

---

## 7. Next Steps

1. Install Docker Desktop, relocate disk image to `/Volumes/OllamaDrive/docker-data`
2. Install TinyGPU driver extension + tinygrad
3. Confirm dock power wiring is correct (both ATX inputs seated, TBT/OCuLink switch
   set correctly) before first power-on
4. First power-on: short test only, to characterize noise and confirm detection,
   before any full inference run
5. Run `qwen3:8b` (or equivalent available model) over the NV path via tinygrad, using
   `DEV=NV python3 tinygrad/apps/llm.py`
6. Document model-switching workflow and image generation once the above is stable
7. Order mini PC (MS-01 vs MS-02 decision still open)
8. Configure Hyper-V + Ubuntu 24.04 LTS guest on work laptop with TB5 GPU passthrough
   (separate track, work machine)

---

*Log maintained as part of the office build-out documentation set.*

---

## 8. Resolution — 2026-09-08

### Status: ✅ GPU OPERATIONAL

The RTX 3090 Ti is now fully functional over Thunderbolt 5 for local AI inference. See the complete troubleshooting documentation: [`thunderbolt-egpu-troubleshooting-guide.md`](./thunderbolt-egpu-troubleshooting-guide.md)

### What Was Required

1. **Disabled GSP firmware** — The GPU System Processor firmware is incompatible with Thunderbolt eGPUs on Linux
2. **Prevented D3cold power state** — The GPU was falling into deep sleep and couldn't wake up
3. **Created boot-time recovery service** — Automatically recovers from MMIO failures and binds the NVIDIA driver

### Performance Achieved

- **Connection:** Thunderbolt 4/5 at 40 Gb/s (2 lanes × 20 Gb/s)
- **Driver:** NVIDIA 580.173.02 with CUDA 13.0
- **Test result:** llama3.2:3b at 257 tok/s evaluation speed

### Files Created

| File | Purpose |
|------|---------|
| `/etc/modprobe.d/nvidia-egpu.conf` | Disables GSP, dynamic power management, ReBAR |
| `/etc/udev/rules.d/99-egpu-power.rules` | Keeps GPU and TB bridges out of D3cold |
| `/usr/local/sbin/egpu-bind.sh` | Boot-time GPU binding with MMIO recovery |
| `/etc/systemd/system/egpu-bind.service` | Systemd service for reliable GPU init |

### Kernel Parameters Added

```
pcie_aspm=off pcie_port_pm=off pcie_ports=native intel_iommu=on iommu=pt 
pci=realloc,assign-busses thunderbolt.clx=0 thunderbolt.host_reset=0
```

### Next Steps

1. ☐ Mount OllamaDrive and configure Ollama to use external storage
2. ☐ Pull Qwen3.8:27b model
3. ☐ Run Thunderbolt benchmark with production model
4. ☐ Install OCuLink adapter (arriving tomorrow)
5. ☐ Run OCuLink benchmark for comparison
6. ☐ Document performance difference for content creation

---

## 9. Benchmark Results

*Section to be populated after running benchmarks with both Thunderbolt and OCuLink connections.*

| Connection | Model | Eval Rate (tok/s) | Total Duration | Date |
|------------|-------|-------------------|----------------|------|
| Thunderbolt | llama3.2:3b | 257 | — | 2026-09-08 |
| Thunderbolt | qwen3.8:27b | TBD | TBD | TBD |
| OCuLink | llama3.2:3b | TBD | TBD | TBD |
| OCuLink | qwen3.8:27b | TBD | TBD | TBD |

### Benchmark Scripts

- `/home/bryanwills/benchmark-egpu.sh` — Run individual benchmarks
- `/home/bryanwills/compare-benchmarks.sh` — Compare all results

Usage:
```bash
# Thunderbolt benchmark
./benchmark-egpu.sh llama3.2:3b thunderbolt
./benchmark-egpu.sh qwen3.8:27b thunderbolt

# After switching to OCuLink
./benchmark-egpu.sh llama3.2:3b oculink
./benchmark-egpu.sh qwen3.8:27b oculink

# Compare all
./compare-benchmarks.sh
```
