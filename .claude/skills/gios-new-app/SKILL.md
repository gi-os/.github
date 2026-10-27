---
name: gios-new-app
description: Create a new gi-os iOS app repository from the kit's template (SwiftUI, XcodeGen, Swift Testing, Check/TestFlight/App Store/Claude workflows, CLAUDE.md). Use when asked to start, make or scaffold a new iOS app.
---

# New gi-os iOS app

The kit is `ios/` in a gi-os/.github checkout, or `.gios/ios/` inside any app repo.

1. **Settle the names** (ask only for what you can't infer):
   - Scheme = repo name, PascalCase letters/digits (`TapeDelay`). Bundle ID becomes
     `com.gios.<scheme lowercased>`.
   - Display name (home screen) and a one-line description. Public unless the user says private.
2. **Create the repo** through the secrets hub (this session's GitHub integration can't create
   repos): `add_repo` gi-os/ios-certs, then `mcp__github__actions_run_trigger` → `run_workflow`,
   `owner: gi-os`, `repo: ios-certs`, `workflow_id: "new-repo.yml"`, `ref: "master"`,
   `inputs: {"name": "<Scheme>", "description": "...", "private": "false"}`. When that run succeeds
   (it also copies in the secrets), attach the new repo with `add_repo` (`access: "push"`) and clone
   it as that tool says. If the run fails with "Add the HUB_TOKEN secret", the hub isn't set up yet:
   ask Giovanni to create the empty repo at github.com/new and point them to HUB.md in ios-certs.
3. **Fill it**: `bash <kit>/ios/new-app.sh <Scheme> "<Display name>" <path to the clone>`.
   Then replace the TODO in CLAUDE.md with what the app is, and adjust project.yml (deployment target,
   orientations, capabilities) and ci/app.env (RUNNER/XCODE for a newer SDK) if the app needs it.
4. **Make it the user's app**: build the first screen they described, keeping logic in testable types
   with a Swift Testing test for it. Replace the placeholder icon at
   `<Scheme>/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` if they gave you one (1024²,
   no alpha).
5. **First push** goes to `main` (a new repo has nothing to protect); later work goes through PRs.
   The TestFlight run registers the bundle ID and makes the signing profiles, then stops at
   "App Store Connect has no app for ..." until the app record exists. Check must be green.
6. **Tell Giovanni the one step only they can do**: App Store Connect → My Apps → + → New App,
   bundle ID `com.gios.<scheme>`, name `<Display name>`. Then re-run the TestFlight workflow yourself
   once they say it's done (`run_workflow`, `workflow_id: "build.yml"`).
