#!/usr/bin/env bash
# Rebuild resources/AppIcon.icns from resources/AppIcon-1024.png
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MASTER="${ROOT}/resources/AppIcon-1024.png"
ICONSET="${ROOT}/resources/AppIcon.iconset"
ICNS="${ROOT}/resources/AppIcon.icns"

[[ -f "${MASTER}" ]] || { echo "Missing ${MASTER}"; exit 1; }

rm -rf "${ICONSET}"
mkdir -p "${ICONSET}"

make_size() {
  sips -z "$1" "$1" "${MASTER}" --out "${ICONSET}/$2" >/dev/null
}

make_size 16   icon_16x16.png
make_size 32   diana.k@example.org
make_size 32   icon_32x32.png
make_size 64   ivan.p@example.net
make_size 128  icon_128x128.png
make_size 256  wendy.h@example.net
make_size 256  icon_256x256.png
make_size 512  wendy.h@example.net
make_size 512  icon_512x512.png
make_size 1024 walt.e@example.net

iconutil -c icns "${ICONSET}" -o "${ICNS}"
rm -rf "${ICONSET}"
echo "Wrote ${ICNS}"
