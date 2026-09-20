# Compatibility

## Reference setup

The initial implementation was developed around:

| Component | Reference |
|---|---|
| OS | Ubuntu 26.04 |
| Desktop | GNOME Shell 50 |
| Session | Wayland |
| RDP server | GNOME Remote Desktop Desktop Sharing |
| Remote Login | Enabled separately on system port 3389 |
| Desktop Sharing | Negotiated to port 3390 |
| Displays | Dell E2421HN, Dell E2420H |
| Display control | DDC/CI, MCCS VCP D6 |

## Expected compatibility

The code is designed to be portable across systemd-based Linux distributions provided these components exist:

- `systemd` / `systemd-logind`
- GNOME Remote Desktop user service
- `iproute2` (`ss`)
- `ddcutil`
- DDC/CI-capable external monitors

The installer knows how to install `ddcutil` with `apt`, `dnf`, `pacman`, or `zypper`, but non-Ubuntu environments are not claimed as validated until users report them.

## Common hardware caveats

- HDMI and DisplayPort usually expose DDC/CI, but docks/KVMs/adapters may block it.
- Some monitors need DDC/CI enabled in their OSD menu.
- Internal laptop panels are usually not addressable with `ddcutil` in the same way.
- VCP D6 semantics vary. `04` is the default because it is commonly recoverable; test your hardware before changing it to `05`.
- I2C bus numbers may change after reboots or driver/hardware changes; auto mode is recommended.
