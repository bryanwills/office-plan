# NVIDIA Thunderbolt eGPU Troubleshooting Guide — MS-01 + DEG2 + RTX 3090 Ti

**Status:** ✅ RESOLVED — GPU operational  
**Last Updated:** 2026-09-08  
**Author:** Bryan Wills  
**Platform:** Minisforum MS-01 (i9-13900H) + Ubuntu 24.04 LTS + Minisforum DEG2 V2 + RTX 3090 Ti

---

## Executive Summary

This document captures three days of troubleshooting to get an NVIDIA RTX 3090 Ti working over Thunderbolt on Linux for local AI inference. The root cause was a combination of:

1. **GSP (GPU System Processor) firmware** — Incompatible with Thunderbolt eGPUs on Linux
2. **D3cold power state** — GPU falling into deep sleep and not waking up
3. **MMIO (Memory-Mapped I/O) failures** — GPU registers becoming unreadable after power state transitions

**Solution:** Disable GSP firmware, prevent D3cold, and implement a boot-time recovery service.

---

## Hardware Configuration

| Component | Model | Specs |
|-----------|-------|-------|
| Host PC | Minisforum MS-01 | Intel i9-13900H, 64GB DDR5, Ubuntu 24.04 LTS |
| eGPU Dock | Minisforum DEG2 V2 | Thunderbolt 5 / OCuLink switchable, Intel JHL9480 controller |
| GPU | EVGA RTX 3090 Ti FTW3 Ultra | 24GB VRAM, GA102, Ampere architecture |
| PSU | Corsair RX1000 | 1000W, Type 4 cables |
| Cable | OWC Thunderbolt 5 Pro | 0.3m, 80 Gb/s rated |
| Storage | SanDisk Extreme 1TB NVMe | Thunderbolt 3 SSD for Ollama models |

### Thunderbolt Link Status

```
rx speed:   40 Gb/s = 2 lanes * 20 Gb/s
tx speed:   40 Gb/s = 2 lanes * 20 Gb/s
```

*Note: Running at TB4 speeds (40 Gb/s) despite TB5 hardware — this is normal for eGPU compute workloads.*

---

## The Problem

### Symptoms

1. **`nvidia-smi` fails** with "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver"
2. **Kernel logs show repeated errors:**
   ```
   NVRM: The NVIDIA GPU 0000:05:00.0 installed in this system has fallen off the bus and is not responding to commands.
   Unable to change power state from D3cold to D0
   ```
3. **GPU appears in `lspci`** but driver won't bind
4. **Error count grows rapidly** — 4500+ identical errors in minutes

### Root Cause Analysis

The NVIDIA Linux driver has several features designed for laptops and workstations that actively harm Thunderbolt eGPU setups:

1. **GSP Firmware** — The GPU System Processor runs firmware that manages the GPU independently. On Thunderbolt, the hot-plug nature means the GSP can lose sync with the host, causing the driver to fail initialization.

2. **Dynamic Power Management** — The driver tries to put idle GPUs into deep sleep (D3cold). Over Thunderbolt, the GPU often can't wake up properly, resulting in "fallen off the bus" errors.

3. **Resizable BAR** — While great for performance, ReBAR can cause issues with PCIe resource allocation over Thunderbolt tunnels.

4. **HDMI Audio** — The 3090 Ti's HDMI audio device consumes Thunderbolt tunnel bandwidth and has its own driver binding issues.

---

## The Solution

### Overview of Required Changes

1. **Kernel boot parameters** — Optimize PCIe, IOMMU, and Thunderbolt subsystems
2. **Modprobe configuration** — Disable problematic NVIDIA driver features
3. **Udev rules** — Prevent power management from killing the GPU
4. **Systemd service** — Reliable boot-time GPU initialization with recovery

### Step 1: Kernel Boot Parameters

Edit `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pcie_aspm=off pcie_port_pm=off pcie_ports=native intel_iommu=on iommu=pt pci=realloc,assign-busses thunderbolt.clx=0 thunderbolt.host_reset=0"
```

| Parameter | Purpose |
|-----------|---------|
| `pcie_aspm=off` | Disable Active State Power Management — prevents link power-down |
| `pcie_port_pm=off` | Disable port power management |
| `pcie_ports=native` | Use native PCIe port enumeration |
| `intel_iommu=on iommu=pt` | Enable IOMMU in passthrough mode for proper GPU resource allocation |
| `pci=realloc,assign-busses` | Allow kernel to reallocate PCI resources for hot-plugged TB devices |
| `thunderbolt.clx=0` | Disable Thunderbolt CL power states |
| `thunderbolt.host_reset=0` | Disable host-initiated resets that destabilize the link |

Apply with:
```bash
sudo update-grub
sudo reboot
```

### Step 2: NVIDIA Module Configuration

Create `/etc/modprobe.d/nvidia-egpu.conf`:

