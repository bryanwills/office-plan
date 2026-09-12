# ai-nuc eGPU Build Log and Recovery Procedure

**Machine:** ai-nuc (Minisforum MS-01, i9-13900H, 64GB RAM, 1TB NVMe)
**OS:** Ubuntu 24.04.4 LTS, kernel 7.0.0-31-generic, headless (multi-user.target)
**GPU:** EVGA RTX 3090 Ti FTW3 Ultra 24GB over Minisforum DEG2 V2 Thunderbolt dock
**Status:** WORKING as of 2026-09-08. Fragile. Read the recovery section before rebooting.
**User:** bryanwills

---

## 1. The one thing to read first

This eGPU setup works but is fragile. The GPU driver binding depends on a
custom systemd service that waits for the Thunderbolt tunnel before binding
the NVIDIA driver. If the GPU disappears after a reboot, an update, or a dock
power cycle:

```bash
sudo /usr/local/sbin/egpu-bind.sh
```

If that alone doesn't work, power-cycle the DEG2 dock PSU: switch it off, wait
10 seconds, switch it on, then run the script again.

**Do not run `apt upgrade` casually on this machine.** A kernel or NVIDIA
driver update can break the bind timing and put you back at "fallen off the
bus." When you do update, expect to possibly re-apply the fix below.

**Power sequence: always power the DEG2 dock before or with the NUC**, never
after the OS is already up. Hot-plugging the powered GPU into a running kernel
is what caused the hard lockups during setup.

---

## 2. Root cause of the "fallen off the bus" failure

This took an entire evening to diagnose. Recording it so it never takes that
long again.

**Symptom:** `nvidia-smi` reported "NVIDIA-SMI has failed because it couldn't
communicate with the NVIDIA driver." Kernel log showed, thousands of times:

```
NVRM: The NVIDIA GPU 0000:05:00.0 (PCI ID: 10de:2203) installed in this system has
NVRM: fallen off the bus and is not responding to commands.
nvidia 0000:05:00.0: probe with driver nvidia failed with error -1
```

**Actual root cause:** The card was visible in `lspci`, but its PCI memory
space read back as `0xffffffff` (dead). The NVIDIA 580 driver probed the GPU
about one second after the DEG2 dock appeared on the bus, while the GPU was
still in D3cold power state. The driver hit dead MMIO and reported the card as
fallen off the bus, then retried in an infinite loop.

This is a known Linux + Thunderbolt dock (Intel JHL9480 controller) + NVIDIA
GSP-firmware interaction failure. It is a **timing and firmware problem, not a
bandwidth problem**. It was NOT caused by using Thunderbolt instead of OcuLink;
OcuLink would not have fixed this automatically. The same race can occur there.

**What it was NOT (ruled out during diagnosis):**
- Not Secure Boot (that was a separate, earlier problem, now resolved/disabled)
- Not a bad cable (the short OWC cable is in use and stable; link trains fine)
- Not the open-vs-proprietary driver flavor by itself
- Not a bandwidth limitation (40 Gb/s TB4 is enough to initialize the card)

---

## 3. The fix that worked

Applied to ai-nuc by an assisted debugging session on 2026-09-08:

1. **Reset the Thunderbolt PCI tree** so the GPU's MMIO space came back to life
   instead of reading `0xffffffff`.

2. **Loaded proprietary NVIDIA 580.173.02 with GSP firmware disabled:**
   ```
   nvidia.NVreg_EnableGpuFirmware=0
   ```

3. **Blacklisted early NVIDIA autoload** so the driver does not probe the GPU
   before the Thunderbolt tunnel is fully up.

4. **Added `egpu-bind.service`** which, on boot, waits for the tunnel, recovers
   the GPU MMIO if needed, then binds the NVIDIA driver. Manual trigger is
   `/usr/local/sbin/egpu-bind.sh`.

5. **Added kernel parameters** (in `/etc/default/grub`, applied via
   `sudo update-grub`):
   ```
   pcie_ports=native iommu=pt pci=realloc,assign-busses thunderbolt.clx=0 thunderbolt.host_reset=0
   ```
   These are in addition to the earlier `pcie_aspm=off pcie_port_pm=off`.

