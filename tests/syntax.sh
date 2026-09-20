#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT/src/rdp-screen-privacy"
bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"
bash -n "$ROOT/scripts/preflight.sh"
bash -n "$ROOT/scripts/show-rdp-connections.sh"

echo "bash syntax checks passed"
