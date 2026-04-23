#!/usr/bin/env bash
# Nine Forge — one-shot release pipeline: build → sign → notarize → dmg.
# Any stage failure aborts subsequent stages.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== release: build ==="
scripts/build.sh

echo "=== release: sign ==="
scripts/sign.sh

echo "=== release: notarize ==="
scripts/notarize.sh

echo "=== release: dmg ==="
scripts/dmg.sh

echo "=== release pipeline complete ==="