---

## 4. Confirmed working state

- `nvidia-smi`: RTX 3090 Ti, 24564 MiB VRAM, persistence mode on, ~99W idle
- Ollama 0.33.3: CUDA compute capability 8.6, 23.8 GiB VRAM available
- `llama3.2:3b` ran 100% on GPU at ~257 tokens/sec decode

---

## 5. How to use it

```bash
ssh bryanwills@ai-nuc
ollama run llama3.2:3b
```

**Model ceiling for 24GB VRAM:**
- Good: anything up to ~32B at Q4 quantization
- `qwen2.5:32b` at Q4 is the practical maximum dense model
- The existing `qwen3.8:27b` (17GB) fits comfortably
- **Do NOT** try `llama3.1:70b` — that is ~40GB at Q4 and will not fit in 24GB.
  It will either fail or fall back to painfully slow CPU/partial offload.

**Performance caveat:** Decode speed is already fast. Prompt ingestion and
large-context loads stay TB4-bandwidth-limited (40 Gb/s) until OcuLink is
wired up. This affects time-to-first-token on big prompts, not decode speed.

---

## 6. Hardware facts about this machine

- MS-01 i9-13900H, dual **Thunderbolt 4** ports (NOT TB5), 40 Gb/s each
- DEG2 link negotiates 40 Gb/s (2x20). Correct for this host.
- The DEG2's JHL9480 controller exposes the 3090 Ti as a UEFI GOP display, so
  the BIOS shows an extra graphics/boot device. This is expected and harmless.
  Leave Ubuntu as the existing boot entry.

**TO VERIFY (the assist tool claimed the x16 slot holds an Intel X710 10GbE
card; this needs confirming — the MS-01's 10G is often onboard SFP+, not a
card in the slot):**
```bash
lspci | grep -i x710
lspci | grep -i ethernet
```
If the x16 slot is actually free, the OcuLink upgrade path is simpler than
assumed.

---

## 7. OcuLink upgrade path (when the adapter arrives)

The DEG2 also has an OcuLink port (PCIe 4.0 x4, ~64 Gb/s, fewer Linux
Thunderbolt bugs). This is the long-term upgrade, not a replacement for a
broken dock — the dock is fine.

Two install options on the MS-01:
1. Put a half-height OcuLink card in the PCIe x16 slot (verify the slot is
   free first — see section 6)
2. Use an M.2-to-OcuLink adapter

Then flip the DEG2 switch from TBT to OcuLink. For dock USB/Ethernet
pass-through in OcuLink mode, also connect the extra USB-C cable that
Minisforum documents.

Expected benefit: faster prompt ingestion and large-context handling, plus a
more stable link that may let you retire the fragile bind service.

---

## 8. Setup history and lessons (condensed)

- **Secure Boot** rejected both the Ubuntu USB and the NVIDIA kernel module
  ("Key was rejected by service"). Resolved by disabling Secure Boot in BIOS.
  A dying USB stick also contributed to the initial install failure — a
  known-good replacement stick fixed that half.
- **Two driver packages** (nvidia-driver-570 and -580) got installed
  simultaneously by the bootstrap's fallback path. Cleaned up to 580 only.
- **The display manager (GDM)** was an early suspect for lockups; the machine
  was set to boot to console (`multi-user.target`) which is correct for a
  headless inference box anyway.
- **Hard lockups** during setup were caused by hot-plugging the powered eGPU
  into a running kernel. Cold-boot-with-GPU-present is the stable path.
- **Wired ethernet + SSH** was the breakthrough that made diagnosis possible —
  it survives even when the GPU/console hangs, so logs from a failed boot can
  be read from the next good boot with `journalctl -b -1`.

---

## 9. Standing constraints for this machine

- Runs 24/7; the GPU/dock does not need to (idle draw is low in D3, but don't
  run models overnight if noise/heat in the room is a concern)
- Headless, driven over SSH (wired now; Tailscale for remote)
- OllamaDrive (exFAT, external) holds the model library, shared with the
  MacBook. Do NOT put container/VM storage on it (exFAT has no sparse files or
  journaling). Models only.
- exFAT is fine for Ollama model blobs on any of the three machines.
