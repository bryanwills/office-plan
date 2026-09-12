#!/bin/bash
# eGPU Bind Script v2 - Supports both Oculink and Thunderbolt
# For: MS-01 + DEG2 V2 + RTX 3090 Ti
# 
# Oculink path:     GPU appears at 01:00.0 (via PCIe Graphics Port 00:06.0)
# Thunderbolt path: GPU appears at 05:00.0 (via TB Root Port 00:07.0)
#
set -euo pipefail

log() { echo "[egpu-bind] $*" >&2; }

# Known GPU locations
OCULINK_GPU="0000:01:00.0"
TB_GPU="0000:05:00.0"
TB_BRIDGE="0000:03:00.0"

# Detect which path the GPU is on
detect_gpu() {
    local gpu_path=""
    
    # Check Oculink path first (more direct, faster)
    if [ -d "/sys/bus/pci/devices/$OCULINK_GPU" ]; then
        if lspci -s "${OCULINK_GPU#0000:}" 2>/dev/null | grep -qi nvidia; then
            gpu_path="$OCULINK_GPU"
            log "GPU detected on Oculink path: $gpu_path"
            echo "$gpu_path"
            return 0
        fi
    fi
    
    # Check Thunderbolt path
    if [ -d "/sys/bus/pci/devices/$TB_GPU" ]; then
        if lspci -s "${TB_GPU#0000:}" 2>/dev/null | grep -qi nvidia; then
            gpu_path="$TB_GPU"
            log "GPU detected on Thunderbolt path: $gpu_path"
            echo "$gpu_path"
            return 0
        fi
    fi
    
    # Fallback: scan all PCI for NVIDIA VGA
    gpu_path=$(lspci -d 10de: 2>/dev/null | grep -i "VGA\|3D" | head -1 | awk '{print "0000:"$1}' || true)
    if [ -n "$gpu_path" ] && [ -d "/sys/bus/pci/devices/$gpu_path" ]; then
        log "GPU detected via scan: $gpu_path"
        echo "$gpu_path"
        return 0
    fi
    
    return 1
}

wait_gpu() {
    local i
    for i in $(seq 1 30); do
        if detect_gpu >/dev/null 2>&1; then
            return 0
        fi
        log "Waiting for GPU... ($i/30)"
        sleep 1
    done
    return 1
}

harden_power() {
    local gpu_path="$1"
    local devices=()
    
    # Always include the GPU
    devices+=("$gpu_path")
    
    # Include relevant bridges based on path
    if [[ "$gpu_path" == "$TB_GPU" ]]; then
        # Thunderbolt path
        devices+=("0000:00:07.0" "0000:00:07.2" "$TB_BRIDGE" "0000:04:00.0")
    elif [[ "$gpu_path" == "$OCULINK_GPU" ]]; then
        # Oculink path (PCIe Graphics Port)
        devices+=("0000:00:06.0")
    fi
    
    for d in "${devices[@]}"; do
        [ -d "/sys/bus/pci/devices/$d" ] || continue
        echo on > "/sys/bus/pci/devices/$d/power/control" 2>/dev/null || true
        echo 0 > "/sys/bus/pci/devices/$d/d3cold_allowed" 2>/dev/null || true
        log "Hardened power for $d"
    done
}

mmio_ok() {
    local gpu_path="$1"
    python3 - "$gpu_path" << 'PY'
import os, mmap, sys
gpu = sys.argv[1]
path = f"/sys/bus/pci/devices/{gpu}/resource0"
try:
    fd = os.open(path, os.O_RDWR | os.O_SYNC)
    m = mmap.mmap(fd, 16, mmap.MAP_SHARED, mmap.PROT_READ)
    data = m[:16]
    m.close()
    os.close(fd)
except Exception as e:
    print(f"MMIO check failed: {e}", file=sys.stderr)
    sys.exit(1)
# All 0xFF means GPU is unresponsive
if data == b"\xff"*16:
    print("MMIO returned all 0xFF - GPU unresponsive", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

recover_thunderbolt() {
    log "MMIO dead; resetting Thunderbolt PCI tree"
    if [ -d "/sys/bus/pci/devices/$TB_BRIDGE" ]; then
        echo 1 > "/sys/bus/pci/devices/$TB_BRIDGE/remove" || true
        sleep 2
    fi
    echo 1 > /sys/bus/pci/rescan
    sleep 4
}

recover_oculink() {
    log "MMIO issue on Oculink; attempting rescan"
    echo 1 > /sys/bus/pci/rescan
    sleep 3
}

# === Main ===

log "Starting eGPU bind (v2 - dual-mode)"

# Wait for GPU to appear
if ! wait_gpu; then
    log "ERROR: GPU never appeared on any path"
    exit 1
fi

GPU_PATH=$(detect_gpu)
if [ -z "$GPU_PATH" ]; then
    log "ERROR: Could not determine GPU path"
    exit 1
fi

log "Using GPU at: $GPU_PATH"

# Harden power management
harden_power "$GPU_PATH"

# Check MMIO
if ! mmio_ok "$GPU_PATH"; then
    log "MMIO check failed, attempting recovery..."
    
    if [[ "$GPU_PATH" == "$TB_GPU" ]]; then
        recover_thunderbolt
    else
        recover_oculink
    fi
    
    # Re-detect after recovery
    sleep 2
    GPU_PATH=$(detect_gpu) || { log "GPU gone after recovery"; exit 1; }
    harden_power "$GPU_PATH"
    
    if ! mmio_ok "$GPU_PATH"; then
        log "ERROR: MMIO still dead after recovery"
        exit 1
    fi
fi

log "MMIO OK"

# Load NVIDIA driver with eGPU-safe options
if ! lsmod | grep -q "^nvidia "; then
    log "Loading NVIDIA modules..."
    modprobe nvidia NVreg_EnableGpuFirmware=0
    modprobe nvidia_uvm || true
    modprobe nvidia_drm modeset=0 || true
    sleep 1
else
    log "NVIDIA modules already loaded"
fi

# Enable persistence mode and verify
if command -v nvidia-smi >/dev/null; then
    nvidia-smi -pm 1 2>/dev/null || true
    log "GPU Status:"
    nvidia-smi --query-gpu=name,driver_version,memory.total,pci.bus_id --format=csv,noheader
fi

log "eGPU bound successfully on ${GPU_PATH}"
