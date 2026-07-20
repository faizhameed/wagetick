# Contributing to WageTick

Thanks for helping improve WageTick. This project follows the usual public open-source workflow used on GitHub.

## Ground rules

- Be respectful and constructive in issues and pull requests.
- Keep changes focused: one concern per PR when practical.
- Prefer clear commit messages that explain *why*, not only *what*.
- Do **not** commit build artifacts (`build/`, `build-release/`, `*.app` contents from local deploys).

## Who can push what?

| Role | How you contribute |
|------|--------------------|
| **Anyone** | Fork, open issues, submit pull requests |
| **Collaborators** (invited Write access) | Same as above; may also push to non-protected branches if policy allows |
| **Maintainers** (Write/Admin on this repo) | Merge PRs, tag releases, publish GitHub Releases |

**Random users cannot push to `main` on this repository.**  
GitHub only accepts pushes from accounts that have been granted write access. Everyone else works via **fork + pull request**.

If you are invited as a contributor, still prefer PRs for reviewable changes unless maintainers ask you to push a branch for a specific task.

---

## Development setup (Apple Silicon)

```bash
# Prerequisites
xcode-select --install   # if needed
# Homebrew: https://brew.sh

git clone https://github.com/YOUR_USERNAME/wagetick.git
cd wagetick
git remote add upstream https://github.com/faizhameed/wagetick.git

brew install cmake qtbase qtdeclarative qtsvg

cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
open build/WageTick.app
```

Install into `/Applications` like end users:

```bash
./install.sh
```

---

## Workflow (fork & pull request)

1. **Fork** [faizhameed/wagetick](https://github.com/faizhameed/wagetick) on GitHub.
2. **Clone your fork** and add `upstream`:

   ```bash
   git clone https://github.com/YOUR_USERNAME/wagetick.git
   cd wagetick
   git remote add upstream https://github.com/faizhameed/wagetick.git
   ```

3. **Sync** before starting work:

   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

4. **Create a branch** (examples):

   ```bash
   git checkout -b fix/timer-pause
   git checkout -b feat/new-currency
   git checkout -b docs/readme-typo
   ```

5. **Make your changes**, build, and run the app.
6. **Commit** with a meaningful message:

   ```bash
   git add -p
   git commit -m "Fix pause so elapsed time does not jump on resume"
   ```

7. **Push to your fork** (not the upstream repo, unless you have write access and maintainers asked you to):

   ```bash
   git push origin fix/timer-pause
   ```

8. Open a **Pull Request** against `faizhameed/wagetick` → `main`.
   - Describe the problem and the solution.
   - Link related issues (`Fixes #123`).
   - Note any UX or platform testing you did (macOS version, Apple Silicon).

### PR checklist

- [ ] Builds cleanly on Apple Silicon with the documented CMake/Qt setup  
- [ ] UI still works for Start / Stop / Reset and currency dropdown  
- [ ] No unrelated formatting churn  
- [ ] Version bump **only** if this PR is intentionally a release (usually maintainers handle that)  

---

## Reporting bugs

Open an [issue](https://github.com/faizhameed/wagetick/issues) with:

- macOS version and chip (e.g. macOS 15, M2)
- WageTick version (header chip, e.g. `v1.2.0`)
- Steps to reproduce
- Expected vs actual behavior
- Logs or screenshots if useful

---

## Feature requests

Open an issue describing:

- The use case
- Why it matters
- Any proposed UX (optional)

Large features are easier to land if discussed first.

---

## Code style (lightweight)

- **C++:** C++17, Qt coding style (reasonable consistency with existing files)
- **QML:** Match existing glassmorphic patterns and spacing
- Prefer small, readable functions over clever one-liners
- Don’t add dependencies unless the PR makes a strong case

---

## Versioning & releases *(maintainers only)*

End users get the in-app **Update available** banner only when a **GitHub Release** is published (not merely when code lands on `main`).

Only people with **write access** to this repository can push tags and publish releases on `faizhameed/wagetick`.

### Release steps

1. Ensure `main` is green and the intended changes are merged via PR.
2. Bump the version in `CMakeLists.txt`:

   ```cmake
   project(WageTick VERSION X.Y.Z LANGUAGES CXX)
   ```

3. Merge that bump (or commit on `main` if you are a maintainer following your normal process).
4. Tag and push **from a clone of this repo with write access**:

   ```bash
   git checkout main
   git pull origin main
   git tag -a vX.Y.Z -m "WageTick vX.Y.Z"
   git push origin main
   git push origin vX.Y.Z
   ```

5. On GitHub: **Releases → Draft a new release**
   - Tag: `vX.Y.Z`
   - Write release notes (shown, truncated, in the app banner)
   - Publish as a normal release (**not** draft, **not** pre-release)

Only **published, non-prerelease** releases trigger automatic update prompts.

### Regenerating the README screenshot

Seeds elapsed time to **01:20:45** (1h 20m 45s):

```bash
./scripts/capture-screenshot.sh
```

Or manually:

```bash
WAGETICK_SCREENSHOT_ELAPSED_MS=4845000 \
WAGETICK_SAVE_SCREENSHOT=docs/screenshot.png \
  ./build-test/WageTick.app/Contents/MacOS/WageTick
```

Commit the updated `docs/screenshot.png` in a docs PR if it changed meaningfully.

---

## License

By contributing, you agree that your contributions are licensed under the same [MIT License](LICENSE) that covers this project.
