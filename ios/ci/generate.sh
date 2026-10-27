#!/bin/bash
# PREPARE from ci/app.env (whatever the build needs that isn't in git, e.g. fetched assets), then
# the Xcode project from project.yml. The .xcodeproj is never committed.
set -euo pipefail
source ci/app.env
if [ -n "${PREPARE:-}" ]; then
  echo "+ $PREPARE"
  bash -o pipefail -c "$PREPARE"
fi
command -v xcodegen >/dev/null || brew install xcodegen >/dev/null
xcodegen generate
