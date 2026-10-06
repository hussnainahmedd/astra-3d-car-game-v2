# Astra 3D Car Game V2

**WORK IN PROGRESS / ACTIVE DEVELOPMENT**

This repository is the dedicated development repository for the second Astra 3D
car-game project. The running game is currently named **Harborline Dispatch** in
`project.godot` and is at version **0.2.0**. It is a native, offline 3D driving
and delivery game for desktop; this upload is a source-code backup during active
development, not a finished game or final release.

Version 0.2 is a playable Ubuntu development preview: drive a delivery van around a
compact harbor district, take contracts, collect cargo, deliver it, and earn money.
The art direction is deliberately stylized and understated, with original
procedural assets. The handling uses a weighted physical vehicle; this is not a
photorealistic or full-scale commercial truck simulator.

**Current architecture:** Godot 4.3 / GDScript / native OpenGL Compatibility.
This project does not contain Three.js, npm, Vite or a localhost
game server. [Architecture and desktop delivery](docs/ARCHITECTURE.md) documents
the real Windows/Linux standalone path and the earlier VMware WebGL2 limitation.
[Continuation status](docs/PROGRESS.md) records completed and remaining work.

## Play now

### Existing local Ubuntu development bundle

The generated bundle is intentionally excluded from Git. If it already exists
in this working directory, it can be launched with:

```bash
./builds/phase1-linux/Harborline
```

Or use **Harborline Dispatch** on the Ubuntu desktop.

Keep `Harborline` and `Harborline.pck` together. The entire
`builds/phase1-linux/` folder can be moved elsewhere. Playing this bundle does
not require the source project, a separately installed engine, OmniRush, a web
browser, an account, or an Internet connection. Normal Linux graphics/audio
drivers and OpenGL 3.3 support are required.

### Source/development version

```bash
./run.sh
```

The launcher uses the downloaded Godot executable in `.tools/`. To edit the
project with the native Godot editor:

```bash
./run.sh --editor
```

If recreating the development environment, run `./tools/install_engine.sh` first.
This needs `curl` and `unzip`. No root access, .NET, Node.js, Python packages, or
asset downloads are needed to build the game itself.

## Your first shift

1. Choose **Start your shift**.
2. Press **J**. Accept the **Northline Works** contract.
3. The van starts inside the depot loading bay. **Hold E** for about two seconds
   while stopped to load the cargo.
4. Pull out west to the road, turn right, and head north. Follow the amber route
   on the map. The destination arrow and distance also update as you drive.
5. Turn into the workshop bay on the right before the far intersection.
6. Stop inside the amber ring and **hold E** to complete the delivery.
7. Your balance increases. Press **J** for another contract; nearby businesses
   offer outbound jobs, so you can keep working without returning to the depot.

Jobs do not fail because you take too long. Careful, on-time driving earns up
to $75 extra. The first workshop contract pays $186 base plus bonuses.
Career ranks unlock fragile and priority work; priority bonuses can total $105.
Milestone rewards add another one-time payment at 3, 8 and 15 deliveries.

See [the quick-start guide](docs/PLAYING.md) for a compact control reference.

## Controls

| Action | Input |
|---|---|
| Accelerate | **W / Up Arrow** |
| Brake, then reverse after stopping | **S / Down Arrow** |
| Steer | **A/D / Left/Right Arrow** |
| Handbrake | **Space** |
| Headlights | **H** |
| Cycle chase / close chase / bonnet cameras | **C** |
| Look around; release to recenter | **Right mouse button + mouse** |
| Recover upright to a nearby road lane | **R** |
| Pause / back / resume | **Esc** |
| Dispatch board | **J** |
| District map / business progress | **M** |
| Workshop / split service / upgrades | **G** |
| Load / hand over cargo, below 2 km/h | **Hold E** |
| Refuel + repair at Coast Service, below 2 km/h | **E** |
| Cycle afternoon / sunset / night | **N** |
| Fullscreen | **F11** |
| Performance and wheel-contact display | **F3** |

Keyboard actions are centralized in `scripts/core/input_bindings.gd`, ready for
a future rebinding interface. Mouse sensitivity and invert-Y have working settings.

## Implemented systems

- **Vehicle:** 1,750 kg rigid body, four raycast springs, damping, load-limited
  lateral and longitudinal tire forces, rear drive, aerodynamic/rolling drag,
  speed-dependent steering, gradual throttle, service brakes, reverse delay,
  handbrake, gravity, collision response, spinning/steering wheels, brake lights,
  and free recovery. Loaded cargo adds 120–220 kg to the rigid body.
  Approximate practical top speed is 75–85 km/h on a long
  straight; town driving should be slower.
- **Cameras:** damped chase, closer chase, and bonnet view. Chase cameras raycast
  against scenery to shorten their distance near walls. Mouse orbit recenters.
- **World:** a hand-composed district with nine intersections, lane and crossing
  markings, sidewalks, warehouses, shops, apartments, parks, street furniture,
  a clinic, café, service station, quay, containers, crane, ship, water, and hills.
