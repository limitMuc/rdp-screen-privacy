# Security notes

`rdp-screen-privacy` is a local privacy helper, not an access-control system.

- Turning a monitor off through DDC/CI does **not** prevent someone with physical access from powering the monitor back on.
- The daemon locks the GNOME session before turning monitors back on after an RDP disconnect, but it cannot protect against failures outside the operating system, firmware, or display hardware.
- The service runs as root because DDC/CI access commonly requires `/dev/i2c-*` access and because it must reliably lock the local graphical session.
- The project does not open firewall ports, configure RDP credentials, expose RDP to the Internet, or bypass network policy.
- Use GNOME Remote Desktop only over a trusted network, VPN, or other approved secure path.
- If using the third-party **Allow Locked Remote Desktop** extension, understand that it intentionally changes GNOME's default behavior around locked sessions.

## Reporting a vulnerability

Please open a private security advisory in the GitHub repository rather than filing a public issue containing sensitive details.
