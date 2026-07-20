#!/usr/bin/env bash
# Capture docs/screenshot.png with elapsed time 01:20:45 (1h 20m 45s).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${ROOT}/build-test"
OUT="${ROOT}/docs/screenshot.png"

# 1*3600 + 20*60 + 45 = 4845 seconds
MS=$(( (1 * 3600 + 20 * 60 + 45) * 1000 ))

if [[ ! -x "${BUILD}/WageTick.app/Contents/MacOS/WageTick" ]]; then
  cmake -S "${ROOT}" -B "${BUILD}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
  cmake --build "${BUILD}" -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
fi

mkdir -p "$(dirname "${OUT}")"
export WAGETICK_SCREENSHOT_ELAPSED_MS="${MS}"
export WAGETICK_SAVE_SCREENSHOT="${OUT}"
"${BUILD}/WageTick.app/Contents/MacOS/WageTick"
echo "Wrote ${OUT} (elapsed 01:20:45)"
