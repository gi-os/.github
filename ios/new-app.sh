#!/bin/bash
# A new gi-os iOS app from ios/template:
#   bash ios/new-app.sh <Scheme> ["Display name"] [dir]
# Scheme is PascalCase letters/digits (also the repo and Xcode project name); the bundle ID is
# com.gios.<scheme lowercased>. dir defaults to ./<Scheme>; it may be an empty clone.
set -euo pipefail
NAME="${1:?usage: new-app.sh <Scheme> [\"Display name\"] [dir]}"
DISPLAY="${2:-$NAME}"
DEST="${3:-$NAME}"
[[ "$NAME" =~ ^[A-Z][A-Za-z0-9]*$ ]] || { echo "Scheme must be PascalCase letters and digits: $NAME" >&2; exit 1; }
BUNDLE="com.gios.$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')"
[ ! -e "$DEST/project.yml" ] || { echo "$DEST already has a project.yml" >&2; exit 1; }
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/template" && pwd)"

mkdir -p "$DEST"
cp -R "$SRC/." "$DEST/"
# Paths first (deepest first, so a renamed folder's children are already done), then contents.
find "$DEST" -depth -name '*__APP__*' -not -path '*/.git/*' | while read -r p; do
  mv "$p" "$(dirname "$p")/$(basename "$p" | sed "s/__APP__/$NAME/g")"
done
esc() { printf '%s' "$1" | sed 's/[&/\]/\\&/g'; }
grep -rlI -e __APP__ -e __BUNDLE__ -e __DISPLAY__ --exclude-dir=.git "$DEST" | while read -r f; do
  sed -i.bak -e "s/__APP__/$NAME/g" -e "s/__BUNDLE__/$BUNDLE/g" -e "s/__DISPLAY__/$(esc "$DISPLAY")/g" "$f"
  rm -f "$f.bak"
done
echo "$NAME ($BUNDLE) is ready in $DEST"
