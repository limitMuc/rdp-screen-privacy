# RDP Screen Privacy GNOME Extension

This directory contains the GNOME Shell UI component for `rdp-screen-privacy`.

The privileged screen-control and locking behavior remains outside the
extension. The extension reads state and requests manual actions through the
user-session D-Bus agent; the agent invokes the fixed installed backend through
polkit.

## Local test

The repository is owned by `limitMuc`, so the extension can be packaged with:

```bash
gnome-extensions pack extension
gnome-extensions install rdp-screen-privacy@limitMuc.shell-extension.zip
gnome-extensions enable rdp-screen-privacy@limitMuc
```

The extension requires GNOME Shell 45 or newer. It is licensed under
GPL-2.0-or-later, separately from the MIT-licensed backend.
