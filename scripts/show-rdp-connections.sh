#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

PORT="${1:-3390}"
echo "Listening on :$PORT:"
ss -Hlnpt "( sport = :${PORT} )" || true

echo
echo "Established on :$PORT:"
ss -Htn state established "( sport = :${PORT} )" || true
