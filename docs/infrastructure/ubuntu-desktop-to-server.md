# Ubuntu Desktop → Server Conversion (ai-nuc)

**Status:** ⏳ Planned  
**Last Updated:** 2026-09-11  
**Platform:** Ubuntu 24.04.5 LTS Desktop → Server (headless)

---

## Overview

Convert the ai-nuc from Ubuntu Desktop to a headless server configuration while preserving:
- NVIDIA drivers (580.173.02)
- eGPU configuration (Oculink/Thunderbolt)
- Docker containers
- Ollama service

---

## Current Configuration Backup

### Before Starting — Document Everything

```bash
# Save driver versions
nvidia-smi --query-gpu=driver_version --format=csv,noheader > ~/driver-backup/nvidia-version.txt
dpkg -l | grep nvidia > ~/driver-backup/nvidia-packages.txt

# Save modprobe configs
sudo cp -r /etc/modprobe.d ~/driver-backup/

# Save udev rules
sudo cp -r /etc/udev/rules.d ~/driver-backup/

# Save systemd services
sudo cp /etc/systemd/system/egpu-bind.service ~/driver-backup/
sudo cp /etc/systemd/system/ollama.service ~/driver-backup/
sudo cp -r /etc/systemd/system/ollama.service.d ~/driver-backup/

# Save GRUB config
sudo cp /etc/default/grub ~/driver-backup/

# Save kernel parameters
cat /proc/cmdline > ~/driver-backup/cmdline.txt
```

### Current Driver State (2026-09-11)

| Component | Version/Path |
|-----------|--------------|
| NVIDIA Driver | 580.173.02 |
| CUDA | 13.0 |
| Kernel | 7.0.0-31-generic |
| DKMS | nvidia/580.173.02 installed |
| modprobe config | `/etc/modprobe.d/nvidia-egpu.conf` |
| udev rules | `/etc/udev/rules.d/99-egpu-power.rules` |
| eGPU bind | `/usr/local/sbin/egpu-bind.sh` |

---

## Method 1: Minimal Conversion (Recommended)

Remove only the GUI, keep all drivers and base system intact.

### Step 1: Disable Desktop Environment

```bash
# Set default to multi-user (no GUI)
sudo systemctl set-default multi-user.target

# Disable display manager
sudo systemctl disable gdm3
sudo systemctl stop gdm3
```

### Step 2: Remove Desktop Packages

```bash
# Remove GNOME desktop (but NOT nvidia packages)
sudo apt remove --purge \
  ubuntu-desktop \
  ubuntu-desktop-minimal \
  gnome-shell \
  gnome-session \
  gnome-control-center \
  nautilus \
  gdm3 \
  gnome-terminal

# Remove orphaned packages
sudo apt autoremove --purge
```

### Step 3: Install Server Essentials

```bash
# Install server tools
sudo apt install \
  openssh-server \
  tmux \
  htop \
  iotop \
  net-tools \
  curl \
  wget \
  vim \
  git
```

### Step 4: Configure SSH

```bash
# Enable SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# Verify access from another machine before rebooting!
ssh bryanwills@ai-nuc
```

### Step 5: Reboot and Verify

```bash
# Reboot
sudo reboot

# After reboot, verify:
nvidia-smi
systemctl status ollama
docker ps
```

---

## Method 2: Full Server Meta-package

**⚠️ More invasive — only if Method 1 doesn't meet needs**

```bash
# Install server meta-package
sudo apt install ubuntu-server-minimal

# This pulls in server defaults and may reconfigure some services
```

---

## Post-Conversion Checklist

### Verify Drivers
```bash
# NVIDIA
nvidia-smi
lsmod | grep nvidia

# eGPU bind service
systemctl status egpu-bind

# Kernel modules
cat /etc/modprobe.d/nvidia-egpu.conf
```

### Verify Services
```bash
# Ollama
systemctl status ollama
ollama list

# Docker
systemctl status docker
docker ps -a

# SSH
systemctl status ssh
```

### Verify Networking
```bash
# IP addresses
ip addr

# Tailscale (if installed)
tailscale status

# UFW firewall
sudo ufw status
```

---

## Troubleshooting

### NVIDIA Driver Missing After Reboot

```bash
# Check if nvidia module exists
lsmod | grep nvidia

# If missing, load manually
sudo modprobe nvidia NVreg_EnableGpuFirmware=0

# Check DKMS
dkms status

# Rebuild if needed
sudo dkms autoinstall
```

### Can't SSH After Conversion

Boot into recovery mode:
1. Hold Shift during boot
2. Select recovery mode
3. Drop to root shell
4. Check: `systemctl status ssh`
5. Fix: `systemctl enable ssh && systemctl start ssh`

### GUI Won't Start (if you want it back)

```bash
# Re-enable GUI
sudo systemctl set-default graphical.target
sudo systemctl start gdm3
```

---

## Rollback Plan

If things go wrong, reinstall desktop:

```bash
sudo apt install ubuntu-desktop
sudo systemctl set-default graphical.target
sudo reboot
```

---

## Why Not Fresh Server Install?

A fresh Ubuntu Server install would require:
1. Reinstalling NVIDIA 580.173.02 driver
2. Rebuilding DKMS for the kernel
3. Recreating all eGPU configuration
4. Recreating Ollama setup
5. Recreating Docker containers

The conversion approach preserves all existing configuration.

---

## Related Documentation

- [`eGPU/oculink-thunderbolt-setup.md`](./eGPU/oculink-thunderbolt-setup.md)
- [`stacks/ai-nuc-stacks-setup.md`](./stacks/ai-nuc-stacks-setup.md)
- [`cursor-local-ollama-setup.md`](./cursor-local-ollama-setup.md)

---

*Last updated: 2026-09-11*
