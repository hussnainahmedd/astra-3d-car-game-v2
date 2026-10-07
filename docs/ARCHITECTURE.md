# Architecture and desktop delivery

## What is actually in this project

The project is **Astra 3D Car Game V2**, a native Godot 4.3
stable / GDScript game, previously named Harborline Dispatch in the development
preview. It already contained this architecture when development
resumed on 2026-10-05. This session continued its existing gameplay and did not
replace it with a new engine or a new project.

There is no Three.js renderer, JavaScript application, npm dependency, Vite
configuration or localhost server in this directory. The browser/WebGL2 failure
reported for the earlier preview is a real constraint of that preview environment,
but it is not the rendering API used by these files.

## Runtime composition

`scenes/main.tscn` loads `scripts/game.gd`, the composition root. It creates:

- **Simulation:** district, player rigid body, camera rig, traffic, vehicle
  resources, delivery state machine and destination marker.
- **Presentation:** a scaled 3D SubViewport behind a sharp native-resolution
  Control HUD/menu layer. Graphics quality adjusts render resolution, shadows
  and multisample antialiasing.
- **Audio:** native audio players and buses, with original generated sounds.
- **Local data:** versioned JSON progress and ConfigFile settings in Godot's
  platform-specific application data directory, outside the installation.

The root and UI process while paused; the simulation is a pausable subtree.
Pause/resume changes are applied in the root's idle update to avoid changing
physics-server state during an active query/step. The main menu disables the
vehicle, traffic and world clock. Losing focus pauses normal gameplay.

### Systems and boundaries

| Location | Responsibility |
|---|---|
| `scripts/core/progress_store.gd` | v1 migration, v2 saves, last-good backup, bounded data/settings |
| `scripts/core/input_bindings.gd` | Central keyboard actions, idempotent registration |
| `scripts/vehicle/vehicle_controller.gd` | Actual rigid-body forces, suspension, tires, payload mass |
| `scripts/vehicle/chase_camera.gd` | Three camera modes, wall avoidance, orbit and invert-Y |
| `scripts/vehicle/vehicle_systems.gd` | Fuel, condition, upgrade effects and service prices |
| `scripts/world/district.gd` | Procedural environment, lighting, places and driveway-attached road-graph routing |
| `scripts/world/traffic.gd` | Five persistent cars, lane loops, following and signal stops |
| `scripts/gameplay/delivery_manager.gd` | Offers, collection/delivery, cargo condition, payment, service detours |
| `scripts/gameplay/career.gd` | Rank thresholds, milestone awards and purchase rules |
| `scripts/ui/` | Dispatch, map/business summary, workshop, HUD and settings |
| `qa/` | Source-only logic, physics/input/UI integration and visual checks |

Service proximity/upright/stationary requirements are enforced by the composition
root as well as reflected in the UI. Purchase rules independently enforce rank,
ownership and affordability. Repairs do not heal cargo. A delivery can pay only
once; late work still receives its base pay. There are no runtime network services.

## Renderer availability and failure handling

`project.godot` selects **OpenGL Compatibility** for desktop and mobile renderer
settings. The game uses OpenGL 3.3 on Linux x64; it does not request WebGL2,
transform feedback, Vulkan or a browser context. The custom water shader also
uses the existing Compatibility pipeline.

Godot creates the native graphics context before executing the game's scripts.
If that context cannot be created on a target machine, the engine reports the
graphics initialization error and exits. A GDScript HUD cannot display an error
before the renderer exists. There is no custom second renderer initializer that
could inadvertently request WebGL2.

On this VM, one native X11/OpenGL run on 2026-10-05 successfully initialized
`OpenGL API 3.3 (Core Profile) Mesa 21.2.6` on VMware SVGA3D and passed all 64
integration checks. This does not establish browser WebGL2 support. The reported
WebGL2 test remains environment-blocked and was not retried.

## Native desktop distribution

Use the existing **native Godot exports**, maintaining the current engine and
Compatibility renderer. Wrapping this project in Electron/Tauri would add a
browser runtime without benefiting the existing native implementation.

The current `builds/phase1-linux/` bundle contains a genuine Linux x64 ELF runtime
plus the game's PCK. The runtime is the standard Godot executable acting as a PCK
player; it starts the game directly and requires no separately installed engine.
It is larger than a release-template build and is a portable **development
preview**, not a final installer. QA, source docs, build tools and engine bootstrap
files are excluded from its runtime pack. Packing finishes in a temporary file
before replacing the playable PCK.

The initial release version is **v0.1.0**, an explicitly prerelease-quality build.
The earlier internal preview number 0.2.0 was not a published release. Gameplay
and save format v2 remain intact; the original profile directory is preserved
with `application/config/custom_user_dir_name`.

`export_presets.cfg` retains the existing Linux x64 and Windows x64 architecture.
The release uses official **4.3.stable** templates with the exact official editor
`4.3.stable.official.77dcf97d8`, no engine conversion or browser wrapper.

- `tools/install_export_templates.py` checks the pinned official SHA-512 checksum
  and template version, then installs only selected desktop release templates.
- `tools/build_desktop.sh` creates the Linux release-template export and portable
  archive, keeping the genuine ELF executable and PCK together.
- `tools/build_windows.ps1` and `.github/workflows/windows-desktop.yml` export on
  `windows-latest`, stamp product/version/icon resources with rcedit 2.0.0, build
  an Inno Setup installer, and validate headless startup and installation lifecycle.
- `tools/package_desktop.py` verifies x64 ELF/PE32+ and Godot 4.3 PCK headers,
  includes notices and the playing guide, and produces an archive, provenance
  manifest and checksum. QA, tooling and generated caches stay out of the runtime.

The Windows installer is per-user and installs under LocalAppData/Programs.
It provides Start Menu/uninstall entries and an optional desktop shortcut.
Progress stays outside the installation and is preserved during reinstallation
and uninstall. The stable installer AppId supports future updates.

Released players will launch an executable or installed shortcut. They will not
run npm, Vite, a localhost server, OmniRush or an editor. Normal system graphics
and audio drivers remain required. Windows graphical gameplay, broad hardware
compatibility and prolonged play remain distinct from build/headless checks.
Actual per-release verification is recorded in `TESTING.md` and release notes.

## Run the current preview

On this Ubuntu machine, from any working directory:

```bash
./builds/phase1-linux/Harborline
```

Keep `Harborline` and `Harborline.pck` together when copying the folder to another
Linux x64 machine. OpenGL 3.3 support is sufficient; WebGL2 capability is not
needed for this native game.

To run the source project with the existing local engine:

```bash
./run.sh
```

On Windows, source can be opened with Godot **4.3 stable** and run with F5 (project)
or F6 (`scenes/main.tscn`). The standalone Windows runtime comes from Godot's
official Windows release template, exported as a genuine x64 PE32+ executable.
