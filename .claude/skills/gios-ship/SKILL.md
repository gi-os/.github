---
name: gios-ship
description: Ship a gi-os iOS app: bump the version, get a build onto TestFlight, or push store text and screenshots to App Store Connect and submit for review. Use when asked to ship, release, cut a version, update the App Store listing, or why a TestFlight build didn't arrive.
---

# Ship (gi-os iOS apps)

## Version

`MARKETING_VERSION` in project.yml is the version users see. Bump it (semver) when a release is
asked for. Build numbers are automatic: the TestFlight workflow's run number + `BUILD_OFFSET`.

## TestFlight: every push to the default branch

1. Work on a branch until **Check** is green (`gios-fix-ci`).
2. Squash-merge the green PR (the house rules: every change ships unless the request says "PR only").
   The push to the default branch starts **TestFlight** (`build.yml`).
3. Watch that run (`mcp__github__actions_list` → `list_workflow_runs`, `resource_id: "build.yml"`).
   - `Missing secrets` warning: tested and compiled, but nothing was uploaded. The secrets hub
     (gi-os/ios-certs, HUB.md) copies them in: `add_repo` ios-certs, run `sync-secrets.yml` (ref `master`) with
     `inputs: {"repo": "<App>"}`, then re-run TestFlight. If the hub itself lacks them, tell
     Giovanni which ones to add there.
   - `App Store Connect has no app for X`: the hub has no Apple ID session, so the record can't be
     made automatically. Ask Giovanni either to create it (My Apps → + → New App → bundle ID X) or to
     add FASTLANE_USER / FASTLANE_PASSWORD / FASTLANE_SESSION to the hub (HUB.md), then re-run.
   - `Couldn't create the App Store Connect app`: name taken → set `STORE_NAME` in ci/app.env;
     session expired → Giovanni runs `fastlane spaceauth -u <apple id>` and updates FASTLANE_SESSION.
   - After adding a capability (App Groups, Push, ...): run `build.yml` by hand with
     `force_profiles: true` (`mcp__github__actions_run_trigger`, `run_workflow`, `ref:` the default
     branch).
   - `The bundle version must be higher`: raise `BUILD_OFFSET` in ci/app.env above the last build.

## App Store

Store text lives in `fastlane/metadata/en-US/*.txt` (name, subtitle, description, keywords,
release_notes, promotional_text, support_url, privacy_url), review notes in
`fastlane/review_notes.txt`, screenshots in `fastlane/screenshots/en-US/` (or taken by the
`SCREEN_SCHEME` UI tests). Then run **App Store** (`release.yml`) by hand:

- `mcp__github__actions_run_trigger` → `run_workflow`, `workflow_id: "release.yml"`, `ref:` the default branch,
  `inputs: {"lane": "release", "submit": "false"}`. Use `"submit": "true"` only when the user says to
  submit for review. It needs screenshots, and the REVIEW_FIRST_NAME / REVIEW_LAST_NAME / REVIEW_EMAIL
  / REVIEW_PHONE secrets or that contact filled in once in App Store Connect.
- `lane: "attach"` only puts the newest processed build on the waiting version.

Once the app is live on the App Store, offer to delete the monthly `schedule:` in build.yml (it only
keeps TestFlight builds from expiring).