- **Traffic:** five persistent cars on rounded, correctly sided lane loops.
  They slow for corners, leave a gap to vehicles ahead, brake for obstructions,
  respect the central vertical traffic-light cycle, and collide physically.
- **Deliveries:** six collection/delivery locations, three offered contracts at
  a time, load/drive/unload states, stationary hold-to-interact, distance-based
  base pay, independent cargo condition/time bonuses, and repeat work from the
  nearest business. Standard, fragile and priority work unlock with career rank.
  Contracts can be returned to dispatch without a charge or reward.
- **Navigation:** north-up district map, road-graph route, destination arrow,
  distance, turn hints, active loading ring, and a world-space destination label.
  The M district map labels destinations and shows business progress. Service
  detours preserve cargo and restore delivery navigation after service.
- **Economy:** balance, lifetime earnings and deliveries, moderate fuel use,
  severity-based collision damage, and a combined refuel/repair service with a
  quoted cost. G opens fuel-only, repair-only and full service plus three permanent
  van upgrades. Four ranks increase base pay and award one-time milestones.
  Emergency fuel and free recovery prevent resource soft locks.
- **Atmosphere:** directional sunlight, optional sun shadows, procedural sky and
  water, slow day progression, selectable night, street lights, and headlights.
- **Audio:** original generated engine loop with RPM/load/gear variation, road
  noise, coastal ambience, a subtle music bed, UI tones, and collision sounds.
- **Menus/HUD:** main menu, pause, resume, recovery, job selection, settings,
  return to menu, save and quit; speed, gear, fuel, condition, balance and job HUD.
- **Working settings:** four window sizes, fullscreen, three rendering qualities,
  separate master/music/effects volumes, mouse sensitivity and invert-Y.
- **Saves:** validated v2 JSON written via a temporary file and atomic rename, v1
  migration, last-good backups and corrupt-file preservation. Position, heading,
  active cargo/timer, money, fuel, condition, delivery totals, upgrades, mileage and
  world clock persist. QA does not modify personal saves or settings.

## Technology and performance

**Godot 4.3 stable, GDScript, OpenGL Compatibility, GodotPhysics3D.**

This engine provides native Linux and Windows execution, 3D rendering, rigid-body
physics, audio, input, UI and export tools under a free license. Compatibility
rendering fits this VM's OpenGL 3.3 graphics support without requiring Vulkan.

The development VM has two virtual CPU cores, approximately 4 GB RAM, Ubuntu
20.04, and VMware SVGA3D/Mesa 21.2.6. The project uses:

- Baked, vertex-colored static scenery with inexpensive box collision geometry.
- Merged vehicle body meshes and batched animated wheels.
- A five-car traffic pool, small textures, and unshadowed local lights.
- A lower-resolution 3D viewport behind a sharp independent UI.
- Fixed 60 Hz physics and a 60 FPS rendering cap.

Historical central-street samples at **960 × 540** were approximately **30 FPS on
VM Low** and **28 FPS on Balanced**. The complete rendered test, which includes
night, collisions, screen captures and view changes, was slower; expect roughly
**20–30 FPS on this VM**, with occasional shader-compilation/view-transition dips.
These are measurements of this VM, not a guarantee for other systems.
The expanded 2026-10-05 native visual integration run averaged **24.9 FPS**;
see `docs/TESTING.md` for the current measurements and coverage.

| Quality | 3D resolution relative to window | Shadows / AA |
|---|---:|---|
| VM Low | 65% | Sun shadows off; no MSAA |
| Balanced (default) | 75% | Sun shadows on; no MSAA |
| High | 100% | Sun shadows and 2× MSAA |

Use **VM Low at 960 × 540** for the smoothest VM experience. High was much slower
in testing and is intended for stronger graphics hardware. Press **F3** to see
the actual frame rate.

## Project organization

```text
project.godot                 Engine/project configuration
scenes/main.tscn              Composition root scene
scripts/game.gd              Game flow, pause, settings, system wiring
scripts/core/                Input actions and local persistence
scripts/vehicle/             Physics, vehicle mesh, camera, fuel and damage
scripts/world/               District, mesh/material helpers, batching, traffic
scripts/gameplay/            Contracts, delivery state machine, destination marker
scripts/ui/                  Native menus, HUD, minimap
scripts/audio/               Procedural sounds and audio buses
assets/                      Original icon and water shader
qa/                          Physics/UI integration tests and visual probes
docs/                        Playing guide and verification notes
third_party/godot/           Engine and bundled-library license notices
tools/                       Engine bootstrap and development bundle creation
builds/phase1-linux/          Playable, self-contained Ubuntu development bundle
.tools/                      Local engine executable (development only)
```

World models and sounds are generated at startup from the source definitions.
There are no copyrighted commercial game assets or runtime network services.

## Progress and settings

On Linux:

```text
~/.local/share/godot/app_userdata/Harborline Dispatch/
    progress.json    player progress
    progress.json.bak    last-good save backup
    settings.cfg     audio/video/mouse preferences
    logs/            engine logs
```

On Windows the equivalent folder is under
`%APPDATA%/Godot/app_userdata/Harborline Dispatch/`.

