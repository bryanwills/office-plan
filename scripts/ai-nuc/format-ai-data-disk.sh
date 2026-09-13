#!/usr/bin/env bash
#
# format-ai-data-disk.sh
# Wipe ONE specific USB disk (the SanDisk labeled "AI") and make it the
# stateful home for /opt/stacks and /opt/backups.
#
# SAFETY: this script will refuse to run unless the target serial matches
# the second drive connected on 2026-09-13. It will never touch:
#   - the internal Kingston boot NVMe
#   - the SanDisk labeled OllamaDrive (Mac model library)
#
# Run: sudo ./scripts/ai-nuc/format-ai-data-disk.sh
#
set -euo pipefail

# Second drive plugged in at 12:37. Label was "AI" (exFAT).
TARGET_SERIAL="323531334830343032323735"
TARGET_ID="usb-SanDisk_Extreme_55AE_${TARGET_SERIAL}-0:0"
DISK="/dev/disk/by-id/${TARGET_ID}"
KEEP_SERIAL="323531334830343036333436"   # OllamaDrive, do not touch
MOUNTPOINT="/mnt/ai-data"
FSTAB_COMMENT="# ai-data (SanDisk Extreme 55AE ${TARGET_SERIAL}) — stacks + chat/memory"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

if [[ ! -b "${DISK}" ]]; then
  echo "Target disk not found: ${DISK}" >&2
  echo "Is the AI-labeled SanDisk plugged in?" >&2
  exit 1
fi

REAL="$(readlink -f "${DISK}")"
KEEP_DISK="/dev/disk/by-id/usb-SanDisk_Extreme_55AE_${KEEP_SERIAL}-0:0"
if [[ -b "${KEEP_DISK}" ]]; then
  KEEP_REAL="$(readlink -f "${KEEP_DISK}")"
  if [[ "${REAL}" == "${KEEP_REAL}" ]]; then
    echo "REFUSED: resolved to OllamaDrive (${KEEP_SERIAL}). Aborting." >&2
    exit 2
  fi
fi

if [[ "${REAL}" == /dev/nvme0n1* ]] || [[ "${REAL}" == /dev/nvme0n1 ]]; then
  echo "REFUSED: resolved to the boot NVMe. Aborting." >&2
  exit 2
fi

LABEL="$(lsblk -no LABEL "${REAL}" 2>/dev/null | head -1 || true)"
# Whole-disk label is empty; check partition 2 if present
if [[ -z "${LABEL}" && -b "${REAL}2" ]]; then
  LABEL="$(lsblk -no LABEL "${REAL}2" 2>/dev/null | head -1 || true)"
fi

echo "About to DESTROY all data on:"
echo "  by-id : ${TARGET_ID}"
echo "  device: ${REAL}"
echo "  label : ${LABEL:-<none>}"
echo "  size  : $(lsblk -ndno SIZE "${REAL}")"
echo
echo "OllamaDrive (${KEEP_SERIAL}) will not be touched."
echo

# Unmount anything on the KEEP disk if a desktop automounter grabbed it
if [[ -b "${KEEP_DISK}" ]]; then
  KEEP_REAL="$(readlink -f "${KEEP_DISK}")"
  for part in "${KEEP_REAL}" "${KEEP_REAL}"[0-9]*; do
    [[ -b "${part}" ]] || continue
    if findmnt -n "${part}" >/dev/null 2>&1; then
      echo "Unmounting OllamaDrive partition ${part} first..."
      umount "${part}" || umount -l "${part}"
    fi
  done
fi

# Unmount target if automounted
for part in "${REAL}" "${REAL}"[0-9]*; do
  [[ -b "${part}" ]] || continue
  if findmnt -n "${part}" >/dev/null 2>&1; then
    echo "Unmounting ${part}..."
    umount "${part}" || umount -l "${part}"
  fi
done

echo "Wiping signatures and partitioning ${REAL}..."
wipefs -a "${REAL}"
sgdisk --zap-all "${REAL}"
sgdisk -n 1:0:0 -t 1:8300 -c 1:ai-data "${REAL}"
partprobe "${REAL}" || true
sleep 2

PART="${DISK}-part1"
if [[ ! -b "${PART}" ]]; then
  PART="${REAL}1"
fi
if [[ ! -b "${PART}" ]]; then
  echo "Partition did not appear after sgdisk. Aborting." >&2
  ls -l /dev/disk/by-id/usb-SanDisk* || true
  exit 3
fi

echo "Creating ext4 filesystem labeled ai-data on ${PART}..."
mkfs.ext4 -F -L ai-data -m 1 "${PART}"
tune2fs -c 0 -i 0 "${PART}"

UUID="$(blkid -s UUID -o value "${PART}")"
if [[ -z "${UUID}" ]]; then
  echo "Could not read new UUID. Aborting before fstab change." >&2
  exit 4
fi

mkdir -p "${MOUNTPOINT}"
if grep -q " ${MOUNTPOINT} " /etc/fstab; then
  echo "fstab already has ${MOUNTPOINT}; leaving that line in place."
else
  echo "${FSTAB_COMMENT}" >> /etc/fstab
  echo "UUID=${UUID}  ${MOUNTPOINT}  ext4  defaults,noatime,nofail,x-systemd.device-timeout=8  0  2" >> /etc/fstab
fi

mount "${MOUNTPOINT}"
mkdir -p \
  "${MOUNTPOINT}/stacks" \
  "${MOUNTPOINT}/backups" \
  "${MOUNTPOINT}/archive" \
  "${MOUNTPOINT}/apps" \
  "${MOUNTPOINT}/lost+found"

chown -R bryanwills:docker "${MOUNTPOINT}/stacks" "${MOUNTPOINT}/backups" "${MOUNTPOINT}/archive" "${MOUNTPOINT}/apps"
chmod 775 "${MOUNTPOINT}/stacks" "${MOUNTPOINT}/backups" "${MOUNTPOINT}/archive" "${MOUNTPOINT}/apps"

mkdir -p /opt
if [[ -e /opt/stacks && ! -L /opt/stacks ]]; then
  echo "NOTE: /opt/stacks exists and is not a symlink. Leaving it. Data dir is ${MOUNTPOINT}/stacks"
else
  ln -sfn "${MOUNTPOINT}/stacks" /opt/stacks
fi
if [[ -e /opt/backups && ! -L /opt/backups ]]; then
  echo "NOTE: /opt/backups exists and is not a symlink. Leaving it. Data dir is ${MOUNTPOINT}/backups"
else
  ln -sfn "${MOUNTPOINT}/backups" /opt/backups
fi

echo
echo "Done."
echo "  filesystem : ${MOUNTPOINT} (UUID=${UUID})"
echo "  stacks     : /opt/stacks -> ${MOUNTPOINT}/stacks"
echo "  backups    : /opt/backups -> ${MOUNTPOINT}/backups"
echo "  archive    : ${MOUNTPOINT}/archive"
df -h "${MOUNTPOINT}"
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT "${REAL}"
