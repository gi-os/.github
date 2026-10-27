---
name: gios-adopt
description: Move an existing gi-os iOS app repo off its copied ci/ scripts, Fastfile and workflows onto the shared kit in gi-os/.github (reusable workflows, shared Fastfile, Claude Code hooks and skills). Use when asked to adopt, migrate, standardize or update an app to the kit.
---

# Adopt the kit (existing gi-os iOS app)

The kit is `ios/` in a gi-os/.github checkout (the template is `ios/template/`). Work on a branch in
the app repo. The goal is the template's shape with every app-specific behaviour preserved.

1. **Inventory** `ci/`, `fastlane/Fastfile`, `.github/workflows/`, `.gitignore`. Diff each ci script and
   the Fastfile against the kit's (`ios/ci/`, `ios/fastlane/Fastfile`) and list what this app does that
   the kit doesn't.
2. **Move knobs into `ci/app.env`** (keys in `ios/README.md`):
   - `runs-on:` → `RUNNER`; workflow `XCODE_VERSION` / `XCODE` → `XCODE`; `SKIP_TESTS` → `SKIP_TESTS`.
   - Steps before `xcodegen` (fetching assets) → `PREPARE`. Extra test commands (`swift test`, sims)
     → `PRE_TEST`; a scheme with no test target → `XCTEST="false"`.
   - Release extras (in-app purchase scripts) → `PRE_RELEASE`; a screenshot UI-test scheme →
     `SCREEN_SCHEME`; `automatic_release: true` → `AUTO_RELEASE="true"`.
3. **Workflows**: replace `check.yml`, `build.yml`, `release.yml` with the template's callers and add
   `claude.yml`. **Keep the file name `build.yml`**: the build number is its run number, and a new file
   would restart at 1 (if it must change, set `BUILD_OFFSET` above the last TestFlight build). Fold
   `attach.yml` into release.yml's `attach` lane. Keep workflows the kit doesn't cover (e.g. `iap.yml`,
   `asc-setup.yml`) as they are.
4. **Fastfile**: the template's one-line import, plus any lane only this app has, below it.
5. **ci/**: delete scripts the kit now runs. Keep app-only scripts (`fetch_logos.py`, `iap.py`, ...).
   Keep a `ci/<step>.sh` as an override only when the app truly needs different behaviour; say why in
   its first comment.
6. **Claude**: copy `ios/template/.claude/` (settings.json, hooks/session-start.sh) and write a short
   CLAUDE.md like the template's with what this app is. Add the template's `.gitignore` lines for
   `.gios/` and `.claude/skills/gios-*/`.
7. **Verify**: push the branch; **Check** must be green (`gios-fix-ci`). The TestFlight path is only
   proven on `main`. Tell the user it's ready to merge, and after they merge, watch the TestFlight run
   and confirm the build number continued.
