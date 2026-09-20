# rdp-screen-privacy

Keep physical monitors dark while remotely controlling the **same GNOME desktop session** over RDP, then lock the local session before turning the monitors back on when the remote connection ends.

This project is for users who prefer GNOME **Desktop Sharing / remote assistance** instead of a separate Remote Login session, but do not want their physical monitors mirroring every remote action.

## Why does this exist?

Ubuntu's GNOME Remote Desktop is good at sharing an existing desktop session, but it does not provide a dependable built-in privacy workflow that turns off the physical monitor when an RDP session starts and locks the local session before the monitor comes back on when the session ends. In practice, Desktop Sharing, Wayland/GNOME display handling and monitor power control are separate layers, and their behavior is not consistently coordinated across Ubuntu versions, display drivers, docks and monitors.

That creates a simple but real workplace problem: you connect remotely and start working, then forget to turn off the office monitor. People nearby can see the same desktop, windows and work activity that you are viewing remotely. This project bridges those layers with a small systemd service: it detects the existing GNOME Desktop Sharing connection, powers off compatible physical monitors through DDC/CI, and locks the GNOME session before turning the monitors back on after a confirmed disconnect.

It is intended as a practical privacy convenience for remote work, not as a replacement for GNOME's authentication, session locking or physical security controls.

> [!IMPORTANT]
> This is a **local privacy helper**, not an access-control boundary. Anyone with physical access may still be able to power a monitor back on. The GNOME session lock remains the real security boundary.

## What it does

```text
RDP Desktop Sharing connection established
                │
                ▼
      detect physical DDC monitors
                │
                ▼
     send VCP D6 power-off commands
       (with configurable retries)
                │
                ▼
 physical monitors dark, same GNOME session stays alive

RDP connection ends
                │
                ▼
       wait for reconnect debounce
                │
                ▼
          lock GNOME session
                │
                ▼
       turn physical monitors on
                │
                ▼
       local screen shows lock screen
```

The daemon does **not** disable GNOME displays or change the logical display layout. It controls the monitor panel through DDC/CI, so the RDP session can continue streaming the existing desktop.

## Features

- Watches the existing GNOME Desktop Sharing RDP session.
- Automatically detects the **user-level** GNOME Remote Desktop listener, including cases where Desktop Sharing moves from `3389` to `3390` because Remote Login already owns `3389`.
- Automatically detects DDC/CI monitor I2C buses and caches them under `/run` so monitors can still be woken even if they stop responding to discovery while powered down.
- Re-sends monitor-off commands after connection because some displays are re-woken during RDP / display negotiation.
- Debounces short disconnect/reconnect events to avoid flashing the local monitors.
- Locks the GNOME session **before** turning monitors back on after a confirmed disconnect.
- Optional periodic OFF enforcement for displays that wake during long sessions.
- Provides systemd service, installer, uninstaller, diagnostics and preflight checks.
- Includes an optional GNOME Shell extension under `extension/` for showing service state in the panel.
- Does not open firewall ports or configure RDP credentials.

## Reference environment

The project was designed around this working setup:

- Ubuntu 26.04
- GNOME Shell 50 / Wayland
- GNOME Remote Desktop Desktop Sharing
- Desktop Sharing on port `3390` while system Remote Login occupies `3389`
- Dell E2421HN and Dell E2420H external monitors
- `ddcutil` / MCCS VCP D6 power control

It should also work on other systemd-based Linux distributions with GNOME Remote Desktop and DDC/CI-capable external monitors. Hardware behavior varies, so test OFF/ON locally before depending on it remotely.

## Why Desktop Sharing instead of Remote Login?

GNOME Remote Desktop has different operating modes. Remote assistance / Desktop Sharing controls an already active desktop session; Remote Login is a system-wide remote login flow. GNOME documents these separately:

https://github.com/GNOME/gnome-remote-desktop/blob/main/docs/configuration.md

This project intentionally targets **Desktop Sharing** because it preserves your already-running browser tabs, IDEs, terminals, window positions and application state.

## Requirements

Required:

- Linux with `systemd`
- GNOME Desktop + GNOME Remote Desktop
- RDP Desktop Sharing enabled
- `ddcutil`
- External monitors that support DDC/CI and VCP feature `D6`
- `iproute2` (`ss`)
- `systemd-logind` (`loginctl`)

Optional but important for some workflows:

- **Allow Locked Remote Desktop** GNOME Shell extension if you want Desktop Sharing to remain reachable after the local session is locked.

  https://extensions.gnome.org/extension/4338/allow-locked-remote-desktop/

  Upstream source:

  https://github.com/jikamens/allow-locked-remote-desktop/

  Extension UUID:

  ```text
  allowlockedremotedesktop@kamens.us
  ```

GNOME's normal remote-assistance behavior closes remote access when the screen is locked, so review the extension's security implications before enabling it.

## Quick start

For the complete handoff, real-machine test plan and release checklist, see
[HANDOFF.md](HANDOFF.md).

The optional GNOME panel extension is packaged separately from the backend:

```bash
make extension-pack
systemctl --user daemon-reload
systemctl --user enable --now rdp-screen-privacy-agent.service
gnome-extensions install rdp-screen-privacy@limitMuc.shell-extension.zip
gnome-extensions enable rdp-screen-privacy@limitMuc
```

The extension metadata points to the `limitMuc/rdp-screen-privacy` repository.

### 1. Enable DDC/CI in monitor settings

Many external monitors have a DDC/CI toggle in their on-screen menu. Enable it first.

### 2. Verify your monitors

```bash
sudo ddcutil detect
```

Check VCP D6 on each monitor, for example:

