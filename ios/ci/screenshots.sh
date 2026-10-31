#!/bin/bash
# Screenshots of the app, so UI work can be checked without a Mac: the launch screen in light and
# dark, then one per name in SCREENS (ci/app.env), each launched with `-gios-screen <name>`
# (UserDefaults key "gios-screen") for the app to route to. Uses the simulator build the tests
# left in /tmp/gios-dd, or builds one (Check runs this in its own job, alongside the tests). PNGs
# go to /tmp/gios-shots, which the Check workflow uploads as the "screenshots" artifact.
set -euo pipefail
source ci/app.env
OUT=/tmp/gios-shots
DD=/tmp/gios-dd
rm -rf "$OUT" && mkdir -p "$OUT"
BID="${TARGETS%%,*}"; BID="${BID#*:}"
DEV=$(bash "$(dirname "${BASH_SOURCE[0]}")/sim.sh")
# Boots while the app builds (a fresh runner takes up to three minutes); waited for below.
xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1 &
built_app() {
  for a in "$DD"/Build/Products/*-iphonesimulator/*.app; do
    [ -d "$a" ] || continue
    [ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$a/Info.plist" 2>/dev/null)" = "$BID" ] && echo "$a" && return
  done
  return 0
}
APP=$(built_app)
if [ -z "$APP" ]; then
  echo "No simulator build of $BID in $DD; building one"
  xcodebuild build -project "${PROJECT:-$SCHEME}.xcodeproj" -scheme "$SCHEME" -destination "id=$DEV" \
    -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO -quiet 2>&1 | tail -40
  APP=$(built_app)
  [ -n "$APP" ] || { echo "The build made no app with bundle ID $BID"; exit 1; }
fi
echo "Simulator: $(xcrun simctl list devices | grep -m1 "$DEV" | sed 's/^ *//')"
xcrun simctl boot "$DEV" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl status_bar "$DEV" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 >/dev/null 2>&1 || true
xcrun simctl install "$DEV" "$APP"
xcrun simctl privacy "$DEV" grant all "$BID" >/dev/null 2>&1 || true
shot() { # name appearance [screen]; a failed shot is a warning, not the end of the step
  local args=() err
  xcrun simctl ui "$DEV" appearance "$2" >/dev/null 2>&1 || true
  xcrun simctl terminate "$DEV" "$BID" >/dev/null 2>&1 || true
  [ -n "${3:-}" ] && args=(-gios-screen "$3")
  if ! err=$(xcrun simctl launch "$DEV" "$BID" ${args[@]+"${args[@]}"} 2>&1); then
    echo "::warning::Couldn't launch $BID for $1: $err"; return 0
  fi
  sleep "${SHOT_DELAY:-5}"
  if err=$(xcrun simctl io "$DEV" screenshot "$OUT/$1.png" 2>&1); then echo "Took $1.png"; return 0; fi
  # A simulator with more than one screen (iPhone Duo) refuses to pick one and lists them
  # ("--display=3  LCD-1 (primary-1) 2007x2853"): take each, named by its size.
  local took=0 id size
  while read -r id size; do
    if xcrun simctl io "$DEV" screenshot --display="$id" "$OUT/$1-$size.png" >/dev/null 2>&1; then
      echo "Took $1-$size.png"; took=1
    fi
  done < <(printf '%s\n' "$err" | sed -nE 's/.*--display=([0-9]+) .* ([0-9]+x[0-9]+) *$/\1 \2/p')
  [ "$took" = 1 ] || echo "::warning::Couldn't screenshot $1: $err"
}
shot 01-launch light
shot 02-launch-dark dark
n=3
for s in ${SCREENS:-}; do shot "$(printf '%02d' "$n")-$s" light "$s"; n=$((n + 1)); done
xcrun simctl ui "$DEV" appearance light >/dev/null 2>&1 || true
ls "$OUT"/*.png >/dev/null 2>&1 || { echo "No screenshots taken"; exit 1; }
