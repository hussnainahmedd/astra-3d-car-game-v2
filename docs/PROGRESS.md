# RoadShift project status

## Implemented baseline

- Four-wheel force-based vehicle handling, recovery, camera switching and lights.
- A compact district with six businesses, accessible loading bays and Coast Service.
- Five persistent traffic cars with lane following, obstruction and signal stops.
- Collection/delivery contracts, cargo mass/condition, rewards and repeat work.
- Standard, fragile and priority work, four career ranks and one-time milestones.
- Permanent economy, bumper and cargo-rack upgrades with affordability/rank checks.
- Full, fuel-only and repair-only service, quoted costs and emergency fuel.
- Road-graph navigation, turn hints, destination markers and service detours.
- Dispatch, district map, workshop, HUD, pause/main menus and audio/video settings.
- Validated v2 progress, v1 migration, backups, corrupt-file recovery and autosave.
- Procedural world/vehicle resources, synthesized audio and day/night lighting.
- Native Windows/Linux exports, portable packages, Windows installer and CI checks.

## Release maintenance

**v0.1.0** established the initial desktop prerelease and remains archived for
existing downloads. **v0.1.1** standardizes the **RoadShift** product identity across
the window, menus, HUD, icon, executable metadata, exports, installer, CI artifacts
and developer/player documentation.

The application-data directory and save schema remain compatible with existing
profiles. Installer file selection explicitly excludes stale product executables
from reused export directories. Gameplay/system identifiers retain their existing
structure.

## Verification coverage

The existing logic suite covers persistence, routes, offers, progression and
economy. The integration suite physically drives a complete delivery, exercises
controls/menus/service, tests seven loaded bay exits and checks traffic behavior.
Native startup and installer checks are recorded separately from full graphical
playtesting. See [TESTING.md](TESTING.md).

## Further playtest scope

- Longer multi-shift journeys, listening/handling review and stronger GPU hardware.
- Additional complete origin/destination journeys beyond the automated course.
- Interactive Windows rendering, audio and broader target-hardware compatibility.
- Presentation/performance tuning only when actual playtest findings justify it.

The current release scope is documented in the README and playing guide. Future
versions use the existing native export pipeline and GitHub Releases; see
[RELEASING.md](RELEASING.md).
