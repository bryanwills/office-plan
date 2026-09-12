# eGPU Connection Status Report — 2026-09-11

**Generated:** Friday Sep 11, 2026 at 9:26 PM EDT  
**System:** ai-nuc (Minisforum MS-01, Intel i9-13900H, Ubuntu 24.04.5 LTS, Kernel 7.0.0-31-generic)

---

## Executive Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Thunderbolt Hardware** | ✅ Ready | Two TB4 controllers active, drivers loaded |
| **Thunderbolt Driver** | ✅ Ready | thunderbolt.ko loaded, bolt.service running |
| **eGPU Enclosure (TBGAA/DEG2)** | ❌ Disconnected | Last connected: Thu Sep 10, 04:23:28 |
| **Oculink Port** | ⚠️ Unknown | No device detected on PCIe Graphics Port |
| **NVIDIA Driver** | ✅ Installed | nvidia-580.173.02 DKMS built for kernel 7.0.0-31-generic |
| **NVIDIA Module** | ⏸️ Blacklisted | Intentionally blacklisted for eGPU hotplug support |

---

## 1. Thunderbolt Status — READY ✅

### Controllers
```
00:0d.2 USB controller: Intel Raptor Lake-P Thunderbolt 4 NHI #0 [8086:a73e]
        Kernel driver in use: thunderbolt
        
00:0d.3 USB controller: Intel Raptor Lake-P Thunderbolt 4 NHI #1 [8086:a76d]
        Kernel driver in use: thunderbolt
```

### PCIe Root Ports
| Port | Bus ID | Address | Slot | Adapter | Power |
|------|--------|---------|------|---------|-------|
| TB4 Root Port #0 | 00:07.0 | secondary=03 | Slot 3 | ❌ None | ✅ On |
| TB4 Root Port #2 | 00:07.2 | secondary=04 | Slot 5 | ❌ None | ✅ On |

### Domains
| Domain | Host Controller | Devices | Security | IOMMU DMA |
|--------|-----------------|---------|----------|-----------|
| domain0 | 0000:00:0d.2 | Gen12 (internal) | user | ✅ Protected |
| domain1 | 0000:00:0d.3 | Gen12 (internal) | user | ✅ Protected |

### Bolt Service
```
● bolt.service - Thunderbolt system service
     Active: active (running) since Fri 2026-09-11 20:04:40 EDT
```

### Known Devices
```
TBGAA (Minisforum DEG2 eGPU Enclosure)
├── UUID: 06d58780-00b7-6ad0-ffff-ffffffffffff
├── Generation: USB4
├── Status: DISCONNECTED ❌
├── Policy: iommu
├── Last Connected: Thu Sep 10, 04:23:28 2026
└── Authorization: Pre-authorized (stored)
```

---

## 2. Oculink / PCIe Graphics Port Status — UNKNOWN ⚠️

### Port Identification
```
00:06.0 PCI bridge: Intel Raptor Lake PCIe 4.0 Graphics Port [8086:a74d]
        Bus: primary=00, secondary=01
        Memory behind bridge: 6c900000-6c9fffff [size=1M]
```

### Currently Connected Device
```
01:00.0 NVMe: Kingston Technology Company, Inc. Device 502d
        Kernel driver: nvme
```

**Note:** The PCIe Graphics Port (00:06.0) currently has an NVMe drive connected, not a GPU. This is likely your primary system drive. If you have a separate Oculink port for the eGPU, it may be on a different bus or require a physical connection to the DEG2 dock.

### PCIe Errors Detected
```
⚠️ ACS Violation errors at boot on 00:06.0
   Status: Recovered automatically
```

---

## 3. NVIDIA Driver Status — INSTALLED ✅

### Driver Version
```
nvidia/580.173.02, 7.0.0-31-generic, x86_64: installed (DKMS)
```

### Available Packages
| Package | Version |
|---------|---------|
| nvidia-driver-580 | 580.173.02-0ubuntu0.24.04.1 |
| nvidia-dkms-580 | 580.173.02-0ubuntu0.24.04.1 |
| nvidia-utils-580 | 580.173.02-0ubuntu0.24.04.1 |
| cuda (bundled) | 13.0 |

### Module Status
```
nvidia modules: BLACKLISTED (intentional for eGPU hotplug)

Configuration: /etc/modprobe.d/nvidia-egpu.conf
├── blacklist nvidia
├── blacklist nvidia_drm
├── blacklist nvidia_modeset
├── blacklist nvidia_uvm
├── NVreg_EnableGpuFirmware=0    ← Critical for TB eGPU
├── NVreg_DynamicPowerManagement=0
├── NVreg_EnableResizableBar=0
├── NVreg_EnableS0ixPowerManagement=0
└── NVreg_PreserveVideoMemoryAllocations=0
```

---

## 4. Boot Service Status — FAILED (Expected)

### egpu-bind.service
```
× egpu-bind.service - Bind NVIDIA eGPU after Thunderbolt tunnel is ready
     Active: failed (Result: exit-code) since Fri 2026-09-11 20:04:44 EDT
     
Log:
  [egpu-bind] MMIO dead; resetting Thunderbolt PCI tree
  [egpu-bind] MMIO still dead after recover
```

