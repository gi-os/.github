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
2. **Create the repo**: `mcp__github__create_repository` (`name`, `description`, `private`,
   `autoInit: false`). In a cloud session, attach it with `add_repo` (`access: "push"`) and clone it as
   that tool says; locally, `git clone`.
3. **Fill it**: `bash <kit>/ios/new-app.sh <Scheme> "<Display name>" <path to the clone>`.
   Then replace the TODO in CLAUDE.md with what the app is, and adjust project.yml (deployment target,
   orientations, capabilities) and ci/app.env (RUNNER/XCODE for a newer SDK) if the app needs it.
4. **Make it the user's app**: build the first screen they described, keeping logic in testable types
   with a Swift Testing test for it. Replace the placeholder icon at
   `<Scheme>/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` if they gave you one (1024²,
   no alpha).
5. **First push** goes to `main` (a new repo has nothing to protect). Without secrets the TestFlight
   workflow still tests and compiles, so a green run there proves the scaffold. Later work goes on
   branches.
6. **Tell the user the one-time steps**, nothing else:
   - Repo secrets (personal account, so per repo): ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8,
     MATCH_PASSWORD, MATCH_GIT_AUTH; CLAUDE_CODE_OAUTH_TOKEN for @claude on a Mac runner.
     From a Mac with the values: `gh secret set NAME -R gi-os/<Scheme>`.
   - App Store Connect → My Apps → + → New App with bundle ID `com.gios.<scheme>` (the first
     TestFlight run with secrets registers the bundle ID, then says when this is needed).
   - Install the Claude GitHub app on the repo for @claude: https://github.com/apps/claude
