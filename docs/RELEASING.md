# Native desktop releases

Repository: **hussnainahmedd/astra-3d-car-game-v2**, branch **main**.
Initial version: **v0.1.0**, prerelease quality.

## Repeatable update path

1. Develop within the existing Godot project. Run:
   ```bash
   ./run.sh --headless --editor --import --quit
   ./run.sh --headless --script res://qa/logic_tests.gd
   ./run.sh --headless --fixed-fps 60 -- --qa
   ```
2. Update `project.godot`'s `config/version`, the two Windows four-part version
   fields in `export_presets.cfg`, and current README/testing notes. The Windows
   build rejects inconsistent executable version metadata.
3. Review/stage source, assets, docs and packaging configuration; commit and push
   to V2 `origin/main`. Keep `.tools/`, `.godot/`, `builds/`, QA outputs and
   credentials excluded from Git.
4. Build Linux sequentially:
   ```bash
   ./tools/build_desktop.sh
   ./builds/linux-release/Astra-3D-Car-Game-V2.x86_64 --headless --quit-after 120 -- --sandbox --quickstart
   ```
   For independence checks, run the executable by absolute path from outside the
   project. Keep it beside its PCK. A short native graphical startup can be checked
   where supported; record VMware renderer blocks separately from script failures.
5. Dispatch **Windows desktop package** on `main`:
   ```bash
   gh workflow run windows-desktop.yml --repo hussnainahmedd/astra-3d-car-game-v2 --ref main
   gh run list --repo hussnainahmedd/astra-3d-car-game-v2 --workflow windows-desktop.yml
   gh run download RUN_ID --repo hussnainahmedd/astra-3d-car-game-v2 --name Astra-3D-Car-Game-V2-Windows-x64 --dir builds/releases
   ```
   Require a successful run and inspect `Windows-validation.txt`. The job verifies
   official toolchain hashes, x64 runtime/data, product metadata, Windows headless
   startup, silent installation, Start Menu shortcut, reinstallation, uninstall
   and user-data preservation. It does not test interactive 3D gameplay/audio.
6. Inspect archives and executable permissions/headers, and verify checksums.
   Combine the platform checksum records as `SHA256SUMS.txt` for publication.
   Include the MIT game license and Godot/bundled-library notices in both packages.
7. Check existing tags/releases. Use a new version; never replace a valid public
   release blindly. Tag the intended source commit and push the tag, then create
   a GitHub prerelease and attach the genuine ZIP, setup EXE, Linux archive,
   checksums and validation report. Use `gh`, secure existing authentication, and
   explicit `--repo hussnainahmedd/astra-3d-car-game-v2`.
8. Verify `HEAD == origin/main`, tag target, published prerelease status, expected
   asset names/sizes/digests and downloadable files. Ensure README/release notes
   distinguish executed checks from untested graphical gameplay.

The portable Linux archive is the initial distribution format; AppImage/DEB are
not required. Windows uses a real Inno Setup installer plus portable ZIP.
GitHub Releases provide update distribution; there is no automatic updater.

## Toolchain

- Exact editor: **4.3.stable.official.77dcf97d8** (official Godot 4.3 stable).
- Templates: official **4.3.stable**, pinned SHA-512 from the official release.
- Windows resource editor: **rcedit 2.0.0**, pinned SHA-256.
- Windows installer: **Inno Setup 6**, native `windows-latest` runner; exact
  compiler version is recorded in the release validation report.
- Packaging: Python standard library and existing native export presets.
