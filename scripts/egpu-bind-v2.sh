#!/bin/bash
# eGPU Bind Script v3 - OCuLink (PEG 00:01.0) + Thunderbolt + live Xid 79 recovery
# For: MS-01 + DEG2 V2 + RTX 3090 Ti
#
# OCuLink path:     GPU at 01:00.0 via PEG bridge 00:01.0
# Thunderbolt path: GPU at 05:00.0 via TB root port 00:07.0
#
set -euo pipefail

log() { echo "[egpu-bind] $*" >&2; }

OCULINK_GPU="0000:01:00.0"
OCULINK_PARENT="0000:00:01.0"
TB_GPU="0000:05:00.0"
TB_BRIDGE="0000:03:00.0"

detect_gpu() {
    local gpu_path=""

    if [ -d "/sys/bus/pci/devices/$OCULINK_GPU" ] \
        && lspci -s "${OCULINK_GPU#0000:}" 2>/dev/null | grep -qi nvidia; then
        log "GPU detected on OCuLink/PEG path: $OCULINK_GPU"
        echo "$OCULINK_GPU"
        return 0
    fi

    if [ -d "/sys/bus/pci/devices/$TB_GPU" ] \
        && lspci -s "${TB_GPU#0000:}" 2>/dev/null | grep -qi nvidia; then
        log "GPU detected on Thunderbolt path: $TB_GPU"
        echo "$TB_GPU"
        return 0
    fi

    gpu_path=$(lspci -d 10de: 2>/dev/null | grep -iE "VGA|3D" | head -1 | awk '{print "0000:"$1}' || true)
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
    local devices=("$gpu_path")

    if [[ "$gpu_path" == "$TB_GPU" ]]; then
        devices+=("0000:00:07.0" "0000:00:07.2" "$TB_BRIDGE" "0000:04:00.0")
    else
        devices+=("$OCULINK_PARENT")
    fi

    local d
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
if data == b"\xff" * 16:
    print("MMIO returned all 0xFF - GPU unresponsive", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

nvidia_smi_ok() {
    command -v nvidia-smi >/dev/null || return 1
    nvidia-smi -L >/dev/null 2>&1
}

unload_nvidia() {
    log "Unloading NVIDIA modules"
    systemctl stop nvidia-persistenced.service 2>/dev/null || true
    killall nvidia-persistenced 2>/dev/null || true
    sleep 1
    local mod
    for mod in nvidia_uvm nvidia_drm nvidia_modeset nvidia; do
        if lsmod | grep -q "^${mod} "; then
            rmmod "$mod" 2>/dev/null || modprobe -r "$mod" 2>/dev/null || true
        fi
    done
    sleep 1
}

load_nvidia() {
    log "Loading NVIDIA modules (GSP off, DRM modeset on for HDMI)"
    modprobe nvidia NVreg_EnableGpuFirmware=0
    modprobe nvidia_modeset || true
    modprobe nvidia_drm modeset=1 fbdev=1 || true
    modprobe nvidia_uvm || true
    sleep 2
}

pci_remove_device() {
    local dev="$1"
    if [ -e "/sys/bus/pci/devices/$dev/remove" ]; then
        echo 1 > "/sys/bus/pci/devices/$dev/remove" || true
    fi
}

recover_oculink() {
    local gpu_path="$1"
    local audio="${gpu_path%.*}.1"
    log "Resetting OCuLink GPU $gpu_path (parent $OCULINK_PARENT)"

    unload_nvidia

    if [ -e "/sys/bus/pci/devices/$gpu_path/reset" ]; then
        log "Attempting PCI function-level reset"
        echo 1 > "/sys/bus/pci/devices/$gpu_path/reset" 2>/dev/null || true
        sleep 2
    fi

    pci_remove_device "$audio"
    pci_remove_device "$gpu_path"
    sleep 2
    echo 1 > /sys/bus/pci/rescan
    sleep 4
}

recover_thunderbolt() {
    log "Resetting Thunderbolt PCI tree"
    unload_nvidia
    if [ -d "/sys/bus/pci/devices/$TB_BRIDGE" ]; then
        echo 1 > "/sys/bus/pci/devices/$TB_BRIDGE/remove" || true
        sleep 2
    fi
    echo 1 > /sys/bus/pci/rescan
    sleep 4
}

# === Main ===

log "Starting eGPU bind (v3 - OCuLink parent 00:01.0 + live recovery)"

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
harden_power "$GPU_PATH"

NEED_RECOVER=0
if ! mmio_ok "$GPU_PATH"; then
    NEED_RECOVER=1
    log "MMIO dead"
elif lsmod | grep -q "^nvidia " && ! nvidia_smi_ok; then
    NEED_RECOVER=1
    log "NVIDIA modules loaded but nvidia-smi failed (likely Xid 79)"
fi

if [ "$NEED_RECOVER" -eq 1 ]; then
    log "Attempting live GPU recovery"
    if [[ "$GPU_PATH" == "$TB_GPU" ]]; then
        recover_thunderbolt
    else
        recover_oculink "$GPU_PATH"
    fi

    sleep 2
    GPU_PATH=$(detect_gpu) || { log "GPU gone after recovery"; exit 1; }
    harden_power "$GPU_PATH"

    if ! mmio_ok "$GPU_PATH"; then
        log "ERROR: MMIO still dead after recovery — power-cycle the DEG2 PSU, wait 10s, power on, then rerun"
        exit 1
    fi
fi

log "MMIO OK"

if ! lsmod | grep -q "^nvidia "; then
    load_nvidia
else
    log "NVIDIA modules already loaded"
fi

if command -v nvidia-smi >/dev/null; then
    nvidia-smi -pm 1 2>/dev/null || true
    if nvidia_smi_ok; then
        log "GPU Status:"
        nvidia-smi --query-gpu=name,driver_version,memory.total,pci.bus_id --format=csv,noheader
        log "eGPU bound successfully on ${GPU_PATH}"
    else
        log "ERROR: nvidia-smi still failing after bind. Power-cycle the DEG2 dock PSU."
        exit 1
    fi
fi
