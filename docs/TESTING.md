# Verification

## Initial release source validation — 2026-10-07, v0.1.0

Recovery found a clean, synchronized `main` at `bbb3f89`, with completed gameplay,
the older Linux development bundle, no release templates, no workflow, and no
existing tags/releases. The existing project was continued in place.

| Executed check | Result |
|---|---|
| Headless editor import / script parsing | **PASSED** |
| Existing logic/rule/persistence suite, plus profile-path preservation | **79 / 79 PASSED** |
| Existing physical driving/input/UI/delivery integration | **64 / 64 PASSED** |
| Shell syntax for source/development/Linux build scripts | **PASSED** |
| Installer icon generation from the original SVG | **PASSED** |

The integration physically drives loaded cargo to Northline Works, unloads it,
and increases the wallet from **$650 to $956**. It exercises all seven loaded
bay exits, traffic, maps/workshop, upgrades, save round-trips, settings and menus.
The logic suite validates all 30 directed business routes, career milestones,
payments, cargo, fuel/damage, save migration and corrupt-save fallback.

The product rename preserves `godot/app_userdata/Harborline Dispatch`; the added
regression check verifies the actual engine user-data directory. Personal saves
and settings are not modified by QA.

### Desktop release checks

The packaging scripts fail on invalid executable/PCK headers, missing data,
incorrect permissions, failed archive checks or failed native export commands.
Windows build/lifecycle results are attached to each published release as
`Windows-validation.txt`, including the actual source commit and compiler version.

Windows graphical gameplay/audio and prolonged target-hardware play are **NOT
TESTED** by headless startup. Historical native rendered results below are prior
evidence, not newly executed release-template gameplay checks.
The historical browser WebGL2 test remains **BLOCKED BY VMWARE GPU ENVIRONMENT**;
it is not retried and is not the rendering API of this native release.

## Historical continuation — 2026-10-06, internal preview v0.2.0

Tested with the existing Godot 4.3 stable engine on Ubuntu 20.04 x64 / VMware.

| Check | Result |
|---|---|
| Headless logic/rule/persistence suite | **78 / 78 passed** |
| Expanded headless physics/input/UI integration | **64 / 64 passed** |
| Native X11 / OpenGL Compatibility visual integration | **64 / 64 passed** |
| Linux development bundle build + external-directory headless/native startup | **Passed** |
| Packaged source-only QA flag guard | **Passed; clear message, expected exit 2** |
| Browser WebGL2 context test | **Environment-blocked; not retried** |

Commands from the project directory:

```bash
./run.sh --headless --editor --import --quit
./run.sh --headless --script res://qa/logic_tests.gd
./run.sh --headless --fixed-fps 60 -- --qa
./run.sh -- --qa --qa-visual
```

Reports: `qa/latest_logic_report.json`, `qa/latest_headless_report.json` and
`qa/latest_visual_report.json`. Tests use only `qa_logic_progress.json` and
`qa_progress.json` (and their QA backups), and skip personal settings writes.
The logic suite cleans up its disk fixtures. Test failures return a nonzero exit.
`qa/environment_status.json` records the browser block and actual native/bundle
results separately.

### Newly exercised coverage

- v2 JSON numeric-version acceptance, v1 migration, good-save backup, corrupt
  primary recovery/preservation, invalid versions and bounded data/settings.
- All career thresholds, one-time milestone rewards, locked/owned/unaffordable
  purchases, payload restore/unload, cargo damage, upgrade effects and late pay.
- Full/fuel-only/repair-only quotes, emergency fuel, empty-tank thrust inhibition,
  condition power reduction and odometer double-count prevention.
- All **30 directed business-to-business road routes** and rotating offers from
  all six origins, including explicit road legs between virtual driveway
  attachments. These validate route logic, not 30 automated driving journeys.
- Actual four-wheel parking and driving out of **all six business bays and Coast
  Service**, carrying 220 kg. Repositioning sets up these isolated bay fixtures;
  each exit itself is physically driven.
- Stopping behind the player without overlap, resuming after obstruction clears,
  stopping at a red crossing and starting on green.
- M map / G workshop, service route/restore buttons, remote-service rejection,
  actual UI upgrade purchase, locked upgrades, saved mileage/clock/upgrade,
  invert-Y wiring, and main-menu traffic/clock freeze.
