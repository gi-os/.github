# gi-os iOS kit

One copy of the pipeline every gi-os iOS app uses, instead of a drifting copy in each repo.

| Piece | Where | What |
|---|---|---|
| Reusable workflows | `.github/workflows/ios-*.yml`, `claude.yml` | Check, TestFlight, App Store, Claude on a Mac |
| CI steps | `ios/ci/` | `kit.sh <step>`: select-xcode, generate, test, build-unsigned |
| Fastlane lanes | `ios/fastlane/Fastfile` | ship, attach, screenshots, release (imported by each app) |
| New app | `ios/new-app.sh`, `ios/template/` | SwiftUI + XcodeGen + Swift Testing + all of the above |
| Claude Code | `ios/claude/`, `.claude/skills/gios-*` | House rules, an edit guard, and skills, loaded by each app's session hook |

## An app on the kit

```
project.yml                 # XcodeGen: the only project file in git
ci/app.env                  # per-app knobs (below)
fastlane/Fastfile           # one import_from_git line (+ app-only lanes)
.github/workflows/          # check.yml, build.yml, release.yml, claude.yml: ~20-line callers
.claude/settings.json       # SessionStart: fetch kit → .gios/, install skills, print house rules
CLAUDE.md                   # what this app is
```

Start one: `bash ios/new-app.sh BasilCam "Basil Cam"`, or ask Claude (`gios-new-app`).
Move an older app over: ask Claude to adopt it (`gios-adopt`).

## ci/app.env

Plain `KEY="value"` lines (fastlane parses them too, so no quotes inside values). No secrets.

| Key | Used by | Meaning |
|---|---|---|
| `APP_NAME` | fastlane | Display name for registrations and messages |
| `SCHEME` | all | Xcode scheme (= project name unless `PROJECT` is set) |
| `TARGETS` | fastlane | `target:bundle.id,...` for everything that ships, app first |
| `RUNNER` | workflows | macOS runner label (default `macos-15`; `xcode-27` for the iOS 27.1 SDK) |
| `XCODE` | select-xcode | Xcode version, e.g. `27.1` (default: newest non-beta) |
| `PREPARE` | generate | Command before `xcodegen` (fetch assets that aren't in git) |
| `PRE_TEST` | test | Command before the simulator tests (e.g. `swift test`) |
| `XCTEST` | test | `false`: scheme has no tests, build for the simulator instead |
| `SKIP_TESTS` | test | `Target/Class/test` ids the runner can't run, space-separated |
| `APP_GROUP` | ship | Turn on App Groups for every bundle ID |
| `PUSH_BUNDLE` | ship | Turn on Push Notifications for this bundle ID |
| `EXTERNAL_GROUPS` | ship | TestFlight groups that get every build, comma-separated |
| `BUILD_OFFSET` | ship | Added to the run number (after renaming build.yml) |
| `SCREEN_SCHEME` | release | UI-test scheme that takes App Store screenshots |
| `PRE_RELEASE` | release | Command before the upload (e.g. in-app purchases); never fails the run |
| `AUTO_RELEASE` | release | `true`: goes live as soon as App Review approves |
| `THIRD_PARTY_CONTENT` | release | Content-rights answer for submission |
| `PROJECT` | all | Project name when it differs from `SCHEME` |

An app's own `ci/<step>.sh` replaces the kit's step, for the rare app that needs to.

## Secrets (per repo: gi-os is a personal account)

`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `MATCH_PASSWORD`, `MATCH_GIT_AUTH` (TestFlight).
Optional: `REVIEW_FIRST_NAME`, `REVIEW_LAST_NAME`, `REVIEW_EMAIL`, `REVIEW_PHONE` (App Review contact),
`CLAUDE_CODE_OAUTH_TOKEN` (`claude setup-token`; @claude on a Mac runner, plus the Claude GitHub app).

## Changing the kit

Everything here is used from `main` by every app, so change it on a branch: **Kit check** builds a
fresh app from the template on a Mac, runs every step, and checks fastlane imports the lanes.
