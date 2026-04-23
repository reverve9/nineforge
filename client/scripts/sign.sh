#!/usr/bin/env bash
# Nine Forge — Developer ID code signing.
# Signs the built .app with hardened runtime + entitlements and verifies.

set -euo pipefail

cd "$(dirname "$0")/.."

: "${NINEFORGE_SIGN_IDENTITY:?NINEFORGE_SIGN_IDENTITY not set. Expected: 'Developer ID Application: Your Name (TEAMID)'}"

APP_PATH="build/macos/Build/Products/Release/nineforge.app"
ENTITLEMENTS="scripts/entitlements/release.entitlements"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: $APP_PATH not found. Run scripts/build.sh first." >&2
  exit 1
fi

if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "ERROR: $ENTITLEMENTS not found." >&2
  exit 1
fi

echo "=== step 1: codesign ==="
codesign --deep --force --verify --options=runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$NINEFORGE_SIGN_IDENTITY" \
  "$APP_PATH"

echo "=== step 2: verify signature ==="
codesign -vv --deep --strict "$APP_PATH"

echo "=== sign complete ==="
