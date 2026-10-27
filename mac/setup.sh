#!/bin/bash
# Sets up a Mac for gi-os iOS work driven from the phone (Claude Code Remote Control): the tools the
# kit uses, and a clone of the kit plus every gi-os app on it in ~/Developer/gi-os. Re-run any time:
# it only installs what's missing and fast-forwards the clones.
#   gh repo clone gi-os/.github ~/Developer/gi-os/.github && bash ~/Developer/gi-os/.github/mac/setup.sh
set -euo pipefail
ROOT="${GIOS_ROOT:-$HOME/Developer/gi-os}"
say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

say "Xcode"
xcode-select -p >/dev/null 2>&1 || { echo "Install Xcode from the App Store, open it once, then run this again."; exit 1; }
xcodebuild -version | head -1

say "Tools"
command -v brew >/dev/null || { echo "Install Homebrew first (https://brew.sh), then run this again."; exit 1; }
for tool in gh xcodegen fastlane; do
  if command -v "$tool" >/dev/null; then echo "$tool ✓"; else brew install "$tool"; fi
done
command -v claude >/dev/null || { echo "Install Claude Code first (https://code.claude.com), then run this again."; exit 1; }
echo "claude $(claude --version)"

say "GitHub"
gh auth status >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git

say "Repos in $ROOT"
mkdir -p "$ROOT"
apps=$(gh repo list gi-os --limit 1000 --no-archived --json name -q '.[].name' | while read -r r; do
  gh api "repos/gi-os/$r/contents/ci/app.env" --silent >/dev/null 2>&1 && echo "$r"
done)
for r in .github $apps; do
  if [ -d "$ROOT/$r/.git" ]; then
    if git -C "$ROOT/$r" pull -q --ff-only; then echo "updated $r"; else echo "$r has local changes: left as is"; fi
  else
    gh repo clone "gi-os/$r" "$ROOT/$r" -- -q && echo "cloned $r"
  fi
done

say "Done"
cat <<MSG
Start Claude in an app's folder and drive it from the Claude app on your phone:
  cd $ROOT/<App> && claude remote-control
Keep the Mac awake while you're away (plugged in): System Settings → Battery/Energy →
"Prevent automatic sleeping when the display is off", or run: caffeinate -dims &
MSG
