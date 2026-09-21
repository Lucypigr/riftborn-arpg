#!/usr/bin/env bash
# Installs the exact editor used by BUILD 001 into a local tools directory.
set -euo pipefail
VERSION="4.3-stable"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/.tools/godot-$VERSION"
ARCHIVE="${TMPDIR:-/tmp}/Godot_v4.3-stable_linux.x86_64.zip"
mkdir -p "$DEST"
curl --fail --location --retry 3 \
  "https://github.com/godotengine/godot/releases/download/$VERSION/Godot_v4.3-stable_linux.x86_64.zip" \
  --output "$ARCHIVE"
unzip -q -o "$ARCHIVE" -d "$DEST"
mv "$DEST/Godot_v4.3-stable_linux.x86_64" "$DEST/godot4"
"$DEST/godot4" --version
printf 'Run tests with: GODOT_BIN=%q ./scripts/test.sh\n' "$DEST/godot4"
