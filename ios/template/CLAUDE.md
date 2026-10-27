# __DISPLAY__

iOS app (SwiftUI) on the gi-os kit. The shared house rules, pipeline and skills come from
gi-os/.github and are loaded at session start by `.claude/hooks/session-start.sh`; the kit itself
is in `.gios/` (read-only here: change it in gi-os/.github).

## This app

- What it is: TODO, one or two lines.
- Code map: `__APP__/App` entry point, `__APP__/UI` views, `__APP__Tests` unit tests (Swift Testing).
- Config: `project.yml` (targets, Info.plist keys, version), `ci/app.env` (pipeline knobs).

## App-specific rules

- Keep logic out of views so `__APP__Tests` can test it.
