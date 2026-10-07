#!/usr/bin/env bash
# Official Linux x64 release-template export and portable archive.
set -euo pipefail
ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
ENGINE="${GODOT_BIN:-$ROOT/.tools/Godot_v4.3-stable_linux.x86_64}"
if [[ ! -x "$ENGINE" ]]; then
    printf 'Run tools/install_engine.sh first.\n' >&2
    exit 1
fi
if [[ "$("$ENGINE" --version)" != "4.3.stable.official.77dcf97d8" ]]; then
    printf 'This release requires official Godot 4.3 stable and matching templates.\n' >&2
    exit 1
fi
OUTPUT="$ROOT/builds/linux-release"
mkdir -p "$OUTPUT"
python3 "$ROOT/tools/install_export_templates.py" --platform linux
"$ENGINE" --headless --editor --path "$ROOT" --import --quit
"$ENGINE" --headless --path "$ROOT" --export-release "Linux x64" "$OUTPUT/RoadShift.x86_64"
chmod +x "$OUTPUT/RoadShift.x86_64"
python3 "$ROOT/tools/package_desktop.py" linux
