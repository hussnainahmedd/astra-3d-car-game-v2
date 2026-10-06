#!/usr/bin/env bash
set -euo pipefail
ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
ENGINE="${GODOT_BIN:-$ROOT/.tools/Godot_v4.3-stable_linux.x86_64}"
if [[ ! -x "$ENGINE" ]]; then
    printf 'Godot 4.3 is missing. Run: "%s/tools/install_engine.sh"\n' "$ROOT" >&2
    exit 1
fi
if [[ ! -f "$ROOT/.godot/global_script_class_cache.cfg" ]]; then
    "$ENGINE" --headless --editor --path "$ROOT" --import --quit
fi
exec "$ENGINE" --path "$ROOT" "$@"
