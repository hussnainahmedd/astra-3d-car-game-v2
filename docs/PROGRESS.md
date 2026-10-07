# Development continuation and release recovery

## Release recovery — 2026-10-07

- Recovered clean, synchronized V2 `main` at `bbb3f89`; no uncommitted source was
  lost and the existing Linux development bundle was retained.
- Confirmed official Godot 4.3 stable and existing native export presets.
- Passed the existing gameplay suites; the coherent delivery/reward/continue loop
  required no system rewrite.
- Standardized product/window/menu/export identity as **Astra 3D Car Game V2**,
  initial release **v0.1.0**, preserving the legacy save/profile directory.
- Added checksum-verified official template bootstrap, Linux portable packaging,
  Windows native export/resource stamping, Inno Setup packaging and CI validation.
- Updated player/developer/release instructions. Actual downloadable artifacts
  and platform validation records belong to the V2 GitHub prerelease.

## Historical development continuation — 2026-10-05

## Resumed state

- Existing native Godot 4.3 project, original harbor district/vehicle/audio,
  functional delivery loop, traffic, menus, settings and Linux development bundle.
- Historical 2026-10-04 reports recorded 37/37 headless and rendered checks.
- No separate previous TODO file was present. Unfinished work was identifiable
  in partially connected career, v2 persistence, payload/cargo-condition and
  service-waypoint systems, plus the README's next-step/QA notes.
- The resumed baseline passed 36/37 headless checks. The partial version check
  rejected JSON numbers parsed as floats; this session corrected it.

## Completed

- [x] Preserve the existing district, tested force-based handling, camera modes,
  five-car traffic pool, delivery course, procedural art and generated audio.
- [x] Finish four career ranks, pay multipliers and one-time rank milestone awards.
- [x] Integrate standard / fragile / priority work and accurate bonus displays.
- [x] Add physically meaningful payload weight and independent cargo condition.
- [x] Connect permanent economy tune, bumpers and padded cargo rack to a workshop UI.
- [x] Offer full, fuel-only and repair-only service, exact quotes and emergency fuel.
- [x] Enforce service proximity, stationary/upright parking, rank and affordability.
- [x] Add M district map/business summary and G workshop, with service detours that
  preserve the contract and restore delivery routing after service.
- [x] Add route hints, cargo condition/bonus window HUD and wrapped notifications.
- [x] Add no-fee contract return, invert-Y setting and camera reset on recovery.
- [x] Stop endless traffic creeping and share one obstacle snapshot per traffic tick.
- [x] Freeze traffic/clock in the main menu, suppress repeat-key toggles, mute an
  empty-tank engine, and avoid counting menu/vertical movement as driven mileage.
- [x] Finish bounded v2 saves, v1 migration, last-good backup and corrupt-file recovery.
- [x] Persist world clock, mileage, upgrades, cargo condition and active delivery time.
- [x] Make QA exit status meaningful and keep all tests away from personal saves/settings.
- [x] Verify all 30 directed business routes and every loading bay's physical access.
- [x] Verify native OpenGL initialization and inspect current rendered UI screenshots.
- [x] Document native Windows/Linux export architecture and approval-gated release work.
- [x] Refresh the existing genuine ELF/PCK Linux preview, verify headless and native
  startup from outside the project, and test the excluded-QA flag guard.
- [x] Back up this current development source in the dedicated Astra 3D Car Game V2
  GitHub repository for continued work; no final release or installer was created.
- [x] Correct virtual driveway route attachments so navigation and distance-based pay
  stay on the road graph; extend QA to assert all internal road legs.
- [x] Fit menu panels to the supported small window size and smooth camera placement
  between physics frames without replacing the existing presentation.

## Historical outstanding work / later playtest scope

- [ ] User review of gameplay, handling, presentation and generated sound.
- [ ] Drive more complete origin/destination journeys; current automation drives
  one entire delivery, physically tests seven bay exits, and validates all 30
  business-to-business road routes. These are different coverage levels.
- [ ] Improve presentation/performance if playtest feedback warrants it. This VM
  averaged about 24.9 FPS during the expanded visual integration run.
- [ ] Verify long multi-shift play on stronger native hardware, including all ranks
  and contract types. Rules and save cases are covered by the headless logic suite.
- Native export/installer configuration and repeatable release tooling are now
  implemented for the authorized initial prerelease. Cross-hardware graphical
  playtesting remains later verification, independently of build/CI checks.

The earlier browser WebGL2 context test remains **environment-blocked by VMware**.
No browser/WebGL2 retries were made. It is not a pending defect in the current
native renderer. See `TESTING.md` and `ARCHITECTURE.md` for evidence and commands.