**Reason:** Service failed because no GPU is connected. The script looks for device at `0000:05:00.0` which is currently an Intel Ethernet controller, not the RTX 3090 Ti. This is expected behavior when the eGPU is not connected.

---

## 5. Kernel Parameters — APPLIED ✅

Current boot parameters for eGPU support:
```
pcie_aspm=off              ✅ ASPM disabled
pcie_port_pm=off           ✅ Port PM disabled
pcie_ports=native          ✅ Native enumeration
intel_iommu=on             ✅ IOMMU enabled
iommu=pt                   ✅ Passthrough mode
pci=realloc,assign-busses  ✅ Dynamic allocation
thunderbolt.clx=0          ✅ CLx disabled
thunderbolt.host_reset=0   ✅ Host reset disabled
```

---

## 6. Actions Required for Testing

### For Thunderbolt eGPU:
1. **Connect the DEG2 dock** via Thunderbolt cable
2. **Verify power** — Both 24-pin ATX AND 8-pin EPS connected to dock
3. **Check switch position** — TB/OCuLink switch in TB position
4. **Run authorization** (if needed):
   ```bash
   boltctl list
   boltctl authorize 06d58780-00b7-6ad0-ffff-ffffffffffff
   ```
5. **Restart egpu-bind service**:
   ```bash
   sudo systemctl restart egpu-bind.service
   sudo journalctl -u egpu-bind.service -f
   ```
6. **Verify GPU**:
   ```bash
   nvidia-smi
   ```

### For Oculink eGPU:
1. **Determine physical port** — Check if MS-01 has a dedicated Oculink connector or if it shares with DEG2
2. **Switch DEG2 to Oculink mode** (if applicable)
3. **Connect Oculink cable**
4. **Rescan PCIe**:
   ```bash
   sudo bash -c 'echo 1 > /sys/bus/pci/rescan'
   lspci | grep -i nvidia
   ```
5. **Load NVIDIA driver**:
   ```bash
   sudo modprobe nvidia NVreg_EnableGpuFirmware=0
   nvidia-smi
   ```

---

## 7. Diagnostic Commands

### Quick Status Check
```bash
# Thunderbolt
boltctl list

# PCIe devices
lspci | grep -E "(VGA|3D|Display|NVIDIA)"

# NVIDIA driver
nvidia-smi

# Service status
systemctl status egpu-bind.service

# Kernel messages
journalctl -k | grep -iE "(thunderbolt|nvidia|gpu)" | tail -20
```

### Test Connection Script
```bash
#!/bin/bash
echo "=== Thunderbolt Status ==="
boltctl list | grep -E "(name|status|connected)"

echo -e "\n=== PCIe Slots ==="
for slot in /sys/bus/pci/slots/*/; do
  echo "$(basename $slot): adapter=$(cat $slot/adapter 2>/dev/null)"
done

echo -e "\n=== GPU Detection ==="
lspci | grep -iE "(nvidia|vga|3d)"

echo -e "\n=== NVIDIA Driver ==="
nvidia-smi 2>&1 | head -5
```

---

## 8. Known Issues

### 1. i40e Bandwidth Warning
```
i40e 0000:02:00.0: PCI-Express bandwidth available for this device may be insufficient
```
**Status:** Informational only — 10GbE NICs requesting more lanes than available. Not affecting operation.

### 2. NVMe I/O Errors (Historical)
```
nvme0n1: I/O Cmd(0x2) @ LBA xxxxxxxx, I/O Error (sct 0x3 / sc 0x71)
```
**Status:** Occurred at boot, may indicate drive issues. Monitor if recurring.

### 3. libapt-pkg Segfaults
Multiple segfaults in apt-related processes detected. Unrelated to eGPU but should be investigated.

---

## 9. Hardware Reference

| Component | Model | Connection |
|-----------|-------|------------|
| Host | Minisforum MS-01 (i9-13900H) | — |
| eGPU Dock | Minisforum DEG2 V2 | TB5/Oculink switchable |
| GPU | EVGA RTX 3090 Ti FTW3 Ultra 24GB | 12V-2x6 power |
| PSU | Corsair RM1000x | 1000W |
| Cable | OWC Thunderbolt 5 Pro 0.3m | 80 Gb/s rated |

---

## Next Steps

1. [ ] Connect Thunderbolt eGPU enclosure
2. [ ] Verify GPU detection with `nvidia-smi`
3. [ ] Run benchmark: `./benchmark-egpu.sh llama3.2:3b thunderbolt`
4. [ ] Switch to Oculink and repeat tests
5. [ ] Document performance comparison

---

*Report generated as part of office-plan infrastructure documentation*  
*Related docs:*
- [`thunderbolt-egpu-troubleshooting-guide.md`](./thunderbolt-egpu-troubleshooting-guide.md)
- [`ai-rig-build-log.md`](./ai-rig-build-log.md)