- The original complete depot-to-workshop delivery still uses real physics and
  driving input throughout the trip, without teleporting to its destination.

### Rendered observations

The native engine successfully initialized **OpenGL 3.3 Core / Mesa 21.2.6 /
VMware SVGA3D**, with the Compatibility renderer. Current screenshots include
the seven original menu/driving/night views plus `08-district-map.png` and
`09-workshop.png`; HUD, dispatch, map, workshop and settings were inspected.

The final 2026-10-06 rendered integration rerun sampled **27.3 FPS average**,
**35.2 ms median frame** and **50.0 ms 95th-percentile frame**, with a 960 × 540
window and default Balanced quality. It reported 144 draw calls and 413 objects
at the end.
This is a VM measurement, not a controlled before/after benchmark.
Frames of 0.5 seconds or more are excluded from those samples as before.

The physical delivery took about **39.0 seconds**, arrived **2.9 m** from the bay
center and paid **$306** ($231 base plus $75 bonuses). Traffic's stopped-player
fixture settled at **0 m/s** with a **7.9 m center-to-center gap**. All seven loaded
bay exits passed.

No script errors, renderer initialization failures or shutdown leaks were reported.
Ubuntu's older `libxkbcommon` printed two optional-symbol lookup messages on stderr
(`xkb_utf32_to_keysym`, `xkb_keymap_key_get_mods_for_level`). These messages did not
prevent initialization or the input/UI checks; they are not a WebGL failure.

### Specifically environment-blocked

The reported browser failure remains:

```text
THREE.WebGLRenderer: A WebGL context could not be created.
WebGL 2 requires support for transform_feedback2.
Error creating WebGL context.
```

It was not relaunched or repeatedly investigated. The inspected project contains
no Three.js/WebGL2 initialization. Native OpenGL rendering **was available** and
was tested once successfully. See `ARCHITECTURE.md` for the rendering boundary.

### Refreshed standalone Linux development bundle

`./tools/build_phase1.sh` imported the project and packed 25 runtime files into
the updated PCK. `file` confirmed the runtime is a genuine x86-64 ELF executable.
The refreshed bundle launched successfully both headless and in an X11/OpenGL
window with its working directory set to `/tmp/omnirush`, without `run.sh`, the
source project as its runtime path, or a separately launched engine/server.

Reproduction commands (the sandbox flag protects personal progress/settings):

```bash
./builds/phase1-linux/Harborline --headless --quit-after 120 -- --sandbox --quickstart
./builds/phase1-linux/Harborline --quit-after 90 -- --sandbox --quickstart
```

Both exited 0. The packaged `--qa` flag was also checked: it reported that the
test requires the source project and exited 2, without a null-instance failure.
The game and its adjacent PCK are the runtime; the package is still a development
preview, not a release-template export or installer. Shell syntax checks for
`run.sh`, `tools/build_phase1.sh` and `tools/install_engine.sh` passed.

### Remaining verification

User listening/handling review, long multi-shift play on target hardware, additional
full delivery journeys, Windows runtime, release-template exports and installers
remain outstanding. Historical measurements below are retained as prior-session
evidence, rather than presented as today's results.

## Historical Phase 1 verification — 2026-10-04

Tested on 2026-10-04 with Godot 4.3 stable on Ubuntu 20.04 x64 in VMware.

## Final integration results

- **Headless integration run: 37 / 37 checks passed.**
- **Rendered X11/OpenGL integration run: 37 / 37 checks passed.**
- Final runs completed with no script errors, engine errors, or shutdown leaks
  in their logs.
- The self-contained native ELF/PCK bundle was also launched with its working
  directory outside the project, and closed normally.

Machine-readable reports:

- `qa/latest_headless_report.json`
- `qa/latest_visual_report.json`

Reproduction commands, from the source project directory:

```bash
./run.sh --headless --fixed-fps 60 -- --qa
./run.sh -- --qa --qa-visual
```

Both use the isolated `qa_progress.json` save slot. They do not alter the
player's `progress.json` or settings.

## What the integration run exercises

1. Constructs the main menu and activates Play through its actual Button signal.
2. Settles the van's suspension on four wheels.
3. Applies acceleration input for three seconds on a clear road.
4. Checks displacement and speed, then checks steering, braking, reverse and
   handbrake behavior using real rigid-body simulation.
