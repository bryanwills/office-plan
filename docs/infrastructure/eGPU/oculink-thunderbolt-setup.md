# MS-01 eGPU Setup — Oculink & Thunderbolt Dual-Mode Configuration

**Status:** ✅ Oculink WORKING | ⚠️ Thunderbolt CONFIGURED (needs physical test)  
**Last Updated:** 2026-09-11  
**Author:** Bryan Wills  
**Platform:** Minisforum MS-01 (i9-13900H) + Ubuntu 24.04 LTS + DEG2 V2 + RTX 3090 Ti

---

## Executive Summary

The MS-01 supports **both** Oculink and Thunderbolt connections to the DEG2 V2 eGPU dock. This document covers the dual-mode configuration that allows switching between connection types without reconfiguring the system.

| Connection | PCIe Path | GPU Bus ID | Bandwidth | Status |
|------------|-----------|------------|-----------|--------|
| **Oculink** | 00:06.0 → 01:00.0 | `0000:01:00.0` | PCIe 4.0 x4 (64 Gb/s) | ✅ Working |
| **Thunderbolt 4** | 00:07.0 → 03:00.0 → 05:00.0 | `0000:05:00.0` | 40 Gb/s (USB4 tunnel) | ⚠️ Configured |

---

## Current Working Configuration (Oculink)

### Hardware Path
```
00:06.0 PCI bridge: Intel Raptor Lake PCIe 4.0 Graphics Port
  └── 01:00.0 VGA: NVIDIA GeForce RTX 3090 Ti [10de:2203]
      └── 01:00.1 Audio: NVIDIA GA102 HD Audio [10de:1aef]
```

### Verified Working
```bash
$ nvidia-smi
Fri Sep 11 22:38:16 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.173.02             Driver Version: 580.173.02     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
|   0  NVIDIA GeForce RTX 3090 Ti     Off |   00000000:01:00.0 Off |                  Off |
| 30%   31C    P8              8W /  450W |   20020MiB /  24564MiB |      0%      Default |
+-----------------------------------------+------------------------+----------------------+
```

---

## Dual-Mode Boot Script

The updated `egpu-bind.sh` (v2) auto-detects which path the GPU is connected through:

**Location:** `/usr/local/sbin/egpu-bind.sh`

**Features:**
- Auto-detects GPU on Oculink (01:00.0) or Thunderbolt (05:00.0) path
- Hardens power management for the active path
- MMIO health check with path-specific recovery
- Loads NVIDIA driver with eGPU-safe options

**Source:** `/home/bryanwills/office-plan/scripts/egpu-bind-v2.sh`

---

## Thunderbolt Configuration

### Current Status
- **Hardware:** Two Intel Raptor Lake-P Thunderbolt 4 NHI controllers
- **Security Mode:** `user` (manual authorization required first time)
- **IOMMU DMA Protection:** Enabled
- **DEG2 Device:** Pre-authorized (UUID: `06d58780-00b7-6ad0-ffff-ffffffffffff`)

### To Test Thunderbolt Mode
1. Power off NUC
2. Disconnect Oculink cable
3. Set DEG2 switch to **Thunderbolt** position
4. Connect Thunderbolt cable (NUC TB port → DEG2 TB port)
5. Power on NUC
6. Verify: `boltctl list` should show TBGAA as `connected`
7. Verify: `nvidia-smi` should show GPU at `05:00.0`

---

## Thunderbolt 5 PCIe Card Recommendations

The MS-01 has a single PCIe 4.0 x16 slot (currently used for the X710 10GbE NIC). For **dedicated** Thunderbolt 5 connectivity, consider these options:

### Option 1: Intel Thunderbolt 5 AIC (Recommended)
| Spec | Detail |
|------|--------|
| **Model** | Intel Thunderbolt 5 Connect AIC (Alpine Ridge successor) |
| **Interface** | PCIe 4.0 x4 |
| **Ports** | 2x USB-C (TB5 80Gbps bidirectional, 120Gbps with Bandwidth Boost) |
| **Estimated Price** | $150-200 |
| **Availability** | Limited as of 2026 (check Intel ARK, Newegg, Amazon) |
| **Notes** | Native Linux support in kernel 6.8+; your 7.0.0 kernel should work |

### Option 2: ASUS ThunderboltEX 5
| Spec | Detail |
|------|--------|
| **Model** | ASUS ThunderboltEX 5 |
| **Interface** | PCIe 4.0 x4 + internal TB header |
| **Ports** | 2x USB-C TB5 + 1x USB-A 3.2 |
| **Price** | ~$130-150 |
| **Notes** | Requires motherboard TB header (MS-01 may not have one) |

