# AI-NUC desktop without a monitor, without a reboot

**Date:** 2026-09-19  
**Do not reboot** this box for xrdp. eGPU / dock first.

## What is actually broken

xrdp is already running (`0.0.0.0:3389`, sesman up, `xorgxrdp` installed, `~/.xsession` is `xfce4-session`). The daemon is fine.

ufw still only allows 22, 11434, 3000, 443. **3389 is not in the list.** Microsoft Remote Desktop to `100.73.71.29` or `172.16.1.232` will sit there until it times out. That is not an xrdp failure.

`ssh -T` is “no tty.” It does not forward a port. Last time was **`ssh -L`**.

## From the Mac (now)

```bash
# Tailscale on. Leave this window open.
ssh -N -L 3389:127.0.0.1:3389 bryanwills@100.73.71.29
```

Or: `bash scripts/macbook/tunnel-xrdp.sh`

Open WebUI `:3000` is a different LaunchAgent (`owui-tunnel start` / `stop`), not this window. See [Open WebUI Mac tunnel](openwebui-mac-tunnel.md).

Then Windows App / Microsoft Remote Desktop:

- PC name: `127.0.0.1`
- User: `bryanwills`
- Session: **Xorg** (not Xvnc)

You never opened 3389 on the house WAN.

Optional later, still no reboot, Tailscale-only (run on the NUC):

```bash
sudo ufw allow from 100.64.0.0/10 to any port 3389 proto tcp comment 'xrdp tailscale'
```

Do not allow 3389 from Anywhere. Do not port-forward it on AT&T.

If the RDP window opens then XFCE dies: `sudo apt install -y dbus-x11` (no reboot). GNOME is gone on purpose; stay on XFCE. Do not reinstall `ubuntu-desktop` until you plan a dock-safe reboot.

## You do not need this desktop for Google Drive

Open WebUI is a browser on the Mac:

`http://100.73.71.29:3000`

Keep doing the Google Cloud steps (Web client, Drive + Picker APIs, test user). Paste Client ID + API key into `/opt/stacks/open-webui/.env` on the NUC. XRDP is unrelated.

## JetKVM without a 50 ft trip-hazard

JetKVM is Ethernet. There is no official “wireless JetKVM.” Do not string cable through the house.

Put a **travel router** next to the NUC (1 ft patch cable):

- JetKVM WAN/LAN → GL-iNet Beryl AX (GL-MT3000) or Slate
- Travel router joins `MooseSpencer5.0G` as a Wi-Fi client
- JetKVM gets a LAN IP; optional Tailscale on the GL-iNet

That is KVM over Wi-Fi without a new KVM.

## Second USB Wi-Fi (small dongle, not a desk antenna)

You already have a MediaTek USB radio (`0e8d:c616`) on `wlan0` at `172.16.1.232` (`MooseSpencer5.0G`). Fine for the room.

The second stick (Cudy, Realtek RTL88x2bu `0bda:b812`, MAC `d4:0d:ab:70:02:58`) uses in-kernel `rtw88_8822bu`. Linux names it `wlxd40dab700258` until we pin it:

```bash
sudo bash scripts/ai-nuc/setup-cudy-wifi.sh
```

That writes `/etc/systemd/network/10-wlan1.link`, renames the iface to **`wlan1`**, USB-resets the stick (rtw88 often comes up with USB `-71` and an empty scan), and sets **`172.16.1.233/24`**. It joins the same 5 GHz SSID **`MooseSpencer5.0G`** as `wlan0` (BSSID `28:74:F5:58:16:5C`). 2.4 GHz is not used. It does **not** take the default route (metric 700, `never-default`). No reboot. If the scan is still empty after the reset, unplug the Cudy, wait 10 seconds, and move it to a different rear USB port. If association still times out, this AP is on DFS channel 100; move `MooseSpencer5.0G` to a non-DFS 5 GHz channel (36–48 or 149–165).

For a third backup radio, still prefer **MediaTek MT7921AU**, in-kernel on Ubuntu 24.04, no DKMS, no reboot-to-load:

| Buy | Why |
|---|---|
| Comfast CF-951AX / CF-953AX | Small stick, mt7921au |
| Alfa **AWUS036AXM** | Same chip, compact. Not AWUS036AXML (the tall antenna kit) |
| Any listing that says **MT7921AU** and shows a nano/stick body | Check chipset, not “AX3000” marketing |

Skip Realtek 88x2bu / 8812au (out-of-tree, want a reboot). Skip gamer “USB + mast” kits. Skip Wi-Fi 7 USB until the Ubiquiti APs exist; a Wi-Fi 6 stick will join those APs.

After it arrives: NetworkManager, same SSID or the 2.4 GHz one, higher route metric so it is standby. Ethernet still beats both when you can run a short cable later.
