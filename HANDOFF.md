# Handoff

Repository: https://github.com/limitMuc/rdp-screen-privacy

The project now contains a GNOME Shell extension, a user-session D-Bus Agent,
and the existing root systemd backend. The extension shows status and exposes
manual OFF, ON and LOCK actions. The backend detects RDP, controls DDC/CI,
debounces disconnects, locks GNOME, and restores monitors. Backend code is MIT;
extension and Agent code are GPL-2.0-or-later.

## Not yet completed

- GNOME Shell/gjs was unavailable during development, so the extension and
  Agent have not been run on real Ubuntu hardware.
- `pkexec` authorization and extension menu actions are untested.
- GNOME Shell 45-50 compatibility is declared but not fully verified.
- Add a GPL license file inside `extension/` before GNOME Extensions upload.
- GitHub Actions CI was intentionally removed; checks are manual.

## Next-machine checklist

1. Clone `https://github.com/limitMuc/rdp-screen-privacy.git` and run `make check`.
2. Run `make shellcheck` if ShellCheck is installed.
3. Enable DDC/CI in each monitor's OSD menu.
4. Run `sudo ddcutil detect`.
5. Test `sudo ddcutil --bus BUS getvcp D6`, then values `04` and `01` while
   physically present. Do not use value `05` without testing recovery.
6. Install with `sudo ./install.sh` (or `--install-deps` if needed).
7. Run `sudo rdp-screen-privacy diagnose` and inspect
   `/etc/rdp-screen-privacy.conf`.
8. Test `sudo rdp-screen-privacy off`, `on` and `lock` locally.
9. Watch `sudo journalctl -u rdp-screen-privacy.service -f` while connecting
   through RDP. Confirm monitors turn off and the same desktop remains usable.
10. Disconnect, wait longer than `DISCONNECT_DELAY`, and confirm GNOME locks
    before monitors turn on. Test a short reconnect during the debounce window.
11. As the graphical user, run `systemctl --user daemon-reload` and
    `systemctl --user enable --now rdp-screen-privacy-agent.service`.
12. Verify D-Bus with `gdbus introspect --session --dest
    com.example.RdpScreenPrivacy --object-path /com/example/RdpScreenPrivacy`.
13. Confirm the output contains `GetState`, `TurnOff`, `TurnOn` and `Lock`.
14. Run `make extension-pack`, then install and enable
    `rdp-screen-privacy@limitMuc` with `gnome-extensions`.
15. Test status display, all menu actions, Agent stop/start, extension
    disable/re-enable, logout/login and lock/unlock.

## Failure evidence

Collect `sudo journalctl -u rdp-screen-privacy.service -n 200 --no-pager`,
`sudo rdp-screen-privacy diagnose`, `sudo rdp-screen-privacy port`, and
`sudo rdp-screen-privacy buses`. For Shell errors use
`journalctl --user -b -u org.gnome.Shell -n 200 --no-pager`. For polkit issues,
test `pkexec /usr/local/sbin/rdp-screen-privacy off|on|lock` separately.

## Before publishing the extension

Add GPL-2.0-or-later license text to `extension/`; keep UUID
`rdp-screen-privacy@limitMuc`; narrow `shell-version` if necessary; upload only
the extension archive; explain that the backend and Agent are installed
separately; and confirm enable/disable cleanup. Do not upload the whole GitHub
repository as the extension archive.

## Release

After real-machine testing: run `make check`, review `git status`, then
`git add .`, `git commit -m "Add GNOME extension integration"`, and
`git push origin main`. Tag only after testing passes:
`git tag -a v0.2.0 -m "Add GNOME extension integration"` followed by
`git push origin v0.2.0`.
