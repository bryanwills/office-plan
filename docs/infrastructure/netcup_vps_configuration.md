System information:

   IP address:     152.53.82.233
                   2a0a:4cc0:2000:35fa:745a:95ff:fe14:6203
   Hostname:       v2202608401004503315.goodsrv.de

 SSH key fingerprints:

   3072 SHA256:HeHIq4xuzijRgCFfweawecWG3mCFAYKEpG3fObMRFDA (RSA)
   256 SHA256:36wo4rYdq+fM+KMx3wiEIFyLLhdP/kCJXY+YH3Em3UM (ECDSA)
   256 SHA256:eIvu/tQgTjsX0IIPqiDGrN9+KQ075U+wklOiy7JCaic (ED25519)
   3072 MD5:2d:9a:54:1c:b9:6c:96:35:6d:64:81:f4:46:9c:4c:96 (RSA)
   256 MD5:26:72:1b:09:f4:4c:64:02:8b:32:82:f2:2e:76:15:19 (ECDSA)
   256 MD5:2c:15:53:ad:ed:41:d5:be:5e:fb:4f:99:a2:74:8a:a5 (ED25519)



❯ ssh bryan@152.53.82.233
The authenticity of host '152.53.82.233 (152.53.82.233)' can't be established.
ED25519 key fingerprint is: SHA256:eIvu/tQgTjsX0IIPqiDGrN9+KQ075U+wklOiy7JCaic
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '152.53.82.233' (ED25519) to the list of known hosts.
bryan@152.53.82.233's password:
Welcome to Ubuntu 26.04 LTS (GNU/Linux 7.0.0-30-generic x86_64)

 * Documentation:  https://docs.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Fri Aug 21 05:04:31 AM CEST 2026

  System load:           0.1
  Usage of /:            0.2% of 1.97TB
  Memory usage:          0%
  Swap usage:            0%
  Processes:             294
  Users logged in:       0
  IPv4 address for eth0: 152.53.82.233
  IPv6 address for eth0: 2a0a:4cc0:2000:35fa:745a:95ff:fe14:6203

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

bryan@v2202608401004503315:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            13G  1.1M   13G   1% /run
/dev/vda3       2.0T  3.4G  1.9T   1% /
tmpfs            32G     0   32G   0% /dev/shm
efivarfs        256K   29K  223K  12% /sys/firmware/efi/efivars
tmpfs            32G     0   32G   0% /tmp
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
/dev/vda2       975M  178M  746M  20% /boot
/dev/vda1       253M  6.3M  246M   3% /boot/efi
none            1.0M     0  1.0M   0% /run/credentials/systemd-networkd.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs           6.3G  8.0K  6.3G   1% /run/user/1000

bryan@v2202608401004503315:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sr0     11:0    1 1024M  1 rom
vda    253:0    0    2T  0 disk
├─vda1 253:1    0  256M  0 part /boot/efi
├─vda2 253:2    0    1G  0 part /boot
└─vda3 253:3    0    2T  0 part /
bryan@v2202608401004503315:~$ sudo apt update
[sudo: authenticate] Password:
Hit:1 http://security.ubuntu.com/ubuntu resolute-security InRelease
Hit:2 http://at.archive.ubuntu.com/ubuntu resolute InRelease
Hit:3 http://at.archive.ubuntu.com/ubuntu resolute-updates InRelease
Hit:4 http://at.archive.ubuntu.com/ubuntu resolute-backports InRelease
Get:5 https://pkgs.tailscale.com/stable/ubuntu resolute InRelease
Fetched 6,652 B in 1s (9,495 B/s)
10 packages can be upgraded. Run 'apt list --upgradable' to see them.
bryan@v2202608401004503315:~$ sudo apt upgrade -y
Not upgrading yet due to phasing:
  gir1.2-packagekitglib-1.0  packagekit                   snapd                       ubuntu-kernel-accessories  ubuntu-server
  libpackagekit-glib2-18     python3-software-properties  software-properties-common  ubuntu-minimal             ubuntu-server-minimal

Summary:
  Upgrading: 0, Installing: 0, Removing: 0, Not Upgrading: 10
bryan@v2202608401004503315:~$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp (OpenSSH)           ALLOW IN    Anywhere
22/tcp (OpenSSH (v6))      ALLOW IN    Anywhere (v6)

bryan@v2202608401004503315:~$ tailscale up
Access denied: checkprefs access denied

Use 'sudo tailscale up'.
To not require root, use 'sudo tailscale set --operator=$USER' once.
bryan@v2202608401004503315:~$ sudo tailscale up

To authenticate, visit:

        https://login.tailscale.com/a/fc856ea0191a2


To approve your machine, visit (as admin):

        https://login.tailscale.com/admin

Success.
Some peers are advertising routes but --accept-routes is false
