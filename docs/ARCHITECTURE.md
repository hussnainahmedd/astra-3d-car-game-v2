# RoadShift architecture

RoadShift is a native **Godot 4.3 stable / GDScript** desktop game. Its renderer,
physics, input, UI, audio and export pipeline use the existing Godot project.
The exact supported editor is `4.3.stable.official.77dcf97d8`.

## Runtime composition

`scenes/main.tscn` loads `scripts/game.gd`. The composition root creates:

- A **SubViewport** with an independent 3D world and a pausable simulation subtree.
- The district, player `RigidBody3D`, chase-camera rig, traffic, resource simulation,
  delivery manager and world-space destination marker.
- A full-window `TextureRect` presenting the lower-resolution 3D viewport behind
  native-resolution **Control/CanvasLayer** menus, HUD and maps.
- Native audio players and a shared progress/settings store.

The root, menu UI and menu audio can process while the simulation is paused.
Pause/resume requests are applied during idle processing, outside physics query
flush/stepping. The main menu disables driving, traffic and the world clock.
Losing focus pauses normal gameplay; sandbox/QA runs are isolated.

## Systems and boundaries

| Source | Responsibility |
|---|---|
| `core/input_bindings.gd` | Centralized, idempotent keyboard-action registration |
| `core/progress_store.gd` | v2 JSON, v1 migration, bounded fields, backup recovery, ConfigFile preferences |
| `vehicle/vehicle_controller.gd` | Four spring raycasts, damping, tire/drive/brake forces, collisions, payload and recovery |
| `vehicle/vehicle_visual.gd` | Merged vehicle meshes, spinning/steering wheels, headlights and brake lights |
| `vehicle/chase_camera.gd` | Chase/close/bonnet views, mouse orbit, recentering, invert-Y and obstacle raycasts |
| `vehicle/vehicle_systems.gd` | Fuel, condition, mileage, upgrade effects and service transactions |
| `world/district.gd` | Geometry, collision, lighting, world clock, delivery places and road graph |
| `world/traffic.gd` | Five `CharacterBody3D` cars on baked `Curve3D` loops, following, signals and collisions |
| `world/geometry.gd`, `scenery_batch.gd` | Primitive meshes/materials, SurfaceTool/ArrayMesh merging and simple colliders |
| `gameplay/delivery_manager.gd` | Offers, collection/delivery, timers, cargo damage, rewards, routing and service detours |
| `gameplay/career.gd` | Four rank thresholds, one-time milestone awards and purchase rules |
| `ui/game_ui.gd`, `minimap.gd` | Native menus, HUD drawing, maps, status and interaction controls |
| `audio/game_audio.gd` | Seeded PCM synthesis, native playback, pitch/volume changes and audio buses |

All paths in this table are under `scripts/`. Internal class/node identifiers
remain stable across product-name changes.

## Physics and navigation

GodotPhysics3D advances at **60 Hz**. The van applies spring, damping and tire
forces through `PhysicsDirectBodyState3D`; cargo increases rigid-body mass.
Buildings use simple physical collision shapes, and traffic uses movement with
collision checks. This is a simplified driving model rather than tire deformation
or a full drivetrain simulation.

Navigation attaches the van and destination driveway to a nine-intersection
road graph, searches shortest paths using Dijkstra-style distance/visited tables,
and retains explicit driveway legs. The map, distance and turn hints share the
resulting route. Traffic uses separate fixed lane curves.

Collection/unloading requires upright parking, at least three grounded wheels,
speed below 2 km/h and proximity to the active bay. Service/purchases enforce
similar parking requirements at Coast Service. Rewards apply once, late jobs
keep their base pay, and repairs do not restore cargo condition.

## Presentation and resources

Native **OpenGL 3.3 Compatibility** renders the world. Quality adjusts SubViewport
resolution, sun shadows and MSAA while the HUD stays at window resolution.
Scenery and vehicle bodies are merged/batched `ArrayMesh` resources with vertex
colors and `StandardMaterial3D`; the water uses `assets/water.gdshader` through
`ShaderMaterial`. The sky is `ProceduralSkyMaterial`.

Audio is locally synthesized **16-bit mono PCM at 22,050 Hz** into
`AudioStreamWAV` resources and played through native `AudioStreamPlayer` nodes.
Master/Music/Effects bus settings and engine load/speed control volume/pitch.

Source resources include GDScript, TSCN, SVG, shader and configuration files.
Godot imports the icon and compiles scripts/scenes for native PCK export.

## Persistence compatibility

`ProgressStore.VERSION` stays **2**, independently of desktop release versions.
The custom user-directory setting deliberately retains
`godot/app_userdata/Harborline Dispatch` so existing saves/settings remain readable.
No progress schema or field identifiers are renamed for branding.

Progress is validated and written to a temporary file before rename. A last-good
backup is retained; unreadable primaries are preserved. QA uses its own slots and
does not write personal settings.

## Desktop distribution

- `tools/install_export_templates.py` verifies the pinned official SHA-512 archive
  checksum and exact **4.3.stable** template version.
- `tools/build_desktop.sh` exports **RoadShift.x86_64** and **RoadShift.pck** and
  packages a portable Linux tar.gz.
- `tools/build_windows.ps1` exports **RoadShift.exe**, uses **rcedit 2.0.0** for
  metadata/icon resources, builds the portable ZIP and compiles **Inno Setup 6**.
- `tools/package_desktop.py` verifies ELF/PE32+ x64 and PCK headers, copies the
  guide/notices, and records source/version/file hashes in `BUILD_INFO.json`.
- `.github/workflows/windows-desktop.yml` performs the native Windows build and
  install/reinstall/uninstall/headless-startup checks on `windows-latest`.
- `tools/release_checksums.py` verifies platform records and writes LF-only
  release-wide SHA-256 checksums.

Installers use the stable application ID and keep user data outside installation.
Explicit installer file selection excludes obsolete executable/data names left
in a reused export directory. Player packages contain native runtimes and game
data, not editor setup or QA tooling.

`tools/build_phase1.sh` remains an optional Linux development-bundle utility;
its RoadShift/PCK output uses the editor executable as a runtime and is larger
than the release-template export. Release packages use the native release templates.

See [release instructions](RELEASING.md) and [verification coverage](TESTING.md).
