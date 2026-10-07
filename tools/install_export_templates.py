#!/usr/bin/env python3
"""Install only the official Godot 4.3 stable desktop release templates."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.3.stable"
ARCHIVE_NAME = "Godot_v4.3-stable_export_templates.tpz"
URL = "https://github.com/godotengine/godot-builds/releases/download/4.3-stable/" + ARCHIVE_NAME
# Published in the official 4.3-stable SHA512-SUMS.txt.
SHA512 = "476366caf0fd45a8f24136cf9cf1dc0bc2b96f7c82d53e5f82200b55aefd07b286d283fd6f1ce29e0de70648c5a51d3b12f96c6d4fafd4e8c4878ecda6406d6a"


def digest(path):
    result = hashlib.sha512()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", choices=("linux", "windows", "all"), default="all")
    args = parser.parse_args()
    tools = ROOT / ".tools"
    tools.mkdir(exist_ok=True)
    archive = tools / ARCHIVE_NAME
    if not archive.exists():
        partial = archive.with_suffix(".tpz.part")
        print("Downloading official Godot 4.3 stable templates...", flush=True)
        curl = shutil.which("curl.exe") if os.name == "nt" else shutil.which("curl")
        if not curl:
            raise SystemExit("curl is required to download the official templates")
        subprocess.run([curl, "--fail", "--location", "--retry", "2", "--silent",
                        "--show-error", URL, "--output", str(partial)], check=True)
        if digest(partial) != SHA512:
            raise SystemExit("Template checksum mismatch; the download was preserved for inspection")
        partial.replace(archive)
    if digest(archive) != SHA512:
        raise SystemExit("Template checksum mismatch; refusing to install")
    if os.name == "nt":
        data_home = Path(os.environ["APPDATA"])
    else:
        data_home = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    destination = data_home / "godot/export_templates" / VERSION
    destination.mkdir(parents=True, exist_ok=True)
    files = ["version.txt"]
    if args.platform in ("linux", "all"):
        files.append("linux_release.x86_64")
    if args.platform in ("windows", "all"):
        files.append("windows_release_x86_64.exe")
    with zipfile.ZipFile(archive) as source:
        if source.read("templates/version.txt").decode().strip() != VERSION:
            raise SystemExit("Template version does not match Godot 4.3 stable")
        for name in files:
            target = destination / name
            with source.open("templates/" + name) as original, target.open("wb") as output:
                shutil.copyfileobj(original, output)
            target.chmod(0o755 if name != "version.txt" else 0o644)
            print("Installed:", target)
    print("PASSED: official SHA-512 checksum and exact template version")


if __name__ == "__main__":
    main()
