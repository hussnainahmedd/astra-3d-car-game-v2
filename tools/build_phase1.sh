#!/usr/bin/env bash
# A self-contained Linux development bundle. No installer or export templates needed.
set -euo pipefail
ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
ENGINE="${GODOT_BIN:-$ROOT/.tools/Godot_v4.3-stable_linux.x86_64}"
OUTPUT="$ROOT/builds/phase1-linux"
if [[ ! -x "$ENGINE" ]]; then
    printf 'Godot 4.3 is missing. Run: "%s/tools/install_engine.sh"\n' "$ROOT" >&2
    exit 1
fi
mkdir -p "$OUTPUT"
"$ENGINE" --headless --editor --path "$ROOT" --import --quit
"$ENGINE" --headless --path "$ROOT" --script res://tools/make_pack.gd
install -m 755 "$ENGINE" "$OUTPUT/Harborline"
install -m 644 "$ROOT/LICENSE" "$OUTPUT/LICENSE.game.txt"
install -m 644 "$ROOT/THIRD_PARTY_NOTICES.md" "$OUTPUT/THIRD_PARTY_NOTICES.md"
install -m 644 "$ROOT/third_party/godot/LICENSE.txt" "$OUTPUT/LICENSE.godot.txt"
install -m 644 "$ROOT/third_party/godot/COPYRIGHT.txt" "$OUTPUT/COPYRIGHT.godot.txt"
install -m 644 "$ROOT/docs/PLAYING.md" "$OUTPUT/PLAYING.md"
printf '\nPlayable native Linux bundle:\n  %s/Harborline\n' "$OUTPUT"
