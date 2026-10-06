# Architecture and desktop delivery

## What is actually in this project

The inspected project is **Harborline Dispatch 0.2.0**, a native Godot 4.3
stable / GDScript game. It already contained this architecture when development
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
| `scripts/world/district.gd` | Procedural environment, lighting, places and road-graph routing |
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

## Recommended distribution strategy

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

After playable-game approval:

1. Install the **official Godot 4.3 stable export templates**, matching the local
   engine. The Linux x64 and Windows x64 presets already exist in
   `export_presets.cfg`, with version 0.2.0 metadata and source-tool exclusions.
2. Export genuine release runtimes. Create the output directories first, then
   run from the project directory:

   ```bash
   ./run.sh --headless --export-release "Linux x64" builds/linux-release/Harborline.x86_64
   ./run.sh --headless --export-release "Windows x64" builds/windows-release/Harborline.exe
   ```

3. Test Linux on a clean Ubuntu 20.04-compatible system and Windows on an actual
   Windows x64 machine. Verify launch, graphics, audio, input, saves, fullscreen,
   focus/pause and paths containing spaces/non-ASCII characters. Linux can build
   a Windows export; that does not replace Windows runtime verification.
4. Include the game license, Godot license and bundled-library notices. For
   Windows, enable proper executable icons/version-resource generation with the
   export toolchain; the current development preset does not stamp those resources.
5. Package Windows with **Inno Setup or NSIS**. Offer a portable ZIP if desired.
   Use a **portable Linux archive/AppImage**, with a `.deb` if installation and
   menu integration are desired. Validate the AppImage runtime against the
   oldest supported distribution. Configure proper shortcuts, install locations,
   upgrade/uninstall behavior and save-data preservation.
6. After review and target-platform verification, prepare a GitHub Release with
   the actual tested artifacts and checksums. The current source backup is already
   in the dedicated V2 repository; no release assets have been published.

Released players will launch an executable or installed shortcut. They will not
run npm, Vite, a localhost server, OmniRush or an editor. Normal system graphics
and audio drivers remain required. No final installers, Windows exports or GitHub
Release have been produced; this source backup is for active development.

## Run the current preview

On this Ubuntu machine, from any working directory:

```bash
"/home/ubuntu/Desktop/3d Game/builds/phase1-linux/Harborline"
```

Keep `Harborline` and `Harborline.pck` together when copying the folder to another
Linux x64 machine. OpenGL 3.3 support is sufficient; WebGL2 capability is not
needed for this native game.

To run the source project with the existing local engine:

```bash
"/home/ubuntu/Desktop/3d Game/run.sh"
```

On Windows, source can be opened with Godot **4.3 stable** and run with F5 (project)
or F6 (`scenes/main.tscn`). A standalone Windows runtime is a later export,
not the Linux `Harborline` file renamed to `.exe`.
