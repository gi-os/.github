---
name: gios-fix-ci
description: Get a gi-os iOS app's Check or TestFlight workflow green. Use after pushing a branch, when CI fails, or when asked whether a change compiles. Reads GitHub Actions logs, fixes compile errors and test failures, and pushes one validated fix at a time.
---

# Get CI green (gi-os iOS apps)

In a Linux cloud session CI is the compiler. Locally on a Mac, run the same steps directly from the
repo root: `bash .gios/ios/ci/kit.sh generate && bash .gios/ios/ci/kit.sh test`.

## 1. Find the run

- `mcp__github__actions_list` → `list_workflow_runs`, `resource_id: "check.yml"` (or `build.yml` for
  TestFlight), filter `branch: <your branch>`. Take the newest run whose `head_sha` is your last commit.
- Still running? Don't poll with sleep. If the branch has a PR, `subscribe_pr_activity` and end the
  turn; CI results wake you. Otherwise schedule one check-in (`send_later`, ~15 min, a Check takes
  10-20) if available, or tell the user it's running.

## 2. Read the failure

`mcp__github__get_job_logs` with `run_id`, `failed_only: true`, `return_content: true`, `tail_lines: 300`.
The kit's test step prints only what matters:

| Log shows | Meaning / fix |
|---|---|
| `File.swift:12:5: error: ...` | Compile error. Open that line; check every symbol, import and type. |
| `✘ Test ...` / `XCTAssert... failed` | A test failed: fix the code, or the test if it is wrong (say which and why). |
| `type-check` / `long function bodies` warnings | Slow-to-compile expression: split it up if it is in code you touched. |
| `Xcode X (release) isn't on this runner` | `XCODE` in ci/app.env names an Xcode the `RUNNER` image lacks. |
| `No TestFlight upload. Missing secrets` | Only a warning: the user must add repo secrets (see `gios-ship`). |
| `App Store Connect has no app for ...` | The user must create the app record once; nothing to fix in code. |
| Hangs after tests finish / StoreKit or simulator stalls | Runner problem. Put the test in `SKIP_TESTS` only with the user's OK, and say why. |

Never skip, disable or delete a test just to go green.

## 3. Fix and push once

Make the minimal fix. Before pushing, re-read your whole diff as the compiler would: new symbols
defined, `import` lines present, access levels (`@testable import` reaches `internal`, not `private`),
optionals unwrapped, `@MainActor` / `Sendable` consistent with the surrounding code, `#available`
around APIs newer than the deployment target in project.yml. Then commit, push, and go back to step 1.
Repeat until green; then say so in one line.
