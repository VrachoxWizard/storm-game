# Claude Code — Project Implementation Guide

This file provides comprehensive instructions and roadmap context for **Claude Code** and other AI agents to continue implementing **Operation Storm**.

---

## 1. Project Overview & Current State

**Operation Storm** is a top-down 2D arcade shooter built in **Godot 4.3+** with **typed GDScript**, set during the Croatian Homeland War (Operation Storm / Oluja, August 1995).

### What Is Already Implemented (Phase 1 — Vertical Slice):
- **Player Controller** (`scripts/player/Player.gd`, `scenes/player/Player.tscn`):
  - WASD 8-directional movement with normalized speed.
  - Continuous mouse-aim rotation.
  - Spacebar dodge-roll (0.3s invincibility, 3x burst speed, transparency, 1.5s cooldown).
  - Health system with hit flashing and dynamic camera screen shake.
  - Checkpoint state save/restore cycle with weapon slots/ammo persistence.
- **Weapon System** (`scripts/weapons/WeaponResource.gd`, `scripts/player/WeaponManager.gd`):
  - 3 weapon slots: primary rifle, secondary pickup, permanent backup pistol.
  - Switching (keys 1, 2, 3), reloading (R), semi-auto and automatic fire.
  - 4 weapon resources created: Zastava M70 (`zastava_m70.tres`), PHP Pistol (`php_pistol.tres`), Hawk 12ga Shotgun (`hawk_shotgun.tres`), Skorpion vz.61 SMG (`skorpion_smg.tres`).
- **Projectile System** (`scripts/weapons/Projectile.gd`, `scenes/weapons/`):
  - 100-bullet pre-allocated object pool for player weapons.
  - Area2D projectile physics with distinct Player (`layer 3`, mask `2,6,7`) and Enemy (`layer 4`, mask `1,6`) layers.
  - Automatic cleanup on mission reload/exit.
- **Enemy AI State Machine** (`scripts/enemies/EnemyBase.gd`):
  - States: `PATROL` → `ALERT` → `CHASE` → `ATTACK` → `DEAD`.
  - **Rifleman** (`Rifleman.gd`, `Rifleman.tscn`): 3-round burst mid-range combatant.
  - **Shotgunner** (`Shotgunner.gd`, `Shotgunner.tscn`): Close-quarters rusher with 5-pellet spread.
- **Pickups** (`scripts/pickups/`, `scenes/pickups/`):
  - Health kits (+30 HP), Ammo crates (+15 ammo), and Weapon pickup slot swapping.
- **Autoload Singletons** (registered in `project.godot`):
  - `GameManager`: Flow coordination (`MENU` → `BRIEFING` → `PLAYING` → `PAUSED` → `RESULTS`).
  - `ScoreManager`: Kills, accuracy tracking, time tracking, score calculation, rank grades (`A`–`D`).
  - `SaveManager`: JSON persistence to `user://save_data.json`.
- **UI & Menus** (`scripts/ui/`, `scenes/ui/`):
  - Main Menu, Mission Briefing screen, In-game HUD (health, ammo, weapon name), Pause Menu, Results Screen.
- **Mission 1 ("First Thunder")** (`scenes/missions/Mission1.tscn`, `scripts/missions/MissionController.gd`):
  - 3-wave holdout scenario with perimeter spawners, sandbag cover barriers, and pickups.
- **2D Graphics & Launchers**:
  - Crisp pixel-art 2D sprites in `assets/sprites/` for player, enemies, bullets, pickups, terrain, and sandbags.
  - `Run_Game.bat` and `Open_In_Godot.bat` for instant testing.

---

## 2. Roadmap: Where to Proceed Next

Follow the game design spec (`docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md`) for detailed gameplay rules. Here are the prioritized implementation phases:

### Phase 2: Remaining Enemies, Heavy Units & Emplacements

Implement new enemy types inheriting from `EnemyBase` or vehicle/emplacement bases:

