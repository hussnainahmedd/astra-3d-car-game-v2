# RoadShift desktop releases

Current repository: **hussnainahmedd/astra-3d-car-game-v2**, branch **main**.
The current repository location remains authoritative until its owner renames it.
RoadShift uses **v0.1.1** for the naming/documentation update; **v0.1.0** remains
an archived, working prerelease.

## Repeatable release path

1. Develop within the existing Godot project, then run:
   ```bash
   ./run.sh --headless --editor --import --quit
   ./run.sh --headless --script res://qa/logic_tests.gd
   ./run.sh --headless --fixed-fps 60 -- --qa
   ```
2. Set `project.godot`'s `config/version` and the matching four-part Windows
   version fields in `export_presets.cfg`. Update current player/release notes.
   Keep save format v2 and its profile directory independent of release versions.
3. Review source, assets, docs and packaging changes, then commit/push to
   `origin/main`. Keep `.tools/`, `.godot/`, generated packages, QA reports and
   credentials excluded. Verify local HEAD equals `origin/main`.
4. Export and package Linux:
   ```bash
   ./tools/build_desktop.sh
   ./builds/linux-release/RoadShift.x86_64 --headless --quit-after 120 -- --sandbox --quickstart
   ```
   Test the absolute executable path and extracted archive from a working
   directory outside the source checkout. Use sandbox saves for smoke checks.
5. Dispatch the native Windows workflow:
   ```bash
   gh workflow run windows-desktop.yml --repo hussnainahmedd/astra-3d-car-game-v2 --ref main
   gh run list --repo hussnainahmedd/astra-3d-car-game-v2 --workflow windows-desktop.yml
   gh run download RUN_ID --repo hussnainahmedd/astra-3d-car-game-v2 --name RoadShift-Windows-x64 --dir builds/releases
   ```
   Require success and inspect `Windows-validation.txt`. It records the actual
   source commit and installer compiler version, plus runtime and installation
   results. The workflow's isolated fixtures validate portable/installed headless
   startup, installation, Start Menu, reinstallation, uninstall and saved-data
   preservation; they do not test interactive graphics/audio.
6. Verify genuine x64 ELF/PE/PCK files, archive structure, Linux permissions,
   RoadShift naming and per-package provenance. Record Linux startup results in
   `Linux-validation.txt`, then run:
   ```bash
   python3 tools/release_checksums.py
   ```
   This verifies platform checksum records and creates LF-only `SHA256SUMS.txt`.
7. Check existing tags/releases and select a new semantic version. Tag the intended
   source commit, push the tag, and create a GitHub prerelease with concise player
   instructions and actual test status. Upload:
   - `RoadShift-Setup-Windows-x64.exe`
   - `RoadShift-Windows-x64.zip`
   - `RoadShift-Linux-x64.tar.gz`
   - `SHA256SUMS.txt`, `Windows-validation.txt` and `Linux-validation.txt`
   Use the GitHub CLI with existing secure authentication and the current repository.
   Preserve previous working releases and their assets.
8. Verify repository, source/tag targets, public prerelease status, asset names,
   nonzero sizes, uploaded digests and anonymous download access. Confirm README,
   release notes and artifact manifests match the published version.

The supported Linux format is the native portable tar.gz; Windows uses a portable
ZIP and a real Inno Setup installer. GitHub Releases provide update distribution.

## Toolchain

- Editor: official **4.3.stable.official.77dcf97d8**.
- Templates: official **4.3.stable**, archive SHA-512 pinned in the installer utility.
- Windows resource editor: **rcedit 2.0.0**, SHA-256 pinned in the Windows build script.
- Windows installer: **Inno Setup 6**; the hosted compiler version is recorded in
  each validation report. The configured absent-tool fallback is 6.4.3.
- CI: `windows-latest`, Python 3.12, native PowerShell build stages and artifact upload.
- Packaging: Python standard library; Bash for Linux orchestration.

Every package includes the MIT game license, Godot/bundled-library notices and
the playing guide. Build manifests record product, version, source commit and
file hashes. The installer keeps a stable application ID for update continuity;
user data is outside its installation directory.