### Option 3: Gigabyte GC-TITAN RIDGE 2.0 (TB4, not TB5)
| Spec | Detail |
|------|--------|
| **Model** | Gigabyte GC-TITAN RIDGE 2.0 |
| **Interface** | PCIe 3.0 x4 |
| **Ports** | 2x TB4 USB-C + 1x Mini DisplayPort |
| **Price** | ~$80-100 |
| **Notes** | TB4 only (40Gbps), but proven Linux compatibility |

### Recommendation
For the MS-01 with the DEG2 V2 dock, **the built-in Thunderbolt 4 is sufficient** for eGPU compute workloads (40 Gb/s is the bottleneck regardless of TB5 on the card side, since the DEG2's internal PCIe tunnel is the limit). 

**Only add a TB5 PCIe card if:**
- You need a second TB port while the built-in is in use
- You're connecting to a future TB5-native eGPU dock with >40Gbps tunnel

---

## Performance Comparison (Expected)

| Connection | Theoretical BW | Effective BW | Use Case |
|------------|----------------|--------------|----------|
| **Oculink PCIe 4.0 x4** | 64 Gb/s | ~50-55 Gb/s | Best for local inference |
| **Thunderbolt 4** | 40 Gb/s | ~20-25 Gb/s | Good for portability |
| **Thunderbolt 5** | 80-120 Gb/s | ~40-60 Gb/s | Future-proofing |
| **Native PCIe x16** | 256 Gb/s | ~200 Gb/s | Desktop baseline |

**For LLM inference (qwen3.8:27b):** Oculink provides ~30-50% more bandwidth than TB4, but the real bottleneck is often VRAM bandwidth (936 GB/s on 3090 Ti), not the external link. Both connections are viable for local AI.

---

## Driver & Kernel Configuration

### Kernel Parameters (GRUB)
```
pcie_aspm=off pcie_port_pm=off pcie_ports=native 
intel_iommu=on iommu=pt pci=realloc,assign-busses 
thunderbolt.clx=0 thunderbolt.host_reset=0 
nvidia.NVreg_EnableGpuFirmware=0
```

### NVIDIA Module Options (`/etc/modprobe.d/nvidia-egpu.conf`)
```
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

### Driver Version
- **NVIDIA Driver:** 580.173.02
- **CUDA Version:** 13.0
- **DKMS Status:** Built for kernel 7.0.0-31-generic

---

## Switching Between Modes

### From Oculink to Thunderbolt
```bash
# 1. Save work
# 2. Power off NUC
sudo shutdown -h now

# 3. Physical changes:
#    - Disconnect Oculink cable
#    - Set DEG2 switch to TB
#    - Connect TB cable

# 4. Power on NUC
# 5. Verify
boltctl list
nvidia-smi
```

### From Thunderbolt to Oculink
```bash
# 1. Save work
# 2. Power off NUC
sudo shutdown -h now

# 3. Physical changes:
#    - Disconnect TB cable
#    - Set DEG2 switch to Oculink
#    - Connect Oculink cable

# 4. Power on NUC
# 5. Rescan and load driver (if not automatic)
sudo bash -c 'echo 1 > /sys/bus/pci/rescan'
sudo modprobe nvidia NVreg_EnableGpuFirmware=0
nvidia-smi
```

---

## Troubleshooting

### GPU Not Detected After Switch
```bash
# Rescan PCIe bus
sudo bash -c 'echo 1 > /sys/bus/pci/rescan'

# Check if GPU appears
lspci | grep -i nvidia

# Load driver manually
sudo modprobe nvidia NVreg_EnableGpuFirmware=0
```

### Thunderbolt Device Not Authorized
```bash
# List devices
boltctl list

# Authorize (first time only)
boltctl authorize <UUID>
# or
boltctl enroll <UUID>  # Permanent authorization
```

### MMIO Failures (GPU Fallen Off Bus)
See: [`thunderbolt-egpu-troubleshooting-guide.md`](./thunderbolt-egpu-troubleshooting-guide.md)

---

## Files Reference

| File | Purpose |
|------|---------|
| `/usr/local/sbin/egpu-bind.sh` | Boot-time GPU binding (v2, dual-mode) |
| `/etc/modprobe.d/nvidia-egpu.conf` | NVIDIA driver options |
| `/etc/udev/rules.d/99-egpu-power.rules` | Power management rules |
| `/etc/systemd/system/egpu-bind.service` | Systemd service |
| `~/test-egpu-readiness.sh` | Quick diagnostic script |
| `~/benchmark-egpu.sh` | Performance benchmark script |

---

## Related Documentation

- [`ai-rig-build-log.md`](./ai-rig-build-log.md) — Full build history
- [`thunderbolt-egpu-troubleshooting-guide.md`](./thunderbolt-egpu-troubleshooting-guide.md) — Detailed troubleshooting
- [`connection-status-20260911.md`](./connection-status-20260911.md) — Diagnostic report

---

*Last updated: 2026-09-11*
