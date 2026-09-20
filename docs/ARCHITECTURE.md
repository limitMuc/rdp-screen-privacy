# Architecture

`rdp-screen-privacy` intentionally avoids touching GNOME's logical monitor layout. The daemon only watches the network state of the user-level GNOME Remote Desktop server and controls physical monitor power through DDC/CI.

## State machine

```text
                 RDP established
      +----------------------------------+
      |                                  v
+-------------+                    +-------------+
| DISCONNECTED|                    |  CONNECTED  |
+-------------+                    +-------------+
      ^                                  |
      |                                  | TCP session disappears
      |                                  v
      |                           +----------------+
      |                           | RECONNECT WAIT |
      |                           +----------------+
      |                              |          |
      |                    reconnect |          | timeout
      |                              |          v
      |                              |     lock GNOME
      |                              |          |
      |                              |      monitors ON
      |                              |          |
      +------------------------------+----------+
```

On transition to `CONNECTED`, the daemon sends monitor OFF commands several times because RDP negotiation, GPU modesetting or compositor activity can wake some displays immediately after the first command.

## RDP port discovery

GNOME supports multiple remote-desktop modes. A system-wide Remote Login daemon may own TCP 3389 while the desktop user's ordinary Desktop Sharing daemon listens on another port such as 3390.

The daemon:

1. determines the active graphical user,
2. finds that user's `gnome-remote-desktop-daemon`,
3. prefers the process in `gnome-remote-desktop.service`,
4. maps its PID to the TCP listener with `ss`, and
5. watches established connections whose local source port is that listener.

This avoids hard-coding 3389/3390 and avoids triggering on the system `--system` Remote Login daemon.

## Monitor discovery and cache

With `MONITOR_BUSES="auto"`:

1. `ddcutil detect` identifies `/dev/i2c-N` buses,
2. bus numbers are saved to `/run/rdp-screen-privacy/buses`,
3. OFF commands use the current detected buses,
4. ON commands can fall back to the cache if a powered-down monitor no longer appears in discovery.

The cache is under `/run`, so it does not survive reboot and cannot permanently pin stale I2C bus numbers after hardware changes.

## Disconnect ordering

The disconnect path is deliberately:

1. wait for reconnect debounce,
2. lock the graphical session,
3. wait for the lock screen to settle,
4. power the physical displays on.

The security property is ordering, not monitor power control: the local GNOME session should already be locked before the displays become visible again.
