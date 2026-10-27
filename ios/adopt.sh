#!/bin/bash
# The mechanical half of moving an app onto the kit (the gios-adopt skill covers the rest): copies
# the template's workflow callers, Fastfile import and Claude hook into the app repo at $1, adds the
# .gitignore lines, and removes the ci scripts the kit now runs. ci/app.env knobs, app-only lanes
# and workflows, and CLAUDE.md are left for you. Review the result with git diff.
set -euo pipefail
APP="${1:?usage: adopt.sh <app repo dir>}"
T="$(cd "$(dirname "${BASH_SOURCE[0]}")/template" && pwd)"
[ -f "$APP/project.yml" ] || { echo "$APP has no project.yml" >&2; exit 1; }
mkdir -p "$APP/.github/workflows" "$APP/fastlane" "$APP/.claude/hooks" "$APP/ci"
for f in .github/workflows/check.yml .github/workflows/build.yml .github/workflows/release.yml \
  .github/workflows/claude.yml fastlane/Fastfile .claude/settings.json .claude/hooks/session-start.sh; do
  cp "$T/$f" "$APP/$f"
done
[ -f "$APP/Gemfile" ] || cp "$T/Gemfile" "$APP/Gemfile"
for f in select-xcode.sh sim.sh test.sh build-unsigned.sh; do rm -f "$APP/ci/$f"; done
rm -f "$APP/.github/workflows/attach.yml"   # now release.yml's "attach" lane
touch "$APP/.gitignore"
[ -z "$(tail -c1 "$APP/.gitignore")" ] || echo >> "$APP/.gitignore"
grep -qxF '.gios/' "$APP/.gitignore" || printf '%s\n' \
  '# the shared kit (gi-os/.github), fetched by CI and by .claude/hooks/session-start.sh' \
  '.gios/' '.claude/skills/gios-*/' '.claude/settings.local.json' >> "$APP/.gitignore"
echo "Adopted $APP: now set ci/app.env, write CLAUDE.md, and review git diff"
