# WageTick

Watch your earnings tick up — **live, every second**.

Set your hourly rate in **USD ($)**, **EUR (€)**, or **GBP (£)**, hit **Start**, and the counter climbs in real time. Pause with **Stop**, clear with **Reset**.

Glassmorphic dark UI · C++17 + Qt 6 · **Apple Silicon Mac**

---

## Install (Apple Silicon)

**One-time setup** — clone the repo and run the installer. It installs dependencies (via Homebrew), builds the app, and puts **WageTick** in your **Applications** folder.

```bash
git clone https://github.com/faizhameed/wagetick.git
cd wagetick
./install.sh
```

That’s it. Open it from **Launchpad**, **Spotlight** (⌘Space → `WageTick`), or:

```bash
open -a WageTick
```

### What the installer does

1. Checks you’re on **Apple Silicon** (`arm64`) macOS  
2. Ensures **Xcode Command Line Tools** + **Homebrew** are available  
3. Installs `cmake`, `qtbase`, `qtdeclarative`, `qtsvg`  
4. Builds a **Release** app bundle  
5. Bundles Qt frameworks into the `.app` (self-contained)  
6. Ad-hoc code-signs the app  
7. Installs to `/Applications/WageTick.app` and launches it  

First install may take several minutes while Homebrew fetches Qt.

### Uninstall

```bash
./uninstall.sh
# or:
rm -rf /Applications/WageTick.app
```

### Reinstall / update

```bash
git pull
./install.sh
```

---

## Requirements

| Item | Notes |
|------|--------|
| Mac | **Apple Silicon** (M1 / M2 / M3 / M4 …) |
| macOS | 12 Monterey or newer recommended |
| Network | Needed once for Homebrew + Qt packages |
| Disk | ~1–2 GB free during build (Qt toolchain); app itself ~120 MB |

Intel Macs are not covered by this installer.

---

## Features

- Hourly rate + currency dropdown (USD / EUR / GBP)
- Start / Stop / Reset
- Live earnings (4 decimal places) from precise elapsed time
- Elapsed clock `HH:MM:SS`
- Per-second and per-minute chips
- Glassmorphic UI with soft animated ambient orbs
- Rate locked while the timer is running
- In-app update checks (GitHub Releases) with optional dismiss / remind later

---

## How earnings are calculated

```
earned = (elapsed_milliseconds / 3_600_000) × hourly_rate
```

Time uses a high-resolution clock and accumulates across pause/resume.

---

## Developer build (optional)

If you only want to compile without installing to Applications:

```bash
brew install cmake qtbase qtdeclarative qtsvg
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
open build/WageTick.app
```

Or use the Makefile:

```bash
make install    # full install to /Applications
make uninstall
make clean
```

---

## Project layout

```
wagetick/
├── install.sh            # ← one-command install to /Applications
├── uninstall.sh
├── Makefile
├── CMakeLists.txt
├── resources.qrc
├── src/
│   ├── main.cpp
│   ├── WageTimer.h
│   └── WageTimer.cpp
├── resources/
│   ├── AppIcon.icns      # macOS app icon
│   └── AppIcon-1024.png
└── qml/
    └── main.qml
```

---


---

## How users get notified of new versions

WageTick checks **GitHub Releases** automatically about once a day (and when the user taps the version chip in the header).

When a newer **published release** exists than the installed app version:

1. A banner appears: **Update available** (`vX.Y.Z → vA.B.C`)
2. **View release** opens the GitHub release page  
3. **How to update** opens install/update instructions  
4. **Skip** hides that version; **✕** reminds again in 24 hours  

Users still install updates by re-running `./install.sh` (or following the release notes). There is no silent auto-download yet.

### Maintainers: publish a release so users get notified

1. Bump the version in `CMakeLists.txt`:
   ```cmake
   project(WageTick VERSION 1.2.0 LANGUAGES CXX)
   ```
2. Commit, tag, and push:
   ```bash
   git add -A && git commit -m "Release v1.2.0"
   git tag v1.2.0
   git push origin main --tags
   ```
3. On GitHub → **Releases → Draft a new release**
   - Choose tag `v1.2.0`
   - Title + release notes (shown truncated in the app banner)
   - Publish (not prerelease / not draft)

Only **published, non-prerelease** releases trigger the in-app banner.  
Repo used for checks: `faizhameed/wagetick`.

## License

MIT — use it, fork it, get paid while you stare at it.
