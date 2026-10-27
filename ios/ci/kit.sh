#!/bin/bash
# One step of the shared iOS pipeline, run from the app repo's root: the app's own ci/<step>.sh
# when it has one (an override for an app that needs something different), otherwise the kit's.
# Steps: select-xcode, generate, test, build-unsigned.
set -euo pipefail
step="$1"
shift
if [ -f "ci/$step.sh" ]; then
  echo "Using this app's own ci/$step.sh"
  exec bash "ci/$step.sh" "$@"
fi
exec bash "$(dirname "${BASH_SOURCE[0]}")/$step.sh" "$@"
