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
# The callers say "main"; a repo whose default branch is something else gets that instead.
DEF=$(git -C "$APP" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
if [ -n "$DEF" ] && [ "$DEF" != main ]; then
  sed -i.bak -e "s/\[main\]/[$DEF]/" -e "s/push to main/push to $DEF/" -e "s/so main is/so $DEF is/" \
    -e "s/rebuild main on/rebuild $DEF on/" "$APP/.github/workflows/check.yml" "$APP/.github/workflows/build.yml"
  rm -f "$APP/.github/workflows/check.yml.bak" "$APP/.github/workflows/build.yml.bak"
fi
[ -f "$APP/Gemfile" ] || cp "$T/Gemfile" "$APP/Gemfile"
for f in select-xcode.sh sim.sh test.sh build-unsigned.sh; do rm -f "$APP/ci/$f"; done
rm -f "$APP/.github/workflows/attach.yml"   # now release.yml's "attach" lane
touch "$APP/.gitignore"
[ -z "$(tail -c1 "$APP/.gitignore")" ] || echo >> "$APP/.gitignore"
grep -qxF '.gios/' "$APP/.gitignore" || printf '%s\n' \
  '# the shared kit (gi-os/.github), fetched by CI and by .claude/hooks/session-start.sh' \
  '.gios/' '.claude/skills/gios-*/' '.claude/settings.local.json' >> "$APP/.gitignore"
echo "Adopted $APP: now set ci/app.env, write CLAUDE.md, and review git diff"
