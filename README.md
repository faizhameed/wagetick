# WageTick

A lightweight desktop app that shows how much you’re earning — **live, every second**.

Set your hourly rate in **USD ($)**, **EUR (€)**, or **GBP (£)**, hit **Start**, and watch the counter climb. Pause anytime with **Stop**, or clear the session with **Reset**.

Built with **C++17 + Qt 6 QML** for a polished glassmorphic UI on macOS.

---

## Features

- Hourly rate input with currency switcher (USD / EUR / GBP)
- Start / Stop / Reset controls
- Live earnings updated from precise elapsed time (shown to 4 decimal places)
- Elapsed clock `HH:MM:SS`
- Per-second and per-minute rate chips
- Glassmorphic dark UI with soft animated ambient orbs
- Rate locked while the timer is running (no accidental mid-session edits)

## Requirements (macOS)

- macOS 12+
- CMake 3.21+
- Qt 6.5+ with: `qtbase`, `qtdeclarative` (includes Quick / Quick Controls / Quick Effects)

Install with Homebrew:

```bash
brew install cmake qtbase qtdeclarative
```

## Build & run

```bash
cd wagetick
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
open build/WageTick.app
# or:
./build/WageTick.app/Contents/MacOS/WageTick
```

Debug build:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
./build/WageTick.app/Contents/MacOS/WageTick
```

## How earnings are calculated

```
earned = (elapsed_milliseconds / 3_600_000) × hourly_rate
```

Time is measured with a high-resolution elapsed timer and accumulated across pause/resume, so stopping and starting mid-session stays accurate.

## Project layout

```
wagetick/
├── CMakeLists.txt
├── resources.qrc
├── README.md
├── src/
│   ├── main.cpp          # App entry, exposes WageTimer to QML
│   ├── WageTimer.h       # Engine API (QObject properties / slots)
│   └── WageTimer.cpp     # Timing + wage math
└── qml/
    └── main.qml          # Glassmorphic UI
```

## License

MIT — use it, fork it, get paid while you stare at it.