5. Drives into the depot building and checks physical obstruction and damage.
6. Toggles lights, cycles close/bonnet/chase cameras, and recovers the vehicle.
7. Opens the dispatch board and accepts the workshop contract through the UI.
8. Verifies that an active contract prevents accepting a second one.
9. Sends an E key-down/up interaction to load cargo at the depot.
10. Steers and accelerates the physical van along a waypoint course to Northline
    Works, with normal traffic running. **No teleport occurs during this trip.**
11. Stops in the destination zone, sends the E interaction, verifies completion,
    and checks that the wallet increases.
12. Checks fuel use, next-job origins, a route that must avoid cutting through a
    block, and traffic circulation.
13. Visits a service fixture, applies damage/fuel deficits, and verifies the
    advertised service price against the resulting wallet and vehicle state.
14. Writes and reloads the local save.
15. Switches graphics quality and verifies shadow settings.
16. Checks that pause freezes the van, opens settings, returns to pause,
    resumes, changes to night, returns to the main menu, and continues again.
17. Quits cleanly.

Recovery/repositioning is used to set up isolated control/collision/service
fixtures. It is not used to fake the delivery journey. The automated driver
supplies throttle, steering and brake requests to the same physics controller
used during normal play.

## Recorded outcomes

| Observation | Final rendered run |
|---|---:|
| Speed after 3 seconds accelerating | 27.3 km/h |
| Distance during acceleration fixture | 12.0 m |
| Steering heading change | 0.292 rad |
| Reverse velocity | −3.54 m/s |
| Handbrake stopping speed | 0.7 km/h |
| Condition after building impact | 90.1% |
| Workshop arrival | 3.0 m from zone center |
| Automated delivery driving time | 38.6 seconds |
| Complete delivery reward | $261 |
| Wallet after delivery | $650 → $911 |
| Fuel after driving/test fixtures | 98.5% |
| Refuel/repair charge for test deficits | $63 |
| Mean sampled rendered frame rate | 26.7 FPS |
| Median sampled rendered frame time | 35.3 ms |
| 95th-percentile sampled frame time | 51.5 ms |

The frame-time samples cover unpaused play and include view changes. Long
initialization/screenshot stalls of 0.5 seconds or more are excluded from that
average. The `end_fps` field is an instantaneous reading immediately following
menu/screenshot operations and is not a meaningful benchmark by itself.

Timed central-street samples from `qa/visual_probe.gd` at 960 × 540:

| Quality | Average FPS | Median frame | 95th percentile |
|---|---:|---:|---:|
| VM Low | 30.5 | 31.9 ms | 37.5 ms |
| Balanced | 27.6 | 35.0 ms | 48.2 ms |
| High | 11.5 | 81.7 ms | 144.0 ms |

These measurements describe this VM and these viewpoints. Night, driver shader
compilation, other VM workloads and larger windows can reduce performance.

## Rendered review

The rendered test saves these current screenshots to `qa/screenshots/`:

- `01-main-menu.png`
- `02-contract-board.png`
- `03-driving.png`
- `04-delivered.png`
- `05-pause.png`
- `06-settings.png`
- `07-night.png`

Lighting, vehicle geometry, HUD layout, loading indicators, menus and night
presentation were inspected from rendered output. Initial overexposure,
excessive draw calls, a body-mesh index mismatch and a route-graph shortcut
through blocks were corrected during development.

The Godot physics pause/resume diagnostic was traced to changing pause state
at an unsafe point between physics query flush and stepping. All pause changes
now go through the always-processing composition root's idle update. Final
headless and rendered tests have clean logs.

## Native desktop smoke check

The Phase 1 bundle was started from `/tmp/omnirush`, using only the absolute
path to `builds/phase1-linux/Harborline`. Godot found the adjacent PCK and opened
the game directly. X11 keyboard events were sent for menu selection, dispatch,
E interaction, W/D driving, handbrake, camera, lights, pause/resume and window
close. The runtime log remained clean.

## Remaining QA scope

The full automated delivery course currently covers the depot-to-workshop
contract. All destinations exist with drivable access, but every possible
origin/destination permutation has not been driven automatically. Audio is
generated and played by native audio players; subjective sound quality needs
the user's listening test. Windows runtime, release-template exports and
installer behavior await Phase 2 and clean-machine testing.
