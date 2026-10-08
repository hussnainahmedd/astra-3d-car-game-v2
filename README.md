# RoadShift

**Open World Delivery & Driving Simulator**

RoadShift is an offline, single-player 3D driving game for Windows and Linux.
Explore a compact harbor district, collect delivery contracts, transport cargo,
earn rewards, and maintain your van between jobs.

**Current version: v0.1.1 — desktop prerelease.**
[Download desktop builds](https://github.com/hussnainahmedd/roadshift/releases).

## Overview

Start a shift, choose a contract from dispatch, stop in the collection bay, and
hold **E** to load. Follow the road route to the destination, stop in its delivery
bay, and hold **E** again to receive payment. Nearby businesses offer return work
so you can continue driving without returning to the depot after every delivery.

Careful handling and on-time arrivals earn bonuses. Late deliveries still pay
their base reward. Career ranks unlock fragile and priority contracts, higher
base pay, and permanent van upgrades.

The current world is one freely drivable, approximately **360 × 400 m** district
with six delivery locations and a service station. Its stylized scenery and
vehicle/audio systems are defined in the source project.

## Features

- **Vehicle driving:** acceleration, service braking, delayed reverse, steering,
  handbrake, headlights, brake lights and free upright recovery.
- **Vehicle physics:** a 1,750 kg rigid body with four raycast suspension springs,
  damping, tire forces, drag, collisions and physically added cargo mass.
- **Cameras:** damped chase, close chase and bonnet views; mouse orbit, recentering,
  invert-Y, and wall avoidance for chase views.
- **District and traffic:** roads, intersections, loading bays, warehouses, shops,
  parks and a waterfront; five persistent traffic cars with lane following,
  obstruction braking, collision response and central traffic-light stops.
- **Deliveries:** three offered contracts, one active job, collection/delivery
  stages, standard/fragile/priority cargo, cargo-condition and time bonuses.
- **Navigation:** north-up minimap, labeled district map, road routes, distance,
  destination arrow, turn hints and loading markers. Service detours preserve cargo.
- **Economy and maintenance:** balance, lifetime earnings, four ranks, milestone
  rewards, fuel, collision-based condition loss, repair/refueling options, and
  economy/bumpers/cargo-rack upgrades. Emergency fuel prevents empty-tank soft locks.
- **Atmosphere and audio:** changing daylight, selectable night, street lights,
  procedural sky/water, synthesized engine/road/ambient/music/UI/collision sounds.
- **HUD and menus:** speed, gear, resources, balance and contract status; dispatch,
  map, workshop, pause, resume, recovery, settings, main menu and save/quit.
- **Persistence:** versioned progress, backup recovery, active cargo/timer,
  position, upgrades, mileage, world clock and saved preferences.
- **Settings:** four window sizes, fullscreen, three rendering qualities,
  master/music/effects volume, mouse sensitivity and invert-Y.

Current scope includes one van and one district. There is no multiplayer,
controller/rebinding menu, modeled cockpit, walking character, weather system or
additional playable vehicle. Traffic uses fixed loops; damage is a condition
value rather than body deformation.

## Controls

| Action | Input |
|---|---|
| Accelerate | **W / Up Arrow** |
| Brake, then reverse after stopping | **S / Down Arrow** |
| Steer | **A / D / Left / Right Arrow** |
| Handbrake | **Space** |
| Load / complete delivery, upright and below 2 km/h | **Hold E** |
| Refuel + repair while stopped at Coast Service | **E** |
| Dispatch board | **J** |
| District map / career progress | **M** |
| Workshop / service / upgrades | **G** |
| Cycle chase / close chase / bonnet camera | **C** |
| Look around; release to recenter | **Right mouse button + mouse** |
| Headlights | **H** |
| Recover upright to a nearby lane | **R** |
| Pause / back / resume | **Esc** |
| Cycle daylight / sunset / night | **N** |
| Fullscreen | **F11** |
| Frame-rate / wheel-contact display | **F3** |

Keyboard actions are defined in `scripts/core/input_bindings.gd`.
See [the playing guide](docs/PLAYING.md) for your first delivery and service rules.

## Tech Stack

| Area | Technology used in this repository |
|---|---|
| Game engine | **Godot 4.3 stable**, exact official build `4.3.stable.official.77dcf97d8` |
| Gameplay language | **GDScript**; Godot shader language for the water material |
| Rendering | Native **OpenGL 3.3 Compatibility**; `Camera3D`, `WorldEnvironment`, procedural sky, directional/local lights, `StandardMaterial3D` and `ShaderMaterial` |
| Resolution/quality | A lower-resolution **SubViewport** behind a native-resolution UI; quality controls render scale, sun shadows and MSAA |
| Physics | Built-in **GodotPhysics3D**, 60 Hz; `RigidBody3D`, `PhysicsDirectBodyState3D`, ray queries, box collision shapes, and `CharacterBody3D` traffic |
| Vehicle solver | Custom four-wheel raycast suspension and load-limited longitudinal/lateral tire forces applied to the rigid body |
| UI/input | Godot **Control**, **CanvasLayer**, buttons/options/sliders/check buttons, custom `CanvasItem` drawing, `InputMap` and built-in fallback font |
| Audio | Godot **AudioServer** and **AudioStreamPlayer**; synthesized **AudioStreamWAV**, 16-bit mono PCM at 22,050 Hz, with Music/Effects buses |
| Persistence | Godot **JSON** progress format v2 and **ConfigFile** settings; bounded data, temporary-file writes, rename, last-good backups and v1 migration |
| Navigation | Custom **Dijkstra-style shortest-path road graph**, driveway attachments and `PackedVector3Array` routes; traffic follows baked `Curve3D` lane loops |
| World/assets | Procedural primitive/merged **ArrayMesh** geometry, **SurfaceTool**, vertex colors and simple colliders; `.gd`, `.tscn`, `.gdshader`, `.svg`, `.godot` and `.cfg` source formats |
| Native exports | Godot's **Linux x64 / Windows x64 release-template export**; official matching `4.3.stable` templates; executable plus `.pck` game data |
| Windows packaging | **rcedit 2.0.0** for executable resources, **Inno Setup 6** for the per-user installer, Python `zipfile` for the portable ZIP; the compiler version is recorded per build |
| Linux packaging | Native x86-64 **ELF** export and Python `tarfile` **tar.gz** archive, with executable permissions preserved |
| Build utilities | **Python 3 standard library**, **Bash**, **PowerShell**, **curl**, **unzip**, Git and GitHub CLI; engine/template/resource-editor downloads use official release sources |
| CI/distribution | **GitHub Actions** on `windows-latest`, Python 3.12, checkout/setup-python/upload-artifact actions; manually dispatched build/validation and **GitHub Releases** distribution |
| Validation | Existing GDScript logic and physics/input/UI suites, headless Godot import/startup, native smoke checks, Bash syntax checks, Python compilation, **Actionlint**, ELF/PE/PCK/ZIP checks and SHA-256/SHA-512 verification |

## Project Architecture

`scenes/main.tscn` loads `scripts/game.gd`, the composition root. It creates the
simulation, rendering viewport, native UI and audio systems and coordinates
launch, menus, pause, settings, autosave and shutdown.

| System | Main source files and responsibilities |
|---|---|
| Vehicle | `scripts/vehicle/vehicle_controller.gd`: forces, suspension, input and recovery; `vehicle_visual.gd`: meshes/wheels/lights; `chase_camera.gd`: camera views; `vehicle_systems.gd`: fuel, condition and service |
| Missions/progression | `scripts/gameplay/delivery_manager.gd`: offers, cargo stages, routing and payment; `career.gd`: ranks/upgrades; `destination_marker.gd`: world guidance |
| World/traffic | `scripts/world/district.gd`: district, lighting, locations and route graph; `traffic.gd`: lane following/stops; `geometry.gd` / `scenery_batch.gd`: mesh and collision construction |
| UI/HUD | `scripts/ui/game_ui.gd`: menus and HUD; `minimap.gd`: map drawing and route display |
| Persistence/input | `scripts/core/progress_store.gd`: local progress/settings; `input_bindings.gd`: keyboard actions |
| Audio | `scripts/audio/game_audio.gd`: PCM synthesis, playback, pitch/volume variation and audio buses |
| Configuration/export | `project.godot`, `export_presets.cfg`, `tools/` and `packaging/windows.iss` |

The simulation pauses as a subtree while menus and UI remain responsive. Pause
changes are applied outside physics stepping. The main menu freezes traffic and
the world clock; losing focus pauses normal gameplay.
See [architecture details](docs/ARCHITECTURE.md).

## Installation

Download the packages from [GitHub Releases](https://github.com/hussnainahmedd/roadshift/releases).
Each portable package includes its runtime, game data, playing guide and license
notices. Players do not need development tools or a separate engine installation.
Normal graphics/audio drivers and **OpenGL 3.3** support are required.

### Windows

- Run **`RoadShift-Setup-Windows-x64.exe`** for per-user installation, a Start Menu
  entry, an optional desktop shortcut and uninstall support.
- Or fully extract **`RoadShift-Windows-x64.zip`**, then double-click
  **`RoadShift.exe`** inside `RoadShift-Windows-x64/`.
- Keep **`RoadShift.pck`** beside the portable executable. User progress is stored
  separately from the installation and is preserved by uninstall.

### Linux

Extract **`RoadShift-Linux-x64.tar.gz`** and run the native executable:

```bash
tar -xzf RoadShift-Linux-x64.tar.gz
./RoadShift-Linux-x64/RoadShift.x86_64
```

Keep **`RoadShift.pck`** beside the executable. The archive preserves permissions;
if your extractor removes them, run `chmod +x RoadShift.x86_64` in the extracted
folder. The Linux package is a portable archive; no root installation is needed.

Linux validation uses Ubuntu 20.04 x64. Windows headless startup and installer
lifecycle checks run on the hosted Windows runner. Interactive Windows rendering
and broad hardware/distribution compatibility are separate, untested coverage.

## Building From Source

### Linux toolchain and export

Use **official Godot 4.3 stable** and exactly matching export templates.
The Linux bootstrap requires `curl` and `unzip`; packaging requires Python 3.

```bash
./tools/install_engine.sh       # first-time engine setup
./run.sh --headless --editor --import --quit
./tools/build_desktop.sh
```

`build_desktop.sh` verifies the engine version, installs checksum-verified official
release templates, imports resources, exports `builds/linux-release/RoadShift.x86_64`
and its PCK, and creates `builds/releases/RoadShift-Linux-x64.tar.gz`.

`GODOT_BIN` can select an existing compatible editor executable. Native export
presets are named **Linux x64** and **Windows x64**.

### Windows export and installer

Use **RoadShift Windows desktop package** in the Actions tab, or dispatch:

```bash
gh workflow run windows-desktop.yml --repo hussnainahmedd/astra-3d-car-game-v2 --ref main
```

The workflow verifies the official Godot/editor/templates and rcedit downloads,
exports the native Windows runtime, stamps product/version/icon resources,
packages the ZIP, compiles Inno Setup, and tests headless startup and installation.
Download its **RoadShift-Windows-x64** artifact for the ZIP, setup and test record.

On a Windows development machine with Python and curl, use PowerShell:

```powershell
./tools/build_windows.ps1 -Phase toolchain
./tools/build_windows.ps1 -Phase export
./tools/build_windows.ps1 -Phase installer
```

The installer step uses Inno Setup 6, installing the configured fallback through
Chocolatey if the compiler is absent. The hosted CI runner also executes
`-Phase validate` for disposable install/reinstall/uninstall fixtures.

## Repository Structure

```text
project.godot              Godot project identity and engine configuration
export_presets.cfg         Native Windows/Linux export presets
scenes/main.tscn           Entry scene
scripts/game.gd            Composition root and application flow
scripts/core/              Input bindings and persistence
scripts/vehicle/           Vehicle physics, visuals, camera and resources
scripts/world/             District, geometry, batching and traffic
scripts/gameplay/          Delivery, progression and destination marker
scripts/ui/                Menus, HUD and maps
scripts/audio/             Procedural audio and bus settings
assets/                    SVG icon and water shader
qa/                        Existing logic/integration/visual suites
tools/                     Engine setup, export, packaging and checksum utilities
packaging/                 Windows installer definition
.github/workflows/         Windows native build and validation
docs/                      Playing, architecture, testing and release guides
third_party/godot/         Engine/library license notices
builds/                    Generated exports/packages (Git-ignored)
.tools/                    Local toolchain downloads (Git-ignored)
```

## Development

On Linux, run `./run.sh` to play from source or `./run.sh --editor` to edit.
On Windows, open `project.godot` in Godot 4.3 stable and press **F5**.

Run the existing isolated validation suites:

```bash
./run.sh --headless --script res://qa/logic_tests.gd
./run.sh --headless --fixed-fps 60 -- --qa
```

Reports are written under `qa/latest_*.json`; screenshots and engine caches are
excluded from Git. Tests use dedicated QA save slots and skip personal settings.
Rendered checks are available through `./run.sh -- --qa --qa-visual` and
`./run.sh -- --visual-probe` where the graphics environment supports them.
See [testing coverage and status](docs/TESTING.md).

Progress uses JSON format v2, independent of the release version. The existing
profile directory remains `godot/app_userdata/Harborline Dispatch` under the
platform's application-data root for save compatibility. It stores progress,
backups, settings and logs; [the playing guide](docs/PLAYING.md) gives full paths.

Use **VM Low / 960 × 540** on limited virtual graphics. Balanced renders 3D at
75% window resolution with sun shadows; High uses full resolution and 2× MSAA.
Historical VM measurements are documented as measurements, not compatibility
or performance guarantees.

## Releases

Packaged desktop builds, `SHA256SUMS.txt` and platform validation records are
distributed through [GitHub Releases](https://github.com/hussnainahmedd/roadshift/releases).
**v0.1.1** introduces the RoadShift product identity. Earlier releases remain
archived for existing downloads. Binaries are not stored in normal Git history.

Follow [the release guide](docs/RELEASING.md) to develop, test, version, commit/push,
export, package and publish a new release. Update distribution is through releases.

## License

RoadShift code and project resources are distributed under the repository's
[MIT License](LICENSE). Godot and bundled-library notices are in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and included in desktop packages.