```bash
# Thunderbolt eGPU on MS-01 + DEG2
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm

options nvidia NVreg_EnableGpuFirmware=0
options nvidia NVreg_DynamicPowerManagement=0
options nvidia NVreg_EnableResizableBar=0
options nvidia NVreg_EnableS0ixPowerManagement=0
options nvidia NVreg_PreserveVideoMemoryAllocations=0
options nvidia_drm modeset=0
```

| Option | Purpose |
|--------|---------|
| `blacklist nvidia*` | Prevent auto-loading — we manually load after TB tunnel is ready |
| `NVreg_EnableGpuFirmware=0` | **CRITICAL** — Disables GSP firmware |
| `NVreg_DynamicPowerManagement=0` | Disable aggressive power management |
| `NVreg_EnableResizableBar=0` | Disable ReBAR for TB compatibility |
| `NVreg_EnableS0ixPowerManagement=0` | Disable S0ix sleep states |
| `NVreg_PreserveVideoMemoryAllocations=0` | Don't try to preserve VRAM on suspend |
| `modeset=0` | Disable display modesetting (compute-only) |

Apply with:
```bash
sudo update-initramfs -u
```

### Step 3: Udev Power Rules

Create `/etc/udev/rules.d/99-egpu-power.rules`:

```bash
# Keep Thunderbolt eGPU and its bridges out of D3cold
ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", TEST=="power/control", ATTR{power/control}="on"
ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", TEST=="d3cold_allowed", ATTR{d3cold_allowed}="0"

# Intel Thunderbolt 4/5 bridges (JHL9480)
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x5786", TEST=="power/control", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x5786", TEST=="d3cold_allowed", ATTR{d3cold_allowed}="0"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa76e", TEST=="power/control", ATTR{power/control}="on"

# NVIDIA HDMI audio steals tunnel bandwidth — leave it unbound
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", RUN+="/bin/sh -c 'echo -n %k > /sys/bus/pci/drivers/snd_hda_intel/unbind || true'"
```

Reload rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Step 4: Boot-time GPU Binding Service

Create `/usr/local/sbin/egpu-bind.sh`:

```bash
#!/bin/bash
set -euo pipefail
log() { echo "[egpu-bind] $*"; }
GPU_VID=0000:05:00.0
TB_UP=0000:03:00.0

wait_gpu() {
  local i
  for i in $(seq 1 30); do
    if [ -d /sys/bus/pci/devices/$GPU_VID ]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

harden() {
  local d
  for d in /sys/bus/pci/devices/0000:00:07.0 /sys/bus/pci/devices/$TB_UP \
           /sys/bus/pci/devices/0000:04:00.0 /sys/bus/pci/devices/$GPU_VID; do
    [ -d "$d" ] || continue
    echo on > "$d/power/control" || true
    echo 0 > "$d/d3cold_allowed" 2>/dev/null || true
  done
}

mmio_ok() {
  python3 - << 'PY'
import os, mmap, sys
path = "/sys/bus/pci/devices/0000:05:00.0/resource0"
try:
    fd = os.open(path, os.O_RDWR | os.O_SYNC)
    m = mmap.mmap(fd, 16, mmap.MAP_SHARED, mmap.PROT_READ)
    data = m[:16]
    m.close(); os.close(fd)
except Exception:
    sys.exit(1)
sys.exit(0 if data != b"\xff"*16 else 1)
PY
}

recover() {
  log "MMIO dead; resetting Thunderbolt PCI tree"
  if [ -d /sys/bus/pci/devices/$TB_UP ]; then
    echo 1 > /sys/bus/pci/devices/$TB_UP/remove || true
    sleep 2
  fi
  echo 1 > /sys/bus/pci/rescan
  sleep 4
}

if ! wait_gpu; then
  log "GPU never appeared"
  exit 1
fi
harden
if ! mmio_ok; then
  recover
  wait_gpu || { log "GPU gone after recover"; exit 1; }
  harden
fi
if ! mmio_ok; then
  log "MMIO still dead after recover"
  exit 1
fi
modprobe nvidia
modprobe nvidia_uvm || true
sleep 1
if command -v nvidia-smi >/dev/null; then
  nvidia-smi -pm 1 || true
  nvidia-smi
fi
log "bound"
```

Make executable:
```bash
sudo chmod +x /usr/local/sbin/egpu-bind.sh
```

Create `/etc/systemd/system/egpu-bind.service`:

```ini
[Unit]
Description=Bind NVIDIA eGPU after Thunderbolt tunnel is ready
After=bolt.service systemd-udev-settle.service
Wants=bolt.service
Before=ollama.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/egpu-bind.sh
RemainAfterExit=yes
TimeoutStartSec=90

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable egpu-bind.service
```

---

## Verification

### Check GPU Status

```bash
nvidia-smi
```

