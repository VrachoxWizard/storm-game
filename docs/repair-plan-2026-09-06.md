# Gameplay repair plan — 6 September 2026

1. Baseline: launch Run_Game.bat, inspect the opening mission, audit all five mission controllers and combat systems.
2. Camera and controls: replace enemy-count zoom with stable framing, constrain the camera to the map, fix HUD ammo initialization/layout and combat recovery.
3. Combat reliability: prevent duplicate projectile hits and tunneling, honor reload/fire cooldowns, cancel sniper windups, keep inactive encounters out of physics and radar.
4. Encounter variety: authored directional holdout waves, anchored defenders with cover-aware pursuit, fixed bunker arcs, useful aimed grenades, convoy engagement, mandatory urban street clearing and gated flag capture.
5. Level identity: add authored cover lanes, roads, buildings and fortress walls using the existing war-journal assets. Preserve navigable routes and objective access.
6. Verification: add runtime regressions for camera, combat and mission progression, run existing suites, inspect all five rendered missions and replay the updated launcher.

Baseline findings: automatic zoom oscillates at four nearby enemies; camera has no map limits; HUD initially omits reserve ammo and its fixed frame covers text; holdout enemies wander; repeating spawn markers stack enemies; hidden stages retain collisions; early flag capture can permanently prevent victory; sequential destroy objectives can stall when targets die early; reload and weapon switching can bypass intended timing; sniper cancellation still leaves a pending damaging callback; grenadier throws stop roughly 88 pixels away regardless of target distance.
