#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DEPS=false
TARGET_USER="${SUDO_USER:-${USER:-}}"
ENABLE_NOW=true

usage() {
    cat <<'EOF_USAGE'
Usage: sudo ./install.sh [options]

Options:
  --install-deps       Install ddcutil using the detected package manager
  --user USER          Desktop user to write into the initial config
  --no-start           Install files but do not enable/start the service
  -h, --help           Show this help
EOF_USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install-deps) INSTALL_DEPS=true ;;
        --user) shift; TARGET_USER="${1:-}" ;;
        --no-start) ENABLE_NOW=false ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ $EUID -ne 0 ]]; then
    echo "Run this installer as root, e.g. sudo ./install.sh" >&2
    exit 1
fi

command -v systemctl >/dev/null 2>&1 || {
    echo "systemd is required." >&2
    exit 1
}

install_deps() {
    if command -v ddcutil >/dev/null 2>&1; then
        return 0
    fi

    if [[ "$INSTALL_DEPS" != true ]]; then
        cat >&2 <<'EOF_MSG'
ddcutil is not installed.
Re-run with --install-deps, or install ddcutil with your distribution's package manager.
EOF_MSG
        exit 1
    fi

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y ddcutil
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ddcutil
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --needed --noconfirm ddcutil
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install ddcutil
    else
        echo "Could not detect a supported package manager. Install ddcutil manually." >&2
        exit 1
    fi
}

install_deps

install -Dm0755 "$ROOT_DIR/src/rdp-screen-privacy" /usr/local/sbin/rdp-screen-privacy
install -Dm0644 "$ROOT_DIR/systemd/rdp-screen-privacy.service" /etc/systemd/system/rdp-screen-privacy.service

if [[ ! -e /etc/rdp-screen-privacy.conf ]]; then
    install -Dm0644 "$ROOT_DIR/config/rdp-screen-privacy.conf.example" /etc/rdp-screen-privacy.conf

    if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]] && id "$TARGET_USER" >/dev/null 2>&1; then
        sed -i "s/^DESKTOP_USER=.*/DESKTOP_USER=\"$TARGET_USER\"/" /etc/rdp-screen-privacy.conf
    fi
    echo "Created /etc/rdp-screen-privacy.conf"
else
    echo "Preserving existing /etc/rdp-screen-privacy.conf"
fi

systemctl daemon-reload

if [[ "$ENABLE_NOW" == true ]]; then
    systemctl enable --now rdp-screen-privacy.service
    echo
    systemctl --no-pager --full status rdp-screen-privacy.service || true
else
    echo "Installed without starting. Enable later with:"
    echo "  sudo systemctl enable --now rdp-screen-privacy.service"
fi

cat <<'EOF_DONE'

Installed rdp-screen-privacy.

Recommended next steps:
  sudo rdp-screen-privacy diagnose
  sudo journalctl -u rdp-screen-privacy -f

If auto-detection is unsuitable, edit:
  sudo editor /etc/rdp-screen-privacy.conf
EOF_DONE
