#!/bin/bash
# Release build for a device, unsigned: catches what a simulator build doesn't (device-only
# code paths, Release-only settings) without needing any signing secrets.
set -euo pipefail
source ci/app.env
xcodebuild build -project "${PROJECT:-$SCHEME}.xcodeproj" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO -quiet 2>&1 | tail -200
