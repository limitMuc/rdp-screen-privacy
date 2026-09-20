#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

failures=0

ok()   { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; failures=$((failures + 1)); }

command -v systemctl >/dev/null 2>&1 && ok "systemd available" || fail "systemd not found"
command -v ddcutil >/dev/null 2>&1 && ok "ddcutil available" || fail "ddcutil not found"
command -v loginctl >/dev/null 2>&1 && ok "loginctl available" || fail "loginctl not found"
command -v ss >/dev/null 2>&1 && ok "ss available" || fail "ss not found"
command -v gnome-shell >/dev/null 2>&1 && ok "GNOME Shell: $(gnome-shell --version 2>/dev/null)" || warn "GNOME Shell command not found"
command -v grdctl >/dev/null 2>&1 && ok "grdctl available" || warn "grdctl not found"

if command -v ddcutil >/dev/null 2>&1; then
    buses="$(sudo ddcutil detect 2>/dev/null | sed -n 's#.*I2C bus:[[:space:]]*/dev/i2c-\([0-9][0-9]*\).*#\1#p' | xargs 2>/dev/null || true)"
    [[ -n "$buses" ]] && ok "DDC/CI buses: $buses" || fail "No DDC/CI displays detected"
fi

if command -v grdctl >/dev/null 2>&1; then
    if grdctl status 2>/dev/null | grep -q 'Status: enabled'; then
        ok "GNOME Desktop Sharing reports enabled"
    else
        warn "GNOME Desktop Sharing does not report enabled"
    fi
fi

if (( failures > 0 )); then
    echo
    echo "$failures required check(s) failed."
    exit 1
fi

echo
echo "Preflight checks passed."
