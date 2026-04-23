#!/usr/bin/env bash
# Nine Forge — DMG packaging.
# Uses create-dmg if available, else falls back to hdiutil.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="build/macos/Build/Products/Release/nineforge.app"
DIST_DIR="dist"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: $APP_PATH not found. Run scripts/build.sh first." >&2
  exit 1
fi

VERSION=$(awk '/^version:/ { split($2, p, "+"); print p[1] }' pubspec.yaml)
if [[ -z "${VERSION:-}" ]]; then
  echo "ERROR: could not read version from pubspec.yaml" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
DMG_PATH="$DIST_DIR/NineForge-$VERSION.dmg"
rm -f "$DMG_PATH"

if command -v create-dmg >/dev/null 2>&1; then
  echo "=== step 1: create-dmg ==="
  create-dmg \
    --volname "Nine Forge" \
    --window-size 540 380 \
    --icon-size 96 \
    --app-drop-link 380 180 \
    --icon "nineforge.app" 160 180 \
    "$DMG_PATH" \
    "$APP_PATH"
else
  echo "=== step 1: hdiutil (create-dmg not installed; brew install create-dmg for prettier output) ==="
  hdiutil create \
    -volname "Nine Forge" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
fi

echo "=== dmg complete: $DMG_PATH ==="
