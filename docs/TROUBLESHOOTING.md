# Troubleshooting

## RDP connects, but the screens do not turn off

Check that the watcher sees the Desktop Sharing connection:

```bash
sudo rdp-screen-privacy port
sudo ss -Htn state established '( sport = :3390 )'
sudo journalctl -u rdp-screen-privacy -f
```

If your Desktop Sharing port is not `3390`, either keep `RDP_PORT="auto"` or set the actual port in `/etc/rdp-screen-privacy.conf`.

## Only one monitor turns off

First verify DDC/CI detection:

```bash
sudo ddcutil detect
sudo rdp-screen-privacy buses
```

Then test each bus manually:

```bash
sudo ddcutil --bus 8 getvcp D6
sudo ddcutil --bus 8 setvcp D6 04
sudo ddcutil --bus 8 setvcp D6 01
```

If a monitor wakes during RDP setup, the daemon already retries OFF by default. You can make it more aggressive:

```bash
OFF_RETRY_DELAYS="0 2 3 5"
KEEP_OFF_INTERVAL=30
```

Restart after editing the config:

```bash
sudo systemctl restart rdp-screen-privacy
```

## A monitor cannot be woken remotely

Some displays stop answering DDC after a hard power-off value. The project therefore defaults to VCP D6 value `04`, not the write-only `05` value some monitors expose.

Check the values advertised by your display:

```bash
sudo ddcutil --bus 8 capabilities | grep -A4 -i 'Feature: D6'
```

Test OFF/ON while physically present before relying on remote recovery.

## Desktop Sharing moved from 3389 to 3390

GNOME Remote Login and Desktop Sharing are separate modes. When Remote Login uses system port 3389, Desktop Sharing may negotiate another port such as 3390. `RDP_PORT="auto"` discovers the user-level GNOME Remote Desktop listener and avoids hard-coding this.

See GNOME Remote Desktop configuration documentation:

https://github.com/GNOME/gnome-remote-desktop/blob/main/docs/configuration.md

## Reconnect fails after the daemon locks the GNOME session

GNOME's normal remote-assistance mode closes remote desktop access when the screen is locked. If you intentionally want Desktop Sharing to remain reachable while locked, install and enable the third-party GNOME Shell extension **Allow Locked Remote Desktop**:

https://extensions.gnome.org/extension/4338/allow-locked-remote-desktop/

Project homepage:

https://github.com/jikamens/allow-locked-remote-desktop/

Extension UUID:

```text
allowlockedremotedesktop@kamens.us
```

Confirm its state as the desktop user:

```bash
gnome-extensions info allowlockedremotedesktop@kamens.us
```

This extension changes lock-screen remote-access behavior. Review its security implications before enabling it.

## Service sees no graphical session

Run:

```bash
loginctl list-sessions
sudo rdp-screen-privacy diagnose
```

If auto-detection chooses the wrong user, set:

```bash
DESKTOP_USER="your-user"
```

in `/etc/rdp-screen-privacy.conf`.

## DDC bus numbers changed after reboot

Keep:

```bash
MONITOR_BUSES="auto"
```

The daemon discovers buses and caches them under `/run/rdp-screen-privacy/`. The cache is recreated after reboot. If you deliberately use fixed bus numbers, re-run `ddcutil detect` after hardware/driver changes.

## View logs

```bash
sudo journalctl -u rdp-screen-privacy -f
```

Recent logs:

```bash
sudo journalctl -u rdp-screen-privacy -n 100 --no-pager
```
