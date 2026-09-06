# Operation Storm repair verification — 6 September 2026

## What changed

- Stable camera magnification and map limits; explosions attenuate camera shake with distance.
- Authored map landmarks and cover routes across all five missions, plus distinct, staggered holdout approaches.
- Cover-aware infantry pursuit, fixed bunker arcs, aimed grenade landing, stronger RPG anti-armor damage and functioning convoy combat.
- Guarded firing/reloading, death input lock, checkpoint action reset and respawn protection.
- Swept bullet collision, one-hit impact handling and tank rear weak-point collision.
- Hidden-stage collision removal, mandatory urban clearing, resilient sequential objectives and final flag gating.
- HUD reserve-ammo initialization and frame placement; mission unlock is saved before results are displayed.

## Verification scope

The original build was launched through Run_Game.bat and inspected live in the opening mission. Empty space outside the map and the HUD overlap were visible. The automatic enemy-count zoom was confirmed in source.

The new gameplay regression suite exercises 24 assertions: camera stability, map limits, weapon timing, death/respawn, fast projectile impacts, tank rear hits, hidden encounter collisions, assault targeting, cancelled sniper shots, sequential objectives and grenade landing.

The campaign suite exercises 33 assertions across all five mission scenes. It uses actual timers, collision worlds and objective signals, with scripted enemy defeats to verify progression. A player-sized clearance check verifies routes to supply pickups. This is a progression regression test, not evidence of a balanced human playthrough.

The existing seven suites cover decals, effects, character rigs, vehicles, mission structure, UI structure and bullet damage. Their startup was corrected to wait for an active scene tree instead of manually calling ready handlers. The runner now detects runtime errors rather than relying only on exit codes. Asset validation: 3 pytest tests passed.

## Remaining limitations

Desktop control was stopped by the physical Escape key before the updated build could be replayed visually. No further desktop input was sent. Final visual review and human difficulty tuning therefore remain unverified.

Godot reports retained script/texture resources at shutdown in some headless suites. These are preserved as warnings in the complete test log, not silently discarded or described as clean shutdowns. The runner still fails on assertions, script errors and other runtime errors.

Run `python tools/run_visual_tests.py` from the project to reproduce the checks. The full result is in `docs/verification-2026-09-06.log`. Close and reopen Run_Game.bat to load the updated source; an already-running game retains the previous build.

---

## Objective Guidance System (same day, evening)

Added world beacons, screen-edge arrows, and minimap gold blips so every mission shows the next target clearly.

- Mission 2: bunkers enforced north→south, then east breach with visible `BREACH EAST` banner
- Missions 3–5: APC/T-55/village, mortars/approach, tank/flag markers
- New suite: `tests/test_objective_guidance.gd` — 28/28 PASS
- Campaign progression: 33/33 PASS; gameplay reliability: 36/36 PASS; UI visual: PASS
