# Changelog

## 0.1.0 - 2026-09-20

Initial public version.

- Watch GNOME Desktop Sharing RDP connections.
- Automatically detect the user-level GNOME Remote Desktop port.
- Auto-detect and cache DDC/CI monitor buses.
- Turn physical monitors off while RDP is connected.
- Retry DDC power-off to handle displays re-woken during RDP negotiation.
- Debounce transient RDP disconnects.
- Lock the local graphical session before turning displays back on.
- Provide installer, uninstaller, diagnostics and systemd unit.
