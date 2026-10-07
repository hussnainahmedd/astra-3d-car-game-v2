# RoadShift verification

RoadShift uses the existing **Godot 4.3 stable** validation suites and native
desktop packaging checks. Keep logic/physics results, native startup and full
graphical playtesting as distinct coverage levels.

## Run the source suites

```bash
./run.sh --headless --editor --import --quit
./run.sh --headless --script res://qa/logic_tests.gd
./run.sh --headless --fixed-fps 60 -- --qa
```

Reports are written to `qa/latest_logic_report.json` and
`qa/latest_headless_report.json`. Failures produce nonzero exit codes.
The suites use only dedicated `qa_logic_progress.json` / `qa_progress.json` slots
and skip personal settings writes; logic fixtures are cleaned up after the run.

### Logic/rule/persistence coverage

- Idempotent keyboard actions, renderer configuration and export preset presence.
- Actual engine user-data-directory preservation through product-name changes.
- Valid v2 saves, numeric/fractional version handling, v1 migration, bounded fields,
  backups, corrupt-primary fallback and unreadable-file preservation.
- Settings defaults, bounded array indices, non-finite inputs and QA write isolation.
- Career thresholds, one-time milestones, locked/owned/unaffordable purchases.
- All **30 directed business-to-business road routes**, with explicit driveway
  attachments and legal internal road legs; rotating offers from all six origins.
- Cargo loading/mass/restore/damage, priority/late payments, cancellation and
  duplicate-payment rejection.
- Fuel/condition effects, service quotes, upgrade effects, emergency fuel and mileage.

### Physics/input/UI coverage

- Main menu and real Play-button activation; four-wheel suspension settling.
- Actual acceleration, steering, braking, reverse, handbrake, collisions and damage.
- Lights, chase/close/bonnet cameras and recovery.
- Dispatch acceptance, stationary held interaction, physical cargo load/unload.
- A complete **depot-to-Northline-Works delivery driven with actual rigid-body
  simulation**, without teleporting the delivery journey; wallet/payment checks.
- All six business-bay exits plus Coast Service, physically driven with loaded cargo.
- Traffic movement, stopped-player following, obstruction clearing and red/green stops.
- Map/workshop/service routing, remote-service rejection and UI upgrade purchases.
- Save round-trips, mileage/clock/upgrades, graphics settings, invert-Y, pause,
  settings return, resume, night, main-menu freeze and continue.

## Desktop package validation

`tools/package_desktop.py` validates the genuine **x86-64 ELF / PE32+** runtime
and **Godot 4.3 PCK**, nontrivial file sizes, Linux executable permissions and
archive structure/CRC. Packages include the guide and engine/game notices plus
`BUILD_INFO.json` with product, version, source commit and hashes.

The Windows workflow also checks stamped **RoadShift** product/version resources,
generates the icon from the SVG, compiles the real Inno Setup installer, and runs
portable/installed headless startup from outside the source tree. Its disposable
runner checks installation, Start Menu shortcuts, reinstallation, uninstall and
user-data preservation. Actual outcomes and compiler version are attached as
`Windows-validation.txt`.

Linux release smoke commands, using isolated saves:

```bash
./builds/linux-release/RoadShift.x86_64 --headless --quit-after 120 -- --sandbox --quickstart
./builds/linux-release/RoadShift.x86_64 --quit-after 60 -- --sandbox --quickstart
```

Use absolute executable paths from a temporary directory outside the project,
and repeat the headless smoke against a separately extracted portable archive.
Record launch exit status and log errors in `Linux-validation.txt`.
`tools/release_checksums.py` verifies records and normalizes release checksums
to LF for standard SHA-256 verification on both platforms.

## Release records

### RoadShift v0.1.1 source checks — 2026-10-07

| Executed check | Result |
|---|---|
| Headless editor import / scene/resource/script parsing | **PASSED** |
| Existing rule/persistence suite, including profile-path preservation | **79 / 79 PASSED** |
| Existing physical driving/input/UI integration | **64 / 64 PASSED** |
| Shell syntax and Python packaging-script compilation | **PASSED** |
| Actionlint workflow validation | **PASSED** |
| Local RoadShift desktop-entry validation | **PASSED** |
| Installer icon generation from the RoadShift SVG | **PASSED** |
| RoadShift product/version, entry scene, native preset metadata and profile compatibility | **PASSED** |

The source integration completed the physical delivery and raised the wallet
from $650 to $956. Gameplay assertions and profile data remained valid after the
identity/output-name changes. Desktop-export outcomes belong to the per-release
platform records below, separately from source checks.

The **v0.1.0** release validation recorded **79/79 logic** and **64/64 headless
integration** checks, successful Linux export/extracted/headless/native startup,
and successful Windows export/headless/installer-lifecycle checks. Inno Setup
**6.7.1** was confirmed from the compiler output. Historical release records
remain available through the archived release rather than being overwritten.

RoadShift **v0.1.1** repeats source and desktop validation after metadata, UI,
icon and output-name changes. Current executed outcomes are recorded in its
published platform validation files; a successful build does not imply a full
interactive graphical playtest.

## Rendered checks and limitations

Where native graphics are available:

```bash
./run.sh -- --qa --qa-visual
./run.sh -- --visual-probe
```

The rendered integration writes `qa/latest_visual_report.json` and screenshots;
the headless renderer omits audio playback and purely visual destination/water
geometry. Do not classify a headless run as an audio or image-quality test.

Historical **2026-10-06** native X11/OpenGL Compatibility integration passed
**64/64** checks on Ubuntu 20.04 x64, Mesa 21.2.6 and VMware SVGA3D. At 960 × 540,
the final expanded run sampled **27.3 FPS average**, **35.2 ms median frame** and
**50.0 ms 95th-percentile frame**. The delivery took about 39 seconds, arrived
2.9 m from the bay and paid $306. These are prior-session measurements, not a
new RoadShift release benchmark or target-hardware guarantee.

Earlier central-street quality samples on that VM:

| Quality | Average FPS | Median frame | 95th percentile |
|---|---:|---:|---:|
| VM Low | 30.5 | 31.9 ms | 37.5 ms |
| Balanced | 27.6 | 35.0 ms | 48.2 ms |
| High | 11.5 | 81.7 ms | 144.0 ms |

**NOT TESTED:** extended rendered release play, interactive Windows graphics/audio,
every complete delivery permutation, long multi-shift play and broad hardware
compatibility. VMware limits representative GPU/performance validation. A short
native startup verifies initialization, not prolonged gameplay. Record genuine
renderer/environment blocks separately from parsing/export/logic failures and
avoid repeatedly launching a failing graphics test.
