#!/usr/bin/env bash
# WageTick installer — Apple Silicon (arm64) macOS
# Clones build dependencies via Homebrew, builds, bundles Qt into the
# .app, and installs it to /Applications/WageTick.app
set -euo pipefail

APP_NAME="WageTick"
BUNDLE_ID="com.wagetick.app"
INSTALL_DIR="${WAGETICK_INSTALL_DIR:-/Applications}"
DEST="${INSTALL_DIR}/${APP_NAME}.app"

# Resolve repo root (directory containing this script)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT}/build-release"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

# ── pretty log helpers ──────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m'; C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
  C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_DIM=""; C_RESET=""
fi

info()  { printf "%s==>%s %s\n" "$C_BLUE" "$C_RESET" "$*"; }
ok()    { printf "%s✓%s  %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf "%s!%s  %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
die()   { printf "%s✗%s  %s\n" "$C_RED" "$C_RESET" "$*" >&2; exit 1; }
step()  { printf "\n%s── %s ──%s\n" "$C_DIM" "$*" "$C_RESET"; }

# ── preflight ───────────────────────────────────────────────────────────────
step "Preflight checks"

[[ "$(uname -s)" == "Darwin" ]] || die "WageTick installer only supports macOS."

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  die "This installer targets Apple Silicon (arm64). Detected: ${ARCH}
       Intel Macs are not supported by this script."
fi
ok "Apple Silicon (${ARCH})"

# Xcode CLT (compiler)
if ! xcode-select -p >/dev/null 2>&1; then
  warn "Xcode Command Line Tools not found — launching installer…"
  xcode-select --install || true
  die "Install the Command Line Tools, then re-run: ./install.sh"
fi
ok "Xcode Command Line Tools"

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  step "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellenv for Apple Silicon default prefix
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
command -v brew >/dev/null 2>&1 || die "Homebrew is required but was not found after install."
# Ensure brew is on PATH in this shell
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"

# ── dependencies ────────────────────────────────────────────────────────────
step "Installing build dependencies"
info "cmake, qtbase, qtdeclarative, qtsvg (via Homebrew — may take a few minutes on first run)"
export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
export HOMEBREW_NO_ENV_HINTS=1
# Show brew output so first-time installs don't look hung
brew install cmake qtbase qtdeclarative qtsvg
ok "Dependencies ready"

# Locate tools
CMAKE="$(command -v cmake)"
MACDEPLOYQT="$(command -v macdeployqt6 || command -v macdeployqt || true)"
[[ -n "$MACDEPLOYQT" ]] || MACDEPLOYQT="$(brew --prefix qtbase 2>/dev/null)/bin/macdeployqt6"
[[ -x "$MACDEPLOYQT" ]] || die "macdeployqt6 not found. Is qtbase installed?"

# ── configure + build ───────────────────────────────────────────────────────
step "Building ${APP_NAME} (Release)"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

"${CMAKE}" -S "${ROOT}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$(brew --prefix)"

"${CMAKE}" --build "${BUILD_DIR}" -j"${JOBS}"
ok "Build complete"

APP_SRC="${BUILD_DIR}/${APP_NAME}.app"
[[ -d "${APP_SRC}" ]] || die "Expected app bundle missing: ${APP_SRC}"

# ── bundle Qt frameworks into the .app ──────────────────────────────────────
step "Bundling Qt into ${APP_NAME}.app (self-contained)"
info "This packages frameworks so the app runs from Applications without extra PATH setup…"

# Homebrew ships modular Qt: plugins live under share/qt/plugins and QML under
# share/qt/qml. Without these hints, macdeployqt6 omits the cocoa platform
# plugin and modules such as QtQuick.Layouts — the installed .app then aborts
# at launch with "Could not find the Qt platform plugin cocoa".
QT_PREFIX="$(brew --prefix)"
QTBASE_PREFIX="$(brew --prefix qtbase)"
QML_IMPORT_PATH="${QT_PREFIX}/share/qt/qml"
if [[ ! -d "${QML_IMPORT_PATH}" ]]; then
  QML_IMPORT_PATH="${QTBASE_PREFIX}/share/qt/qml"
fi
QT_PLUGINS_PATH="${QT_PREFIX}/share/qt/plugins"
if [[ ! -d "${QT_PLUGINS_PATH}" ]]; then
  QT_PLUGINS_PATH="${QTBASE_PREFIX}/share/qt/plugins"
fi
[[ -d "${QML_IMPORT_PATH}" ]] || die "Qt QML import path not found (expected share/qt/qml under Homebrew)."
[[ -d "${QT_PLUGINS_PATH}/platforms" ]] || die "Qt platforms plugins not found under ${QT_PLUGINS_PATH}."

export QT_PLUGIN_PATH="${QT_PLUGINS_PATH}"
export QML2_IMPORT_PATH="${QML_IMPORT_PATH}"

LIBPATHS=(
  -libpath="${QT_PREFIX}/lib"
  -libpath="$(brew --prefix qtsvg)/lib"
  -libpath="${QTBASE_PREFIX}/lib"
  -libpath="$(brew --prefix qtdeclarative)/lib"
)

# macdeployqt may print non-fatal rpath / intermediate codesign noise on Homebrew Qt.
# We always re-sign the full bundle ourselves afterward.
# Capture full log (don't pipe through grep — that can mask a real failure via PIPESTATUS).
DEPLOY_LOG="${BUILD_DIR}/macdeployqt.log"
set +e
"${MACDEPLOYQT}" "${APP_SRC}" \
  -qmldir="${ROOT}/qml" \
  -qmlimport="${QML_IMPORT_PATH}" \
  "${LIBPATHS[@]}" \
  -verbose=1 \
  -no-codesign \
  >"${DEPLOY_LOG}" 2>&1
DEPLOY_RC=$?
set -e
if [[ ${DEPLOY_RC:-0} -ne 0 ]]; then
  # Still continue if frameworks landed — macdeployqt often returns non-zero on rpath noise.
  if [[ ! -d "${APP_SRC}/Contents/Frameworks" ]]; then
    tail -40 "${DEPLOY_LOG}" >&2 || true
    die "macdeployqt failed (exit ${DEPLOY_RC}). See ${DEPLOY_LOG}"
  fi
  warn "macdeployqt exited with code ${DEPLOY_RC} (often non-fatal). Continuing with checks…"
fi

# Sanity: frameworks + cocoa platform plugin (required to open a window)
[[ -d "${APP_SRC}/Contents/Frameworks" ]] || die "Deploy failed — Frameworks folder missing."
if [[ ! -f "${APP_SRC}/Contents/PlugIns/platforms/libqcocoa.dylib" ]]; then
  # Last-resort manual copy if macdeployqt still skipped platforms
  warn "libqcocoa missing after macdeployqt — copying from Homebrew plugins…"
  mkdir -p "${APP_SRC}/Contents/PlugIns/platforms"
  cp "${QT_PLUGINS_PATH}/platforms/libqcocoa.dylib" "${APP_SRC}/Contents/PlugIns/platforms/"
  # Point @rpath deps at the bundled Frameworks folder
  install_name_tool -add_rpath @loader_path/../../Frameworks \
    "${APP_SRC}/Contents/PlugIns/platforms/libqcocoa.dylib" 2>/dev/null || true
fi
[[ -f "${APP_SRC}/Contents/PlugIns/platforms/libqcocoa.dylib" ]] \
  || die "Deploy failed — cocoa platform plugin still missing."

# Ensure QML modules our UI imports are present (Layouts / Effects)
for mod in Layouts Effects; do
  if [[ ! -d "${APP_SRC}/Contents/Resources/qml/QtQuick/${mod}" ]]; then
    warn "QML module QtQuick.${mod} missing after macdeployqt — copying from Homebrew…"
    mkdir -p "${APP_SRC}/Contents/Resources/qml/QtQuick"
    cp -R "${QML_IMPORT_PATH}/QtQuick/${mod}" "${APP_SRC}/Contents/Resources/qml/QtQuick/"
  fi
done

# qt.conf so the installed app finds PlugIns/ and QML without relying on env vars
mkdir -p "${APP_SRC}/Contents/Resources"
cat > "${APP_SRC}/Contents/Resources/qt.conf" <<'EOF'
[Paths]
Plugins = PlugIns
QmlImports = Resources/qml
Qml2Imports = Resources/qml
EOF

ok "Qt frameworks + platforms + QML modules bundled"

# ── ad-hoc code sign (required after macdeployqt rewrites binaries) ─────────
step "Signing app (ad-hoc)"
codesign --force --deep --sign - "${APP_SRC}"
codesign --verify --verbose=1 "${APP_SRC}" >/dev/null
ok "Signature valid"

# ── install into Applications ───────────────────────────────────────────────
step "Installing to ${DEST}"

if [[ -d "${DEST}" ]]; then
  info "Removing previous installation…"
  # Quit running instance if any
  osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
  sleep 0.5
  rm -rf "${DEST}"
fi

mkdir -p "${INSTALL_DIR}"
# ditto preserves bundle metadata better than cp -R
ditto "${APP_SRC}" "${DEST}"

# Clear quarantine if present (harmless if absent)
xattr -dr com.apple.quarantine "${DEST}" 2>/dev/null || true

# Re-sign at final location
codesign --force --deep --sign - "${DEST}"

[[ -x "${DEST}/Contents/MacOS/${APP_NAME}" ]] || die "Install failed — binary missing at destination."
ok "Installed: ${DEST}"

# ── optional: refresh Launch Services so Spotlight / Launchpad see it ───────
if [[ -x /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister ]]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "${DEST}" >/dev/null 2>&1 || true
fi

# ── done ────────────────────────────────────────────────────────────────────
printf "\n"
ok "${APP_NAME} is ready in ${INSTALL_DIR}"
printf "\n"
printf "  Open it:\n"
printf "    %sopen -a %s%s\n" "$C_DIM" "$APP_NAME" "$C_RESET"
printf "    or from Launchpad / Spotlight (⌘Space → WageTick)\n"
printf "\n"
printf "  Uninstall later:\n"
printf "    %s./uninstall.sh%s\n" "$C_DIM" "$C_RESET"
printf "\n"

# Launch unless WAGETICK_NO_LAUNCH=1
if [[ "${WAGETICK_NO_LAUNCH:-0}" != "1" ]]; then
  info "Launching ${APP_NAME}…"
  open -a "${APP_NAME}" || open "${DEST}"
fi
