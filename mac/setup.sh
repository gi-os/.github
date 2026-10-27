#!/bin/bash
# Sets up a Mac (Giovanni's Mac mini) for gi-os iOS work driven from the phone with Claude Code
# Remote Control: the tools the kit uses, the kit and every gi-os app on it in ~/Developer/gi-os,
# and a workspace there that phone-started sessions understand. Re-run any time: it installs only
# what's missing and fast-forwards the clones.
#   gh repo clone gi-os/.github ~/Developer/gi-os/.github && bash ~/Developer/gi-os/.github/mac/setup.sh
# --always-on also keeps the Mac awake for good and runs `claude remote-control` as a login service
# that restarts itself, so the phone can always start a session. (It asks for your password once.)
# Before the first --always-on, run `claude remote-control` once in $ROOT and answer its question.
set -euo pipefail
ROOT="${GIOS_ROOT:-$HOME/Developer/gi-os}"
KIT="$ROOT/.github"
ALWAYS_ON=false
[ "${1:-}" = "--always-on" ] && ALWAYS_ON=true
say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

say "Xcode"
if ! xcodebuild -version >/dev/null 2>&1; then
  # Often Xcode is there but the Mac still points at the Command Line Tools.
  X=$(find /Applications -maxdepth 1 -name 'Xcode*.app' ! -iname '*beta*' 2>/dev/null | sort -V | tail -1)
  if [ -n "$X" ]; then
    echo "$X is installed but not selected. Run, then run this again:"
    echo "  sudo xcode-select -s \"$X/Contents/Developer\" && sudo xcodebuild -license accept && xcodebuild -runFirstLaunch"
  else
    echo "Install Xcode from the App Store, open it once, then run this again."
  fi
  exit 1
fi
xcodebuild -version | head -1
xcrun simctl list runtimes 2>/dev/null | grep -q iOS || echo "No iOS simulator yet: run  xcodebuild -downloadPlatform iOS"

say "Tools"
command -v brew >/dev/null || { echo "Install Homebrew first (https://brew.sh), then run this again."; exit 1; }
for tool in gh xcodegen fastlane; do
  if command -v "$tool" >/dev/null; then echo "$tool ✓"; else brew install "$tool"; fi
done
command -v claude >/dev/null || { echo "Install Claude Code (brew install --cask claude-code), sign in by running 'claude', then run this again."; exit 1; }
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
# Each app's own copy of the kit in .gios/ (gitignored), as its session hook keeps it, so the house
# rules' `bash .gios/ios/ci/kit.sh ...` works from any session, wherever it started.
for r in $apps; do
  if [ -d "$ROOT/$r/.gios/.git" ]; then
    git -C "$ROOT/$r/.gios" fetch -q --depth 1 origin main && git -C "$ROOT/$r/.gios" reset -q --hard FETCH_HEAD
  else
    rm -rf "$ROOT/$r/.gios" && git clone -q --depth 1 https://github.com/gi-os/.github.git "$ROOT/$r/.gios"
  fi
done

say "Workspace"
# Sessions the phone starts open in $ROOT itself, so it gets the house rules and the kit's skills.
mkdir -p "$ROOT/.claude/skills"
for s in "$KIT"/.claude/skills/gios-*; do
  [ -d "$s" ] || continue
  rm -rf "$ROOT/.claude/skills/$(basename "$s")" && cp -R "$s" "$ROOT/.claude/skills/"
done
cat > "$ROOT/CLAUDE.md" <<'MD'
# gi-os workspace (Giovanni's Mac mini)

Every gi-os iOS app on the kit is cloned here, one folder each, with the kit itself in `.github/`.
Work inside the app's folder (`cd <App>`), whose own CLAUDE.md says what it is; kit changes go in
`.github/`. Written by `.github/mac/setup.sh`: re-run it to pick up new apps and kit updates.

@.github/ios/claude/CONTEXT.md
MD
echo "CLAUDE.md and $(find "$ROOT/.claude/skills" -maxdepth 1 -name 'gios-*' | wc -l | tr -d ' ') skills in $ROOT"

if $ALWAYS_ON; then
  say "Always on"
  # Never sleep, wake for network access, start again after a power cut.
  sudo pmset -a sleep 0 disksleep 0 womp 1 autorestart 1
  # `claude remote-control` as a login service: KeepAlive restarts it if it exits, which it does
  # after about ten minutes without a network. Run it once by hand first: its first start asks
  # "Enable Remote Control? (y/n)", which a service can't answer.
  PLIST="$HOME/Library/LaunchAgents/com.gios.claude-remote.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  # launchd doesn't read your shell profile: give it claude's full path and this PATH (Homebrew,
  # Xcode tools) so sessions find everything a terminal would.
  cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.gios.claude-remote</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(command -v claude)</string><string>remote-control</string><string>--name</string><string>Mac mini</string>
  </array>
  <key>WorkingDirectory</key><string>$ROOT</string>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>$PATH</string></dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>30</integer>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/claude-remote.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/claude-remote.log</string>
</dict>
</plist>
PL
  launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  echo "Remote Control runs as a login service (log: ~/Library/Logs/claude-remote.log)"
fi

say "Done"
if $ALWAYS_ON; then
  echo "On your phone: Claude app → Code → \"Mac mini\" → start a session. It opens in $ROOT."
else
  cat <<MSG
Start the Remote Control server, then use it from the Claude app on your phone (Code tab):
  cd $ROOT && claude remote-control --name "Mac mini"
Run this script with --always-on to keep it running for good.
MSG
fi
