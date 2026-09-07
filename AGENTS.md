# AI Agent Instructions

This file provides context for AI coding agents (Cursor, Cline, Copilot, Antigravity, Claude Code, Windsurf, etc.) working on this project.

## Project Summary

**Operation Storm** is a top-down 2D arcade shooter built with **Godot 4** and **GDScript**. The game is set during the Croatian Homeland War's Operation Storm (1995). The player uses WASD movement and mouse aim/shoot through a 5-mission campaign.

## Critical Context

- **Engine**: Godot 4.x (NOT Godot 3.x — APIs differ significantly)
- **Language**: GDScript only (no C#, no GDExtension)
- **Art Style**: Hand-drawn war-journal aesthetic — all visual decisions should align with this
- **Game Type**: Top-down 2D arcade shooter (not platformer, not 3D, not turn-based)

## Architecture Overview

### Core Systems

| System | Location | Description |
|--------|----------|-------------|
| GameManager | `scripts/autoloads/GameManager.gd` | Singleton — scene transitions, game state, mission flow, `MISSION_META` (sector/brigade/SVK-corp/date) |
| ScoreManager | `scripts/autoloads/ScoreManager.gd` | Singleton — kill tracking, accuracy, scoring, ranks |
| SaveManager | `scripts/autoloads/SaveManager.gd` | Singleton — mission unlock progress, high scores persistence, settings (merged with defaults) |
| SoundManager | `scripts/autoloads/SoundManager.gd` | Singleton — audio bus management, SFX, music, voice lines (`play_voice_line`) |
| DecalManager | `scripts/effects/DecalManager.gd` | Singleton/Manager — persistent ground decals (blood, scorch, casings, treads) capped at 250 FIFO |
| CombatVfx | `scripts/effects/CombatVfx.gd` | Singleton/Helper — multi-stage charcoal explosions, dynamic point lights, muzzle flashes, burning-wreck cap (6) |
| FactionResource | `scripts/factions/FactionResource.gd` | Resource — HV/SVK faction identity (side, display_name, flag, insignia, uniform tint, unit names); `.tres` in `resources/factions/` |
| ObjectiveTracker | `scripts/missions/ObjectiveTracker.gd` | Mission objectives — DESTROY/AREA/KILL_COUNT/SURVIVE, sequential gating, `get_current_targets()`, `objective_target_changed` |
| ObjectiveGuidance | `scripts/missions/ObjectiveGuidance.gd` | Binds tracker/manual targets to world markers + HUD edge arrow |
| ObjectiveMarker | `scripts/effects/ObjectiveMarker.gd` | World-space gold beacon; joins `"objective"` / `"flag"` groups for minimap |
| ObjectiveArrow | `scripts/ui/ObjectiveArrow.gd` | Screen-edge pointer + distance readout toward off-screen objectives |
| Player | `scripts/player/Player.gd` | CharacterBody2D — modular rig, movement, aim, health, dodge-roll, HV faction |
| WeaponManager | `scripts/player/WeaponManager.gd` | Weapon slots, switching, firing, ammo management |
| EnemyBase | `scripts/enemies/EnemyBase.gd` | Base class for all enemies — state machine AI, modular rig, casualty decals, SVK faction |
| VehicleBase | `scripts/vehicles/VehicleBase.gd` | Base class for vehicles — independent turrets, tread decals, weak points, wrecks, SVK faction |

### Key Patterns

- **Autoload singletons** for global managers (GameManager, ScoreManager, SaveManager, SoundManager, DecalManager, CombatVfx)
- **Faction identity** via `FactionResource` (.tres) — HV (Croatian) and SVK (Serbian Krajina) sides drive unit names, uniform tints, flags, insignia, and minimap colors
- **Objective guidance** — `ObjectiveTracker` + `ObjectiveGuidance` drive world beacons (`ObjectiveMarker`), screen-edge arrows (`ObjectiveArrow`), and minimap gold blips via `"objective"` / `"flag"` groups
- **Inheritance** for enemy types — all extend `EnemyBase`; vehicles extend `VehicleBase`
- **Composition** for weapons — `WeaponManager` manages weapon instances on the player
- **Signals** for loose coupling — objectives, pickups, and UI communicate via Godot signals
- **State machines** for enemy AI — simple enum-based (PATROL, ALERT, CHASE, ATTACK, DEAD)
- **Object pooling** for projectiles — reuse bullet nodes instead of instancing/freeing
- **Persistent Decal FIFO**: `DecalManager` manages blood splatter, scorch marks, spent brass casings, and vehicle treads capped at 250 nodes using FIFO recycling
- **Dynamic 2D Lighting & Charcoal VFX**: Multi-stage explosions, muzzle flashes, and ricochet sparks paired with instantaneous/decaying `PointLight2D` nodes and charcoal smoke bursts (`CombatVfx.gd`, `VfxComponents.gd`)
- **Modular Character Rigging**: 3-tier hierarchy (`ShadowSprite` -> `LegsSprite` with 4-frame walk cycle aligned to movement -> `TorsoContainer` with 360-degree aim, weapon recoil kickback, squash/tumble dodge-roll, and casualty decal stamping on death)
- **Vehicle Mechanics & Destruction States**: Independent rotating turrets, continuous tread tracks, rear engine weak points (3x multiplier on Tank), and destruction states (wreck sprite swap, fire/smoke emitters, disabled collisions)
- **Atmospheric Lighting & Themed Terrain**: Seamless 512x512 ground textures, per-mission `CanvasModulate` atmospheric color grading, and illustrated architectural cover props (`BuildingTileRoof`, `BuildingTinRoof`, `BunkerEmplacement`)
- **Paper Overlay Shader & Sketched UI**: Hand-drawn paper texture overlay shader (`paper_overlay.gdshader`), chromatic aberration shock waves, sketched HUD frames, compass minimap, and ink-stamped mission completion reports
- **Procedural Asset Pipeline**: `tools/generate_war_journal_assets.py` generates 47 hand-drawn, cross-hatched, watercolor-washed sprites (characters, vehicles, terrain, props, VFX, UI, faction flags & insignia) deterministically using Python/Pillow, validated by `tests/test_assets_generation.py`

### Collision Layers

| Layer | Name | Used By |
|-------|------|---------|
| 1 | Player | Player CharacterBody2D |
| 2 | Enemies | All enemy CharacterBody2D nodes |
| 3 | PlayerBullets | Projectiles fired by player |
| 4 | EnemyBullets | Projectiles fired by enemies |
| 5 | Pickups | Weapon, health, ammo pickups |
| 6 | Environment | Walls, buildings, obstacles |
| 7 | Vehicles | APCs, tanks |

### Scene Organization

- Each scene type lives in its own `scenes/<category>/` directory
- Corresponding scripts live in `scripts/<category>/`
- Mission levels are individual scenes in `scenes/missions/`
- Effects systems in `scenes/effects/` and `scripts/effects/`
- Architectural prefabs in `scenes/environment/`
- Assets (sprites, audio, fonts, shaders, tilesets) are in `assets/`
- Procedural generation tools in `tools/`
- Test suites in `tests/`

## Code Style Rules

- Use **snake_case** for variables, functions, signals, and file names
- Use **PascalCase** for class names and node names
- Use **SCREAMING_SNAKE_CASE** for constants and enums
- Prefix private functions/variables with underscore: `_process()`, `_velocity`
- Use **type hints** on all function parameters and return types
- Use `@export` for inspector-configurable properties
- Use `@onready` for node references instead of `get_node()` in `_ready()`
- Keep scripts under 300 lines — split into components if growing larger
- Document `@export` vars and public functions with `##` doc comments
- **Update documentation after bigger changes** — when you add/modify major gameplay systems, inputs, UI/UX, missions, autoloads, or resources, update the relevant `.md` files in the same change (see `docs/CONVENTIONS.md`).

## Common Godot 4 Patterns

```gdscript
# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# Exported properties
@export var speed: float = 200.0
@export var max_health: int = 100

# Signals
signal health_changed(new_health: int)
signal died

# Type-hinted functions
func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        died.emit()

# Input handling
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("shoot"):
        _fire_weapon()
```

## Input Map Actions

| Action | Default Binding | Description |
|--------|----------------|-------------|
| move_up | W | Move up |
| move_down | S | Move down |
| move_left | A | Move left |
| move_right | D | Move right |
| shoot | Left Mouse Button | Fire weapon |
| interact | E / Right Mouse Button | Pick up items, interact |
| reload | R | Reload weapon |
| dodge | Space | Dodge-roll |
| weapon_1 | 1 | Switch to weapon slot 1 |
| weapon_2 | 2 | Switch to weapon slot 2 |
| weapon_3 | 3 | Switch to weapon slot 3 (pistol) |
| pause | Escape | Pause menu |

## What NOT to Do

- **Do NOT use Godot 3 APIs** — this is Godot 4 (e.g., use `CharacterBody2D` not `KinematicBody2D`, `@export` not `export`, `@onready` not `onready`)
- **Do NOT create .cs files** — this is a GDScript-only project
- **Do NOT add multiplayer/networking** — this is a single-player game
- **Do NOT use procedural generation** for mission layout — missions are hand-crafted authored levels
- **Do NOT overcomplicate enemy AI** — simple state machines, arcade-style behavior
- **Do NOT add microtransactions or F2P mechanics** — this is a premium single-player game

## Design Spec

The full game design document is at:
`docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md`

Always consult this spec before implementing gameplay features.

## Implementation Status & Roadmap

### Current Status: All Phases (1–5) Complete

1. **Phase 1: Core Vertical Slice (Complete)**
   - Player movement, 360-degree mouse aiming, dodge-roll with invulnerability frames, screen shake.
   - Weapon inventory (slots 1–3), reload cycle, weapon types (pistol, rifle, shotgun, sniper, RPG).
   - Projectile pooling and damage pipeline.
   - Core enemies (Rifleman, Shotgunner), basic pickups (HealthKit, AmmoCrate, WeaponPickup).
   - Core autoloads (`GameManager`, `ScoreManager`, `SaveManager`), UI menus, HUD, pause, mission flow.
   - Mission 1 staging baseline with sandbag cover and holdout waves.

2. **Phase 2: Heavy Enemies & Emplacements (Complete)**
   - Sniper (`Sniper.gd`, `Sniper.tscn`): Aim telegraph red laser, high precision damage.
   - Grenadier / RPG Infantry (`Grenadier.gd`, `Grenadier.tscn`): Rocket projectiles with Area2D splash radius.
   - Machine Gunner (`MachineGunner.gd`, `MachineGunner.tscn`): Sustained suppressing fire with spread cone.
   - Officer (`Officer.gd`, `Officer.tscn`): Speed & fire-rate buff aura for nearby infantry.
   - B-80 APC → **SVK M-80 IFV** (`Apc.gd`, `Apc.tscn`): Layer 7 vehicle, rotating machine gun turret, infantry deployment with `order_assault`, SVK tricolor hull marking.
   - T-55 Tank (`Tank.gd`, `Tank.tscn`): Boss vehicle, rotating cannon turret, rear engine weak point (3x dmg), weak-point double-damage guard.
   - Sandbag Bunker / MG Nest (`Bunker.gd`, `Bunker.tscn`) & Mortar Pit (`Mortar.gd`, `Mortar.tscn`).

3. **Phase 3: Full 5-Mission Campaign (Complete)**
   - Mission 1: "First Thunder" — Aug 4 dawn, Lika/Gospić staging grounds holdout vs SVK 15th Lika Corps.
   - Mission 2: "Breaking the Line" — Aug 4-5, Medak axis fortified bunker line assault vs SVK 15th Lika Corps.
   - Mission 3: "Open Road" — Aug 5, Sinj/Vrlika approach; intercept SVK M-80 convoy, T-55, liberate Kijevo/Vrlika.
   - Mission 4: "The Heart" — Aug 5 afternoon, Knin street-by-street clearing vs Knindže, mortar battery, fortress approach.
   - Mission 5: "Victory" — Aug 5 evening, Knin Fortress climb, T-55 boss, courtyard clear, raise the šahovnica.

4. **Phase 4: Audio System (Complete)**
   - `SoundManager.gd` autoload: Gunfire SFX, shell casing clatters, impact sounds, low-pass filter on low HP.

5. **Phase 5: Visual Polish & War-Journal Aesthetic (Complete)**
   - **Asset Generation Pipeline**: `tools/generate_war_journal_assets.py` procedurally produces 42 hand-inked, cross-hatched, watercolor-washed sprites (characters, vehicles, terrain, props, VFX, UI). Verified by `tests/test_assets_generation.py`.
   - **Persistent Decal System**: `DecalManager.gd` stamps blood splatter, scorch marks, spent brass casings, and vehicle treads capped at 250 FIFO entries with zero memory leaks.
   - **Combat VFX & Dynamic 2D Lighting**: `CombatVfx.gd` and `VfxComponents.gd` spawn multi-stage charcoal explosion bursts, weapon-specific muzzle flashes, ricochet sparks, and transient `PointLight2D` illumination.
   - **Modular Character Rigs**: Player and all 6 enemy types feature independent `ShadowSprite`, 4-frame animated `LegsSprite` aligned with movement direction, and 360-degree `TorsoContainer` with weapon recoil kickback, dodge tumble, and casualty decal stamping.
   - **Armored Vehicles & Destruction**: APC and Tank feature independent rotating turrets, continuous tread stamping, rear weak points, and destruction states with burning wreck sprites, fire/smoke emitters, and disabled collision.
   - **Mission Maps & Environments**: All 5 campaign missions upgraded with unique seamless 512x512 illustrated terrain, per-mission `CanvasModulate` atmospheric lighting, and hand-inked architectural prefabs (`BuildingTileRoof`, `BuildingTinRoof`, `BunkerEmplacement`).
   - **Paper Overlay Shader & UI Polish**: Fullscreen `paper_overlay.gdshader` with parchment grain, vignette, chromatic aberration combat shock, hand-drawn HUD frames, minimap compass, and ink-stamped mission completion reports.

6. **Polish Elevation Pass (Complete)**
   - Magazine + reserve ammo economy; wired enemy `detection_range`; Mission 5 stage gating.
   - Enemy projectile pool; Sniper LOS; per-type combat behaviors; sequential mission objectives.
   - Per-weapon/impact audio, music crossfade, journal Main Menu/Pause, HUD slots/toasts, per-mission ranks.
   - Minimap/zoom throttle, muzzle-light caps, FX cleanup between missions.

7. **Authenticity Overhaul (Complete — 6 Sep 2026)**
   - `FactionResource` system: HV (Croatian) vs SVK (Serbian Krajina) identity wired into enemies, vehicles, player, briefing UI, minimap.
   - All 5 briefings rewritten with real Oluja chronology, HV brigades (9th Guards "Vukovi", 4th Guards, 118th), SVK corps (15th Lika, 7th Dalmatian, Knindže), sectors, dates, battle cries.
   - Narrative debrief paragraphs on results screen; `GameManager.MISSION_META` exposes sector/brigade/SVK-corp/date.
   - Visuals: proper 5×5 šahovnica flag, SVK tricolor + insignia, SVK armbands, bearded militia, HV brigade patch; M4 terrain relabeled Petrinja → Knin.
   - B-80 APC renamed to SVK M-80 IFV; M75 grenade named; `Škorpion` diacritic fixed; `SoundManager.play_voice_line()`.
   - Bug fixes: tank weak-point double-damage, sniper respawn i-frames, dry-fire, shotgun pellet loss, enemy pool cap, steering fallback, rocket layer filter, bunker hit direction, APC deploy assault order, M4/M5 HUD sync, Officer aura, burst tokens, accuracy scoring, settings persistence, SaveManager merge, burning-wreck cap. See `docs/authenticity-overhaul-2026-09-06.md`.

8. **Visual, Shooting & Content Overhaul (Complete — 7 Sep 2026)**
   - M70 full-auto + spread bloom/recovery (`bloom_changed`); OS cursor hides while PLAYING; projectile pool pre-check trims pellets instead of wasting ammo.
   - New weapons: **M72 RPK** (LMG), **Zastava M76** (DMR), **M80 "Zolja"** (disposable one-shot rocket, auto-discards via `is_disposable`/`weapon_discarded`).
   - Per-weapon `held_sprite` on `WeaponResource` wired to `Player.WeaponSprite`; baked torso rifle slimmed; brass ejects from `BrassMarker`.
   - `Crosshair.gd` rewritten: dual-tone high-contrast reticles per weapon, live bloom ring, hit/kill marker pulses (via `ScoreManager.hit_registered`/`kill_registered`).
   - Flags regenerated at 96×48 2:1 (crowned šahovnica, SVK tricolor) with pixel-assertion tests; M5 flag-raise tweened.
   - Density pass on all 5 missions: terrain detail, scatter props, buildings with walls, new pickups (ArmorVest, grenades, RPK/M76/Zolja), camera `max_zoom` clamp.
   - Tracer bullet sprites, muzzle smoke, ambient war layer, muzzle-flash `z_index` fix; PaperOverlay below HUD; HUD bottom bar re-anchored.
   - Bug audit: faction-tint restore on hit flash, checkpoint-after-difficulty-kit, M2 reinforcement timing, 2.5s enemy pursuit grace, `minf` accuracy, freed-node timer guards, pistol ammo redirect. See `docs/visual-combat-overhaul-2026-09-07.md`.

## Testing & Verification

Run the master visual test suite and individual verification suites using the Godot headless console:

```powershell
# Run all 11 test suites sequentially via Python runner
python tools/run_visual_tests.py

# Overhaul regression suite (run WITHOUT --quit; it self-quits after timer awaits)
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tests/test_overhaul_regressions.gd

# Master visual test runner (headless Godot compilation check)
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/run_all_visual_tests.gd --quit

# Individual visual test suites
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_decal_manager.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_combat_vfx.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_character_rigs.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_vehicles_visual.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_missions_visual.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_ui_visual.gd --quit

# Asset generator unit tests
pytest tests/test_assets_generation.py

# Regenerate all 42 war-journal assets
python tools/generate_war_journal_assets.py
```

