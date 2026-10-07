#!/usr/bin/env python3
"""Verify platform checksum records and create one LF-only release checksum file."""
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "builds/releases"


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def main():
    records = {}
    for platform in ("Linux", "Windows"):
        record = OUTPUT / ("SHA256SUMS-" + platform + ".txt")
        normalized = []
        for line in record.read_text(encoding="utf-8-sig").splitlines():
            expected, name = line.split(None, 1)
            if Path(name).name != name or digest(OUTPUT / name) != expected:
                raise SystemExit("FAILED: release checksum for " + name)
            records[name] = expected
            normalized.append(expected + "  " + name)
        with record.open("w", encoding="utf-8", newline="\n") as target:
            target.write("\n".join(normalized) + "\n")
    for name in ("Windows-validation.txt", "Linux-validation.txt"):
        if (OUTPUT / name).exists():
            records[name] = digest(OUTPUT / name)
    with (OUTPUT / "SHA256SUMS.txt").open("w", encoding="utf-8", newline="\n") as target:
        for name, checksum in sorted(records.items()):
            target.write(checksum + "  " + name + "\n")
    print("PASSED: platform checksums verified; LF-only SHA256SUMS.txt created")


if __name__ == "__main__":
    main()
