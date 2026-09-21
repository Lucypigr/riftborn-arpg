#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT_BIN:-godot4}"
"$GODOT_BIN" --headless --path "$(cd "$(dirname "$0")/.." && pwd)" --editor --quit
"$GODOT_BIN" --headless --path "$(cd "$(dirname "$0")/.." && pwd)" --script res://tests/combat_test.gd
