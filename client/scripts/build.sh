#!/usr/bin/env bash
# Nine Forge — macOS release build.
# Cleans, resolves deps, and builds the .app with --dart-define injection.

set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE=".env.dart-define.json"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Create it with SUPABASE_URL and SUPABASE_ANON_KEY." >&2
  exit 1
fi

echo "=== step 1: flutter clean ==="
flutter clean

echo "=== step 2: flutter pub get ==="
flutter pub get

echo "=== step 3: build_runner ==="
dart run build_runner build --delete-conflicting-outputs

echo "=== step 4: flutter build macos --release ==="
flutter build macos --release --dart-define-from-file="$ENV_FILE"

APP_PATH="build/macos/Build/Products/Release/nineforge.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: build output $APP_PATH not found." >&2
  exit 1
fi

echo "=== build complete: $APP_PATH ==="
