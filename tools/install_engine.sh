#!/usr/bin/env bash
# Optional development dependency bootstrap; the Phase 1 portable game needs none of this.
set -euo pipefail
ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
mkdir -p "$ROOT/.tools"
ARCHIVE="$ROOT/.tools/godot-4.3-linux.zip"
curl -L --fail --retry 2 \
    'https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip' \
    -o "$ARCHIVE"
unzip -o "$ARCHIVE" -d "$ROOT/.tools"
chmod +x "$ROOT/.tools/Godot_v4.3-stable_linux.x86_64"
"$ROOT/.tools/Godot_v4.3-stable_linux.x86_64" --version
