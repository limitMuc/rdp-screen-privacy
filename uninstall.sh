#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -euo pipefail

PURGE_CONFIG=false

if [[ "${1:-}" == "--purge-config" ]]; then
    PURGE_CONFIG=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: sudo ./uninstall.sh [--purge-config]" >&2
    exit 2
fi

if [[ $EUID -ne 0 ]]; then
    echo "Run as root, e.g. sudo ./uninstall.sh" >&2
    exit 1
fi

systemctl disable --now rdp-screen-privacy.service 2>/dev/null || true
rm -f /etc/systemd/system/rdp-screen-privacy.service
rm -f /usr/local/sbin/rdp-screen-privacy
rm -rf /run/rdp-screen-privacy

if [[ "$PURGE_CONFIG" == true ]]; then
    rm -f /etc/rdp-screen-privacy.conf
    echo "Removed configuration."
else
    echo "Preserved /etc/rdp-screen-privacy.conf"
fi

systemctl daemon-reload
systemctl reset-failed rdp-screen-privacy.service 2>/dev/null || true

echo "rdp-screen-privacy uninstalled. ddcutil was left installed."
