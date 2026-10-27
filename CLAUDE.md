# gi-os/.github

The shared iOS kit (ios/README.md) plus account-wide defaults. Every gi-os iOS app runs these
workflows, scripts and lanes from `main`, so a change here is a change to all of them: work on a
branch, keep each app's behaviour, and get **Kit check** green (it builds an app from the template on
a Mac) before merging. Locally: `shellcheck ios/ci/*.sh ios/claude/*.sh ios/new-app.sh` and
`actionlint`. The skills in `.claude/skills/gios-*` are copied into app sessions by their hook.

From here you can also start a new app (`gios-new-app`) or move an app onto the kit (`gios-adopt`):
attach that app's repo with `add_repo` first.

@ios/claude/CONTEXT.md
