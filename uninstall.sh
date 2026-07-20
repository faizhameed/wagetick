#!/usr/bin/env bash
# Remove WageTick from /Applications (or WAGETICK_INSTALL_DIR)
set -euo pipefail

APP_NAME="WageTick"
INSTALL_DIR="${WAGETICK_INSTALL_DIR:-/Applications}"
DEST="${INSTALL_DIR}/${APP_NAME}.app"

if [[ -t 1 ]]; then
  C_GREEN=$'\033[1;32m'; C_RED=$'\033[1;31m'; C_RESET=$'\033[0m'
else
  C_GREEN=""; C_RED=""; C_RESET=""
fi

if [[ ! -d "${DEST}" ]]; then
  printf "%s✗%s  %s is not installed at %s\n" "$C_RED" "$C_RESET" "$APP_NAME" "$DEST"
  exit 1
fi

# Quit if running
osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
sleep 0.4

rm -rf "${DEST}"
printf "%s✓%s  Removed %s\n" "$C_GREEN" "$C_RESET" "$DEST"
