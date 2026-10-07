#!/usr/bin/env python3
"""Validate a native Godot export and package its runtime, notices and guide."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PRODUCT = "Astra 3D Car Game V2"
BASENAME = "Astra-3D-Car-Game-V2"


def digest(path):
    value = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def validate(executable, pack, platform):
    with executable.open("rb") as binary:
        header = binary.read(64)
        if platform == "linux":
            if header[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", header, 18)[0] != 62:
                raise SystemExit("The Linux runtime is not a genuine little-endian x86-64 ELF")
            if executable.stat().st_mode & 0o111 == 0:
                raise SystemExit("The Linux runtime is missing executable permissions")
        else:
            if header[:2] != b"MZ":
                raise SystemExit("The Windows runtime is not a genuine PE executable")
            binary.seek(struct.unpack_from("<I", header, 60)[0])
            pe = binary.read(26)
            if pe[:4] != b"PE\0\0" or struct.unpack_from("<H", pe, 4)[0] != 0x8664 or struct.unpack_from("<H", pe, 24)[0] != 0x20B:
                raise SystemExit("The Windows runtime is not an x64 PE32+ executable")
    with pack.open("rb") as source:
        header = source.read(20)
    if header[:4] != b"GDPC" or struct.unpack_from("<III", header, 8) != (4, 3, 0):
        raise SystemExit("The game data is not a Godot 4.3 PCK")
    if executable.stat().st_size < 1024 * 1024 or pack.stat().st_size < 1024:
        raise SystemExit("Runtime or data file is unexpectedly small")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("platform", choices=("linux", "windows"))
    parser.add_argument("--export-dir", type=Path)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "builds/releases")
    args = parser.parse_args()
    export = args.export_dir or ROOT / ("builds/" + args.platform + "-release")
    executable = export / (BASENAME + (".x86_64" if args.platform == "linux" else ".exe"))
    pack = export / (BASENAME + ".pck")
    validate(executable, pack, args.platform)
    notices = {"LICENSE": "LICENSE.game.txt", "THIRD_PARTY_NOTICES.md": "THIRD_PARTY_NOTICES.md",
               "third_party/godot/LICENSE.txt": "LICENSE.godot.txt",
               "third_party/godot/COPYRIGHT.txt": "COPYRIGHT.godot.txt", "docs/PLAYING.md": "PLAYING.md"}
    for source, target in notices.items():
        shutil.copyfile(ROOT / source, export / target)
    version = re.search(r'^config/version="([^"]+)"', (ROOT / "project.godot").read_text(), re.M).group(1)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    files = [executable, pack] + sorted(export.glob("*.dll")) + [export / target for target in notices.values()]
    info = {"product": PRODUCT, "version": version, "platform": args.platform + "-x64",
            "source_commit": commit, "engine": "4.3.stable.official.77dcf97d8",
            "export_templates": "official Godot 4.3.stable release templates",
            "sha256": {path.name: digest(path) for path in files}}
    manifest = export / "BUILD_INFO.json"
    manifest.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    files.append(manifest)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    folder = BASENAME + ("-Linux-x64" if args.platform == "linux" else "-Windows-x64")
    output = args.output_dir / (folder + (".tar.gz" if args.platform == "linux" else ".zip"))
    # Explicit file selection keeps caches, QA fixtures and stale exports out.
    if args.platform == "linux":
        with tarfile.open(output, "w:gz") as archive:
            for path in files:
                archive.add(path, arcname=folder + "/" + path.name)
        with tarfile.open(output) as archive:
            members = archive.getmembers()
            runtime = archive.getmember(folder + "/" + executable.name)
            assert runtime.mode & 0o111 and len(members) == len(files)
    else:
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in files:
                archive.write(path, arcname=folder + "/" + path.name)
        with zipfile.ZipFile(output) as archive:
            assert archive.testzip() is None and len(archive.namelist()) == len(files)
    checksum = args.output_dir / ("SHA256SUMS-" + args.platform.capitalize() + ".txt")
    checksum.write_text(digest(output) + "  " + output.name + "\n", encoding="utf-8")
    print("PASSED: genuine x64 runtime, Godot 4.3 PCK and archive structure")
    print(output, "(%d bytes)" % output.stat().st_size)


if __name__ == "__main__":
    main()
