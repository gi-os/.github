#!/bin/bash
# The Xcode named by XCODE in ci/app.env (e.g. 27.1), otherwise the newest on the runner. Never a
# beta: App Store Connect refuses beta builds, and on the xcode-27 image the plain Xcode_27.2.app
# is a symlink to one, so links are resolved before betas are ruled out.
set -euo pipefail
source ci/app.env
WANT="${XCODE:-${XCODE_VERSION:-}}"
release() { for x in "$@"; do [ -e "$x" ] || continue; r=$(readlink -f "$x"); case "$r" in *[Bb]eta*) ;; *) echo "$r" ;; esac; done; }
if [ -n "$WANT" ]; then
  X=$(release /Applications/Xcode_"$WANT".app | head -1)
  [ -n "$X" ] || { echo "::error::Xcode $WANT (release) isn't on this runner:"; ls -d /Applications/Xcode_*.app; exit 1; }
else
  X=$(release /Applications/Xcode_*.app | sort -uV | tail -1)
  [ -n "$X" ] || { echo "::error::No release Xcode on this runner"; exit 1; }
fi
sudo xcode-select -s "$X/Contents/Developer"
xcodebuild -version
echo "iOS SDK $(xcrun --sdk iphoneos --show-sdk-version)"