1. **Sniper Enemy** (`scenes/enemies/Sniper.tscn`, `scripts/enemies/Sniper.gd`):
   - Long detection/attack range (400px+).
   - Stationary while aiming; draws a visible red targeting laser line (`Line2D`) towards player for 1.5s before firing.
   - High damage (35 HP), slow fire rate (3s cooldown). High priority target for player.
2. **RPG Infantry** (`scenes/enemies/RpgInfantry.tscn`, `scripts/enemies/RpgInfantry.gd`):
   - Fires slow-moving rocket projectile (`scenes/weapons/RocketProjectile.tscn`).
   - Rocket explodes on impact with an Area2D splash radius dealing 30 area damage and triggering camera shake.
3. **Officer / Commander** (`scenes/enemies/Officer.tscn`, `scripts/enemies/Officer.gd`):
   - Armed with pistol/SMG; stays behind regular infantry.
   - Has a passive aura (`Area2D`) that buffs nearby enemies: +25% speed, +20% fire rate.
4. **Vehicles (Collision Layer 7)**:
   - `scripts/vehicles/VehicleBase.gd` (extends `CharacterBody2D` or `PathFollow2D`):
     - Heavy health pool (200-500 HP), immune to light pistol/SMG fire or takes reduced damage (armor threshold).
     - Destroyed state: records vehicle kill in `ScoreManager.record_vehicle_destroyed()`, spawns burning wreckage or drops pickups.
   - **B-80 APC** (`scenes/vehicles/Apc.tscn`):
     - Mounted machine gun turret that rotates independently towards player.
     - Spawns 3-4 infantry soldiers when stopping or taking damage.
   - **T-55 Tank** (`scenes/vehicles/Tank.tscn`):
     - Mini-boss / boss enemy.
     - Turret rotates slowly toward player; fires heavy explosive shell (high damage + screen shake).
     - Weak point: Rear engine takes 3x damage.
5. **Emplacements**:
   - **Sandbag Bunker / MG Nest** (`scenes/enemies/Bunker.tscn`):
     - Stationary fortified structure with heavy front armor; continuous suppressing fire in a 60-degree arc.
   - **Mortar Pit** (`scenes/enemies/Mortar.tscn`):
     - Fires indirect shells: shows red warning circle telegraph on ground for 1.5s, followed by explosion damage.

---

### Phase 3: Missions 2–5 & Authoring the Campaign

Add mission scenes in `scenes/missions/` and register them in `GameManager.MISSION_SCENES`:

1. **Mission 2: "The Breakthrough"** (`scenes/missions/Mission2.tscn`):
   - Setting: Fortified Krajina defense line with minefields and trenches.
   - Objectives: Neutralize 2 MG bunkers, eliminate sniper tower, breach fortified gate.
   - Features: Anti-personnel mine hazard (explodes if stepped on without dodge-roll).
2. **Mission 3: "Highway Ambush"** (`scenes/missions/Mission3.tscn`):
   - Setting: Rural highway surrounded by pine forest.
   - Objectives: Intercept and destroy a retreating enemy supply convoy (2 APCs + escorts) before they cross the map exit.
3. **Mission 4: "Urban Combat — Petrinja"** (`scenes/missions/Mission4.tscn`):
   - Setting: Ruined city streets, barricades, apartment buildings with interior sightlines.
   - Objectives: Clear street-by-street checkpoints, rescue isolated friendly squad, eliminate mortar battery.
4. **Mission 5: "The Fortress — Knin"** (`scenes/missions/Mission5.tscn`):
   - Setting: Historical Knin fortress hill summit.
   - Objectives: Multi-stage assault:
     - Stage 1: Climb fortress approaches under sniper and mortar fire.
     - Stage 2: Defeat the defending T-55 Tank boss.
     - Stage 3: Clear inner courtyard and raise the flag (triggers campaign victory cutscene/results).

---

### Phase 4: Audio System & Sound Design

Create `scripts/autoloads/SoundManager.gd` and register in `project.godot` `[autoload]`:

