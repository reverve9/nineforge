#!/usr/bin/env bash
# Nine Forge — Apple Notarization.
# Zips the signed .app, submits to Apple notary, waits, and staples.

set -euo pipefail

cd "$(dirname "$0")/.."

: "${NINEFORGE_APPLE_ID:?NINEFORGE_APPLE_ID not set (Apple Developer account email)}"
: "${NINEFORGE_APP_SPECIFIC_PASSWORD:?NINEFORGE_APP_SPECIFIC_PASSWORD not set (appleid.apple.com app-specific password)}"
: "${NINEFORGE_TEAM_ID:?NINEFORGE_TEAM_ID not set (Apple Developer Team ID, 10 chars)}"

APP_PATH="build/macos/Build/Products/Release/nineforge.app"
ZIP_PATH="build/macos/Build/Products/Release/nineforge.zip"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: $APP_PATH not found. Run scripts/build.sh and scripts/sign.sh first." >&2
  exit 1
fi

echo "=== step 1: ditto zip ==="
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "=== step 2: notarytool submit (waits until done) ==="
set +e
xcrun notarytool submit "$ZIP_PATH" \
  --apple-id "$NINEFORGE_APPLE_ID" \
  --password "$NINEFORGE_APP_SPECIFIC_PASSWORD" \
  --team-id "$NINEFORGE_TEAM_ID" \
  --wait
NOTARY_STATUS=$?
set -e

if [[ $NOTARY_STATUS -ne 0 ]]; then
  echo "ERROR: notarization failed. To inspect logs:" >&2
  echo "  xcrun notarytool log <submission-id> --apple-id \"\$NINEFORGE_APPLE_ID\" --password \"\$NINEFORGE_APP_SPECIFIC_PASSWORD\" --team-id \"\$NINEFORGE_TEAM_ID\"" >&2
  exit "$NOTARY_STATUS"
fi

echo "=== step 3: staple ==="
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "=== notarize complete ==="