```bash
sudo ddcutil --bus 8 getvcp D6
sudo ddcutil --bus 8 capabilities | grep -A4 -i 'Feature: D6'
```

A typical monitor may advertise:

```text
01: DPM: On
04: DPM: Off
05: Write only value to turn off display
```

The project defaults to `04` because it is usually more recoverable than the write-only `05` mode.

### 3. Test OFF and ON while physically present

```bash
sudo ddcutil --bus 8 setvcp D6 04
sleep 5
sudo ddcutil --bus 8 setvcp D6 01
```

Do this for every display before installing the daemon.

### 4. Run the preflight check

```bash
./scripts/preflight.sh
```

### 5. Install

Ubuntu / Debian example:

```bash
git clone https://github.com/limitMuc/rdp-screen-privacy.git
cd rdp-screen-privacy
sudo ./install.sh --install-deps --user "$USER"
```

The installer creates:

```text
/usr/local/sbin/rdp-screen-privacy
/etc/rdp-screen-privacy.conf
/etc/systemd/system/rdp-screen-privacy.service
```

Then it enables the service.

### 6. Diagnose

```bash
sudo rdp-screen-privacy diagnose
```

### 7. Watch logs during your first test

```bash
sudo journalctl -u rdp-screen-privacy -f
```

Connect to your GNOME **Desktop Sharing** RDP endpoint. The monitors should turn off automatically. Disconnect; after the debounce period, the local GNOME session should lock and the monitors should turn back on.

## Configuration

Edit:

```bash
sudo editor /etc/rdp-screen-privacy.conf
```

The most useful settings are:

```bash
# Active GNOME user. Empty = auto-detect seat0 graphical user.
DESKTOP_USER=""

# Auto-detect the user-level GNOME Desktop Sharing listener.
RDP_PORT="auto"

# Auto-detect all DDC/CI displays. You may instead use e.g. "8 13".
MONITOR_BUSES="auto"

# Avoid reacting to brief RDP reconnects.
DISCONNECT_DELAY=5

# Initial OFF + two retries after 2s and 3s.
OFF_RETRY_DELAYS="0 2 3"

# Wake retry sequence.
ON_RETRY_DELAYS="0 2"

# 0 = disabled. Set e.g. 30 if a display wakes during long RDP sessions.
KEEP_OFF_INTERVAL=0

DDC_OFF_VALUE="04"
DDC_ON_VALUE="01"

LOCK_ON_DISCONNECT=true
TURN_ON_AFTER_DISCONNECT=true
LOCK_ON_SERVICE_STOP=true
TURN_ON_ON_SERVICE_STOP=true
```

Restart after changes:

```bash
sudo systemctl restart rdp-screen-privacy
```

## Command reference

```bash
sudo rdp-screen-privacy diagnose
sudo rdp-screen-privacy port
sudo rdp-screen-privacy buses
sudo rdp-screen-privacy off
sudo rdp-screen-privacy on
sudo rdp-screen-privacy lock
```

Service commands:

```bash
sudo systemctl status rdp-screen-privacy
sudo systemctl restart rdp-screen-privacy
sudo journalctl -u rdp-screen-privacy -f
```

## When Remote Login and Desktop Sharing are both enabled

A common setup is:

```text
3389 -> system GNOME Remote Desktop -> Remote Login
3390 -> user GNOME Remote Desktop   -> Desktop Sharing
```

Do not assume the port. Keep:

```bash
RDP_PORT="auto"
```

The daemon finds the listener belonging to the desktop user's `gnome-remote-desktop-daemon`, rather than the system-wide `--system` daemon.

You can inspect both manually:

```bash
sudo ss -lntp | grep -E ':(3389|3390)\b'
```

## Monitor bus changes after reboot

I2C bus numbers can change after driver or hardware changes. With:

```bash
MONITOR_BUSES="auto"
```

the project re-discovers the monitors and caches the current buses in:

```text
/run/rdp-screen-privacy/buses
```

Because `/run` is temporary, stale bus numbers do not persist across reboots.

## Safety behavior

The order after an RDP disconnect is intentional:

```text
connection disappears
        ↓
wait for reconnect window
        ↓
lock GNOME session
        ↓
wait for lock screen to settle
        ↓
turn physical displays on
```

This avoids briefly exposing an unlocked desktop on the physical monitors.

The same fail-safe behavior is used when the service is stopped or restarted, unless disabled in the configuration.

## Limitations

- DDC/CI support is monitor-, cable-, dock- and GPU-dependent.
- Laptop internal panels usually cannot be controlled with `ddcutil` the same way as external monitors.
- Some monitors stop responding to DDC in specific power modes. Always test local recovery first.
- Physical users can still press the monitor power button or change inputs.
- This project does not hide the existence of an RDP session from the operating system or network.
- This project does not bypass GNOME authentication, screen locking, endpoint management, firewall or company security policy.
- GNOME behavior can change between releases; open an issue with `sudo rdp-screen-privacy diagnose` output when reporting compatibility problems.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

Quick checks:

```bash
sudo rdp-screen-privacy diagnose
sudo ddcutil detect
sudo journalctl -u rdp-screen-privacy -n 100 --no-pager
```

## Uninstall

Keep configuration:

```bash
sudo ./uninstall.sh
```

Remove configuration too:

```bash
sudo ./uninstall.sh --purge-config
```

`ddcutil` is intentionally left installed.

## Development

Syntax checks:

```bash
make check
```

ShellCheck:

```bash
make shellcheck
```


## License

Licensed under the **MIT License**.

MIT is a permissive open-source license that allows personal and commercial use, modification, redistribution, and sublicensing, subject to preserving the copyright and license notice.

See [LICENSE](LICENSE).
