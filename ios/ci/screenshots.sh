#!/bin/bash
# Screenshots of the app the tests just built, so UI work can be checked without a Mac: the
# launch screen in light and dark, then one per name in SCREENS (ci/app.env), each launched
# with `-gios-screen <name>` (UserDefaults key "gios-screen") for the app to route to. PNGs go
# to /tmp/gios-shots, which the Check workflow uploads as the "screenshots" artifact.
set -euo pipefail
source ci/app.env
OUT=/tmp/gios-shots
DD=/tmp/gios-dd
rm -rf "$OUT" && mkdir -p "$OUT"
BID="${TARGETS%%,*}"; BID="${BID#*:}"
APP=""
for a in "$DD"/Build/Products/*-iphonesimulator/*.app; do
  [ -d "$a" ] || continue
  [ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$a/Info.plist" 2>/dev/null)" = "$BID" ] && APP="$a" && break
done
if [ -z "$APP" ]; then
  echo "No simulator build of $BID in $DD; building one"
  DEV=$(bash "$(dirname "${BASH_SOURCE[0]}")/sim.sh")
  xcodebuild build -project "${PROJECT:-$SCHEME}.xcodeproj" -scheme "$SCHEME" -destination "id=$DEV" \
    -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO -quiet 2>&1 | tail -40
  for a in "$DD"/Build/Products/*-iphonesimulator/*.app; do
    case "$a" in *-Runner.app) ;; *) APP="$a"; break ;; esac
  done
fi
DEV=$(bash "$(dirname "${BASH_SOURCE[0]}")/sim.sh")
xcrun simctl boot "$DEV" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl status_bar "$DEV" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 >/dev/null 2>&1 || true
xcrun simctl install "$DEV" "$APP"
xcrun simctl privacy "$DEV" grant all "$BID" >/dev/null 2>&1 || true
shot() { # name appearance [screen]
  xcrun simctl ui "$DEV" appearance "$2" >/dev/null 2>&1 || true
  xcrun simctl terminate "$DEV" "$BID" >/dev/null 2>&1 || true
  if [ -n "${3:-}" ]; then xcrun simctl launch "$DEV" "$BID" -gios-screen "$3" >/dev/null
  else xcrun simctl launch "$DEV" "$BID" >/dev/null; fi
  sleep "${SHOT_DELAY:-5}"
  xcrun simctl io "$DEV" screenshot --type=png "$OUT/$1.png" >/dev/null 2>&1 && echo "Took $1.png"
}
shot 01-launch light
shot 02-launch-dark dark
n=3
for s in ${SCREENS:-}; do shot "$(printf '%02d' "$n")-$s" light "$s"; n=$((n + 1)); done
xcrun simctl ui "$DEV" appearance light >/dev/null 2>&1 || true
