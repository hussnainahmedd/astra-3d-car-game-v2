# RoadShift — quick start

Run **RoadShift.exe** on Windows or
**RoadShift.x86_64** on Linux. Keep `RoadShift.pck` beside it.
This is a native, offline desktop game set in the Harborline district.
The optional Linux development bundle uses `RoadShift` and `RoadShift.pck`.

## Your first delivery

1. Choose **Start your shift**.
2. Press **J** and accept the first contract, **Northline Works**.
3. You start in the depot collection bay. Stop and **hold E** until the cargo is loaded.
4. Pull out to the road on your left. Turn right, then follow the amber route north.
5. The workshop loading bay is on your right, just before the far intersection.
6. Stop in the amber ring. **Hold E** to hand over the cargo and receive payment.
7. Press **J** again for jobs collecting at the place you just delivered to.

There are no failed jobs or countdown penalties. On-time, careful driving earns
an extra bonus. Use the map and take your time.

## Controls

| Action | Keys |
|---|---|
| Accelerate | W / Up |
| Brake; hold at low speed to reverse | S / Down |
| Steer | A, D / Left, Right |
| Handbrake | Space |
| Load / deliver | Hold E while stopped in the bay |
| Refuel and repair | E while stopped at Coast Service |
| Job board | J |
| District map and business progress | M |
| Workshop, service options and upgrades | G |
| Camera: chase, close, bonnet | C |
| Look around | Hold right mouse button and move mouse |
| Headlights | H |
| Recover upright to a nearby lane | R |
| Pause | Esc |
| Cycle afternoon / sunset / night | N |
| Fullscreen | F11 |
| Frame-rate / physics readout | F3 |

The service station is just west of the middle-left intersection, marked by a
teal square on the map. Recovery is free and preserves your cargo.

Press **M → Route to Coast Service** to make a service detour during a contract.
Your cargo stays aboard. Successful service restores the delivery route; you can
also restore it using the map. **G** shows the workshop from anywhere, but you
must park upright at the service station to buy service or upgrades.

## Build your business

- **New Courier:** standard work. The $500 economy tune saves 25% fuel.
- **Local Partner, 3 deliveries:** 5% higher base pay, fragile work and a $125
  milestone award. Protective bumpers ($700) reduce van damage by 25%; a padded
  cargo rack ($900) reduces cargo damage by 35%.
- **Harbor Specialist, 8 deliveries:** 10% higher base pay, priority work and $250.
- **Master Dispatcher, 15 deliveries:** 15% higher base pay and $500.

Careful handling earns up to $45 extra. Standard/fragile jobs can earn $30 for
being on time; priority jobs can earn $60. The bonus window is shown after loading.
Late jobs still pay their base and care bonus. Milestone awards are paid once.

Loaded cargo adds weight to the physical van. Fragile cargo is more vulnerable
to impacts. Repairs restore the van, not damaged cargo. If you want different work,
use **J → Return contract • no fee**; returning a contract grants no reward.

Choose fuel-only, repair-only or full service with **G**. If you cannot afford
service and the tank is nearly empty, emergency fuel keeps the shift playable.

## VM performance

Start with **960 × 540, Balanced**. For a smoother frame rate, choose **VM Low**;
it disables sun shadows and renders the 3D view at a lower resolution while
keeping the HUD sharp. High is intended for a better graphics device.

## Saving

Progress saves on collection, delivery, service, upgrades, every 25 seconds, when
opening gameplay menus, and when exiting. It includes money, fuel, condition,
current cargo/timer, rank progress, upgrades, mileage, world clock and position.
Older v1 progress is migrated automatically. A last-good `progress.json.bak` is
kept; a damaged primary is preserved as `progress.json.unreadable` when replacing it.

Linux save directory:
`~/.local/share/godot/app_userdata/Harborline Dispatch/`

Windows: `%APPDATA%/godot/app_userdata/Harborline Dispatch/`.
This legacy folder is preserved across the product rename. Uninstalling the game
does not remove your progress. Save format v2 is independent of the release version.

You can exit with **Esc → Save & quit** or close the window.