Expected output:
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.173.02             Driver Version: 580.173.02     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3090 Ti     On  |   00000000:05:00.0 Off |                  Off |
| 33%   42C    P2             96W /  450W |     738MiB /  24564MiB |      0%      Default |
+-----------------------------------------+------------------------+----------------------+
```

### Check Thunderbolt Link

```bash
boltctl list
```

### Check Kernel Parameters Applied

```bash
cat /proc/cmdline | grep -o 'pcie_aspm=off\|intel_iommu=on\|thunderbolt.clx=0'
```

### Test with Ollama

```bash
ollama run llama3.2:3b "Hello, GPU!"
```

---

## Benchmarking for TB vs OCuLink Comparison

### Benchmark Script

Save as `/home/bryanwills/benchmark-egpu.sh`:

```bash
#!/bin/bash
# eGPU Inference Benchmark Script
# Tests token generation speed for Thunderbolt vs OCuLink comparison

MODEL="${1:-llama3.2:3b}"
PROMPT="Write a detailed 500-word essay about the history of artificial intelligence, from its origins to modern developments."

echo "=============================================="
echo "eGPU Inference Benchmark"
echo "=============================================="
echo "Date: $(date)"
echo "Model: $MODEL"
echo ""
echo "=== System Info ==="
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo ""
echo "=== Thunderbolt Link ==="
boltctl list 2>/dev/null | grep -E "(speed|status):" || echo "boltctl not available"
echo ""
echo "=== Running Inference Test ==="
echo ""

# Run ollama and capture output including the stats line
OUTPUT=$(ollama run "$MODEL" "$PROMPT" 2>&1)

echo "$OUTPUT"
echo ""
echo "=============================================="
echo "Benchmark Complete"
echo "=============================================="
```

### Running Benchmarks

```bash
chmod +x /home/bryanwills/benchmark-egpu.sh

# Test with different models
./benchmark-egpu.sh llama3.2:3b          # Small model baseline
./benchmark-egpu.sh qwen3:8b             # Medium model
./benchmark-egpu.sh qwen3.8:27b          # Target model for production
```

### Interpreting Results

Ollama prints stats at the end:
```
total duration:       12.3s
load duration:        1.2s
prompt eval count:    45 token(s)
prompt eval duration: 234ms
prompt eval rate:     192.31 tokens/s
eval count:           523 token(s)
eval duration:        11.06s
eval rate:            47.29 tokens/s   <-- This is your tok/s
```

**Expected Performance Ranges:**

| Connection | Bandwidth | Expected tok/s (3090 Ti, 27B model) |
|------------|-----------|-------------------------------------|
| Thunderbolt 4/5 | 40 Gb/s (effective ~20 Gb/s due to protocol overhead) | 15-25 tok/s |
| OCuLink PCIe 4.0 x4 | 64 Gb/s | 25-35 tok/s |
| Native PCIe x16 | 256 Gb/s | 35-50 tok/s |

*Note: Actual performance depends on model quantization, prompt length, and VRAM utilization.*

---

## Troubleshooting Guide

### Problem: GPU falls off bus after sleep/wake

**Solution:** Disable system suspend or add a wake-up script:

```bash
# Disable suspend
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### Problem: GPU not detected after cold boot

**Check:**
1. Dock power connected (both 24-pin ATX AND 8-pin EPS)
2. TB/OCuLink switch in correct position
3. Run `sudo journalctl -u egpu-bind.service` to see binding logs

### Problem: Low performance (< 10 tok/s)

**Check:**
1. Ensure Ollama is using GPU: `ollama ps` should show CUDA
2. Verify GPU isn't thermal throttling: `nvidia-smi -q -d TEMPERATURE`
3. Check link speed: `boltctl list`

### Problem: "NVRM: GPU has fallen off the bus" reappears

**Solution:** The MMIO recovery might have failed. Try:

```bash
# Manual recovery
sudo bash -c 'echo 1 > /sys/bus/pci/devices/0000:03:00.0/remove'
sleep 2
sudo bash -c 'echo 1 > /sys/bus/pci/rescan'
sleep 5
sudo modprobe nvidia NVreg_EnableGpuFirmware=0
nvidia-smi
```

---

## References

- [NVIDIA Linux Driver README](https://download.nvidia.com/XFree86/Linux-x86_64/latest/README/)
- [eGPU.io Forums — Linux Thunderbolt eGPU Guide](https://egpu.io/forums/)
- [Arch Wiki — External GPU](https://wiki.archlinux.org/title/External_GPU)
- [Ubuntu Forums — Thunderbolt 3/4 eGPU](https://ubuntuforums.org/)
- [Minisforum MS-01 Specifications](https://www.minisforum.com/page/ms-01/)
- [Minisforum DEG2 V2 Documentation](https://www.minisforum.com/support/)

---

## Changelog

| Date | Change |
|------|--------|
| 2026-09-08 | Initial documentation after successful troubleshooting |
| 2026-09-08 | Added benchmark script and expected performance ranges |

---

*This guide is part of the office-plan infrastructure documentation.*
*Maintained at: `/home/bryanwills/office-plan/docs/infrastructure/eGPU/`*