1. **Audio Buses** (`default_bus_layout.tres`):
   - Master, Music, SFX.
2. **Sound Effects**:
   - Weapon sounds: Rifle firing, pistol shot, shotgun blast, SMG burst, reload slide/click, dry fire click.
   - Impact sounds: Bullet hitting flesh, bullet ricochet off sandbag/metal, explosion thud.
   - Character feedback: Player dodge-roll whoosh, damage grunt, enemy death screams.
   - Pickups: Medkit zip, ammo reload rattle, weapon equip cocking sound.
3. **Audio Features**:
   - Low-pass audio filter when player health drops below 25% or during dodge-roll.
   - Volume sliders integrated into PauseMenu and Settings.
4. **Music**:
   - Title theme, tension ambient loop during patrol, dynamic combat action track during waves.

---

### Phase 5: War-Journal Art Style & Visual Polish

Align the visual presentation with the hand-drawn war-journal aesthetic:

1. **Parchment / Ink Post-Processing**:
   - Full-screen post-processing shader on `CanvasLayer` giving paper texture, subtle sepia vignette, and dark ink sketch outlines.
2. **Combat Particles (GPUParticles2D)**:
   - Muzzle flashes on gun firing.
   - Ejected brass shell casings bouncing on ground.
   - Dust/debris puffs on bullet wall impacts.
   - Blood splatters on enemy hits.
3. **Minimap / Radar**:
   - Top-right corner radar showing player (white dot), enemies (red dots), and objectives/pickups.
4. **Low Health Effects**:
   - Screen edges vignette pulsing red when health < 30%.

---

## 3. Critical Technical Rules & Godot 4 Conventions

When adding or modifying code, you **MUST** follow these rules without exception:

### 1. Engine & Language
- **Godot 4.x only** (never use Godot 3 APIs like `KinematicBody2D`, `yield()`, or `export var`).
- **GDScript only** — no C#, no external plugins.
- Keep all scripts under **300 lines**. Split into modular components if growing larger.

### 2. Static Typing & Class Names
- Godot 4 requires strict type safety. Always provide type hints on variables, parameters, and function return types:
  ```gdscript
  func take_damage(amount: int) -> void:
  var weapon: WeaponResource = weapon_manager.get_current_weapon()
  ```
- Any custom script intended to be used as a type by other scripts **must** declare `class_name` at the top (e.g. `class_name WeaponManager`, `class_name WeaponResource`).

### 3. Asset Pipeline & `.import` Manifests
- Whenever creating new `.png` or audio files in `assets/`, Godot requires `.import` files to register them.
- To generate missing `.import` manifests programmatically in headless environments, run:
  ```powershell
  & "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --editor --headless --quit --path .
  ```
- Always commit both the asset files and their corresponding `.import` files.

### 4. Collision Layers Cheat Sheet
Collision layers are 1-indexed bit positions (`value = 1 << (layer - 1)`):

| Layer | Name | Bitmask Value | Description |
|---|---|---|---|
| 1 | Player | 1 | Player character |
| 2 | Enemies | 2 | Enemy soldiers |
| 3 | PlayerBullets | 4 | Projectiles fired by player |
| 4 | EnemyBullets | 8 | Projectiles fired by enemies |
| 5 | Pickups | 16 | Health, ammo, weapons |
| 6 | Environment | 32 | Walls, buildings, sandbags, obstacles |
| 7 | Vehicles | 64 | Tanks, APCs, heavy machinery |

### 5. Signal-Driven Architecture
- Autoloads (`GameManager`, `ScoreManager`, `SaveManager`) emit signals for state changes.
- UI elements and controllers connect to signals; **never poll state per-frame in `_process()`**.

### 6. Testing & Running on Windows
- Game launcher: `Run_Game.bat`
- Editor launcher: `Open_In_Godot.bat`
- Godot console verification:
  ```powershell
  & "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --quit-after 10 --path .
  ```