Progress is saved on pickup, delivery, service, upgrades, gameplay menus, exit,
and every 25 seconds of play. Continuing an active delivery restores its cargo
condition, timer, payload weight and current position. Old v1 saves are migrated;
an unreadable primary falls back to the last-good backup when available.
The simulation pauses when the game loses focus.

QA uses separate `qa_progress.json` / `qa_logic_progress.json` slots and never
changes player progress or settings.
To start a fresh personal profile, close the game and move both `progress.json`
and `progress.json.bak` (if present) out of this directory. Keep them in a backup
folder if you want to restore that shift later; leaving the `.bak` in place will
restore the last good shift automatically.

## Verification

[Verification notes](docs/TESTING.md) describe the exercised gameplay path.
Current results: **78/78 logic checks**, **64/64 headless integration checks**,
and **64/64 native rendered integration checks**. The browser WebGL2 test remains
environment-blocked and was not retried.
The integration playtest uses actual rigid-body simulation and input actions;
it physically drives the loaded van to the workshop rather than teleporting
to the destination.

From the project directory:

```bash
# Non-rendering persistence, progression, offers/routes and economy regressions
./run.sh --headless --script res://qa/logic_tests.gd

# Fast, isolated physics/gameplay/menu integration test
./run.sh --headless --fixed-fps 60 -- --qa

# The same gameplay test in a rendered native desktop window, plus screenshots
./run.sh -- --qa --qa-visual

# Visual review viewpoints and timed rendering samples
./run.sh -- --visual-probe
```

Reports are written to `qa/latest_logic_report.json`, `qa/latest_headless_report.json`
and `qa/latest_visual_report.json`. Screenshots go to `qa/screenshots/`.
The headless renderer omits audio playback and purely visual destination/water
geometry; the rendered run exercises their actual presentation.

## Build the Ubuntu development bundle

```bash
./tools/build_phase1.sh
```

This creates `builds/phase1-linux/Harborline` and `Harborline.pck`, with license
notices and the playing guide. The bundle uses the standard engine executable
as its native PCK runtime; consequently it is larger than a release-template
export. It opens directly into the game, not an editor or project manager.
It is a portable **development bundle**, not a final installer.

## Future desktop packaging goal

The future distribution goal is tested native **Linux/Ubuntu x64** and **Windows
x64** playable builds, followed by a setup/installer where technically supported.
This work is deliberately deferred while the game remains in active development;
there is no final installer, release tag or GitHub Release in this repository yet.

## Phase 2 export workflow — after playable-version approval

`export_presets.cfg` includes **Linux x64** and **Windows x64** presets. Once
Phase 1 has been approved:

1. Install the **Godot 4.3 stable export templates** through the editor's export
   template manager (free). Match templates to the engine version exactly.
2. Create `builds/linux-release/` and `builds/windows-release/`.
3. Produce release-template exports:

   ```bash
   ./run.sh --headless --export-release "Linux x64" builds/linux-release/Harborline.x86_64
   ./run.sh --headless --export-release "Windows x64" builds/windows-release/Harborline.exe
   ```

4. Include the PCK and license notices, then test both exports on clean target
   systems with no editor, source checkout, or network connection.
5. Package Linux as an AppImage and/or `.deb`; package Windows with a free
   installer such as Inno Setup or NSIS. Add proper shortcuts, icons, version
   metadata, upgrade/uninstall behavior and smoke tests.

Windows exports can be generated from Linux. Windows runtime behavior still
needs testing on Windows. Final installers and Windows binaries are deliberately
deferred until approval of this playable version.

## Scope and known limitations

- One van, a compact, mostly flat district, and six delivery destinations.
  The geometry is original stylized art, not scanned/photorealistic content.
- Bonnet view is available; there is no modeled cockpit, working dashboard,
  walking character, trailer coupling, or manual transmission.
- Traffic follows fixed loops with conservative yielding, not a general city AI.
  Cars wait behind a blocking player and cannot plan overtaking maneuvers.
  There are no pedestrians, police, traffic fines, or dynamic vehicle spawning.
- Tires use a simplified force/friction model. Narrow obstacles or aggressive
  collisions can tip the van; **R** is the intended recovery mechanism.
- Visual curbs are intentionally forgiving; roads do not simulate detailed
  potholes or terrain deformation. Buildings have exterior collision only.
- Damage is a condition value, not body deformation. Fuel and repairs are a
  simple service transaction, not detailed fluid/mechanical simulation.
- Navigation is a compact road-graph route and compass, without spoken turn
  instructions. A large labeled district map and turn hints are available;
  there is no route recalculation penalty.
- Audio is synthesized rather than recorded. Music is an ambient pad.
- No rebinding menu, controller/steering-wheel support, localization, multiplayer,
  weather, additional playable vehicles, or multiple personal save slots.
- Low VM performance and first-use shader stutter remain the main presentation
  constraints. Night adds local-light work; High is expensive on this VM.

Next gameplay improvements should follow playtest feedback: handling tuning,
better road/vehicle art, richer loading interactions, more capable traffic,
controller support, and additional contracts within the existing district.

## License

Game code and original assets: MIT. Engine/library notices are in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
