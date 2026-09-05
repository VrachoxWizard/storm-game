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
| GameManager | `scripts/autoloads/GameManager.gd` | Singleton — scene transitions, game state, mission flow |
| ScoreManager | `scripts/autoloads/ScoreManager.gd` | Singleton — kill tracking, accuracy, scoring, ranks |
| SaveManager | `scripts/autoloads/SaveManager.gd` | Singleton — mission unlock progress, high scores persistence |
| Player | `scripts/player/Player.gd` | CharacterBody2D — movement, rotation, health, dodge-roll |
| WeaponManager | `scripts/player/WeaponManager.gd` | Weapon slots, switching, firing, ammo management |
| EnemyBase | `scripts/enemies/EnemyBase.gd` | Base class for all enemies — state machine AI |

### Key Patterns

- **Autoload singletons** for global managers (GameManager, ScoreManager, SaveManager)
- **Inheritance** for enemy types — all extend `EnemyBase`
- **Composition** for weapons — `WeaponManager` manages weapon instances on the player
- **Signals** for loose coupling — objectives, pickups, and UI communicate via Godot signals
- **State machines** for enemy AI — simple enum-based (PATROL, ALERT, CHASE, ATTACK, DEAD)
- **Object pooling** for projectiles — reuse bullet nodes instead of instancing/freeing

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
- Assets (sprites, audio, fonts, tilesets) are in `assets/`

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
- **Do NOT use procedural generation** — missions are hand-crafted authored levels
- **Do NOT overcomplicate enemy AI** — simple state machines, arcade-style behavior
- **Do NOT add microtransactions or F2P mechanics** — this is a premium single-player game

## Design Spec

The full game design document is at:
`docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md`

Always consult this spec before implementing gameplay features.

## Implementation Status & Roadmap for Next Phases

### Current Status: Phase 1 Complete
- Full playable vertical slice is implemented and verified in Godot 4.3+.
- Features: Player (WASD, mouse-aim, dodge-roll, screen shake, checkpoints), Weapons (4 types, slots, reloading), Projectile pooling, Enemies (Rifleman, Shotgunner), Pickups (health, ammo, shotgun), Autoloads (GameManager, ScoreManager, SaveManager), UI (Menus, HUD, Pause, Results), Mission 1 (3-wave holdout, sandbag cover, terrain).
- Launchers: `Run_Game.bat` and `Open_In_Godot.bat`.

### Next Implementation Phases
1. **Phase 2: Heavy Enemies & Emplacements**
   - Sniper (`scenes/enemies/Sniper.tscn`, `scripts/enemies/Sniper.gd`): Red laser targeting telegraph, high damage.
   - RPG Infantry (`scenes/enemies/RpgInfantry.tscn`): Rocket projectile with Area2D splash radius.
   - Officer (`scenes/enemies/Officer.tscn`): Speed & fire-rate buff aura for nearby enemies.
   - B-80 APC (`scenes/vehicles/Apc.tscn`): Vehicle layer 7, rotating machine gun turret, deploys infantry.
   - T-55 Tank (`scenes/vehicles/Tank.tscn`): Boss vehicle, rotating cannon turret, rear engine weak point (3x dmg).
   - Sandbag Bunker / MG Nest (`scenes/enemies/Bunker.tscn`) & Mortar Pit (`scenes/enemies/Mortar.tscn`).
2. **Phase 3: Campaign Missions 2–5**
   - Mission 2: "The Breakthrough" (Lika front, minefield hazards, bunker clearing).
   - Mission 3: "Highway Ambush" (intercept retreating supply convoy).
   - Mission 4: "Urban Assault — Petrinja" (street-by-street clearing, tight urban sightlines).
   - Mission 5: "The Fortress — Knin" (summit assault, T-55 tank battle, flag raising).
3. **Phase 4: Audio System**
   - `SoundManager.gd` autoload: Gunfire SFX, shell casing clatters, impact sounds, low-pass filter on low HP.
4. **Phase 5: Visual Polish & War-Journal Aesthetic**
   - CanvasLayer paper sketch / ink outline shader, muzzle flashes, blood and dust particles, radar/minimap.

