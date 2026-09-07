# Claude Code — Project Implementation Guide

This file provides comprehensive instructions and roadmap context for **Claude Code** and other AI agents to continue implementing **Operation Storm**.

**Current status:** Phases 1–5, the Polish Elevation Pass, the Authenticity Overhaul (6 Sep 2026), and the Visual, Shooting & Content Overhaul (7 Sep 2026) are complete — M70 full-auto with spread bloom, rewritten high-visibility crosshair with hit/kill markers, three new era-correct weapons (M72 RPK, Zastava M76, disposable M80 "Zolja"), per-weapon held sprites, heraldic flag regeneration, a 5-mission density pass, and a bug audit with regression tests (`tests/test_overhaul_regressions.gd`, run without `--quit`). Canonical mission titles: First Thunder, Breaking the Line, Open Road, The Heart, Victory (`GameManager.MISSION_NAMES`). Each mission is anchored to real Oluja chronology via `GameManager.MISSION_META` (sector, HV unit, SVK unit, date). See `AGENTS.md`, `docs/ARCHITECTURE.md`, and `docs/visual-combat-overhaul-2026-09-07.md` for systems detail.

---

## 1. Project Overview & Current State

**Operation Storm** is a top-down 2D arcade shooter built in **Godot 4.3+** with **typed GDScript**, set during the Croatian Homeland War (Operation Storm / Oluja, August 1995). The player fights as a Croatian HV soldier against the Serbian SVK (Srpska vojska Krajine / Republika Srpska Krajina) through a 5-mission campaign.

### Faction Identity (Authenticity Overhaul — 6 Sep 2026)
- **FactionResource** (`scripts/factions/FactionResource.gd`) + `resources/factions/hv_faction.tres` / `svk_faction.tres` define HV (Croatian, šahovnica) and SVK (Serbian Krajina, tricolor) sides.
- `EnemyBase` and `VehicleBase` default to SVK; `Player` defaults to HV.
- All 5 briefings rewritten with real Oluja chronology, HV brigades (9th Guards "Vukovi", 4th Guards, 118th), SVK corps (15th Lika, 7th Dalmatian, Knindže), sectors, dates, and Croatian battle cries.
- B-80 APC renamed to **SVK M-80 IFV**; M75 grenade named; `Škorpion vz.61` diacritic fixed; `SoundManager.play_voice_line()`.
- Visuals: proper 5×5 šahovnica flag, SVK tricolor + insignia, SVK armbands, bearded militia, HV brigade patch.
- See `docs/authenticity-overhaul-2026-09-06.md` for the full change list and bug fixes.

### Objective Guidance (6 Sep 2026)
- Players always know the next step via world gold beacons (`ObjectiveMarker`), a screen-edge arrow with distance (`ObjectiveArrow`), and minimap gold blips (`"objective"` / `"flag"` groups).
- `ObjectiveTracker.get_current_targets()` + `objective_target_changed` drive `ObjectiveGuidance`, which mission controllers bind via `MissionHelpers.bind_objective_guidance()`.
- Mission 2 enforces bunker order (north → south → east breach) with per-bunker objectives and a visible `BREACH EAST` zone banner.
- Missions 3–5 mark APC/T-55/village, mortars/approach, and tank/flag respectively; Mission 1 holdout remains text-only (enemies come to the player).
- Headless coverage: `tests/test_objective_guidance.gd`.

### What Is Already Implemented (Phase 1 — Vertical Slice):
- **Player Controller** (`scripts/player/Player.gd`, `scenes/player/Player.tscn`):
  - WASD 8-directional movement with normalized speed.
  - Continuous mouse-aim rotation.
  - Spacebar dodge-roll (0.3s invincibility, 3x burst speed, transparency, 1.5s cooldown).
  - Health system with hit flashing and dynamic camera screen shake.
  - Checkpoint state save/restore cycle with weapon slots/ammo persistence.
- **Weapon System** (`scripts/weapons/WeaponResource.gd`, `scripts/player/WeaponManager.gd`):
  - 3 weapon slots: primary rifle, secondary pickup, permanent backup pistol.
  - Magazine + reserve ammo economy; reload draws from reserve; pistol unlimited.
  - Switching (keys 1, 2, 3), reloading (R), semi-auto and automatic fire.
  - Weapons: Zastava M70, PHP Pistol, Hawk 12ga, Škorpion vz.61 SMG, M48 Mauser, RPG-7, M75 hand grenade.
- **Projectile System** (`scripts/weapons/Projectile.gd`, `ProjectilePool.gd`):
  - Player pool (100) + shared enemy/vehicle pool under `Main/Projectiles`.
  - Area2D projectile physics with distinct Player (`layer 3`) and Enemy (`layer 4`) layers.
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

All planned phases (1–5) plus the Polish Elevation Pass and the Authenticity Overhaul are complete. The game is feature-complete and authentic to Operation Storm. Future work should focus on:

- Playtesting and difficulty tuning (per-mission rank targets in `ScoreManager.gd` are hardcoded).
- Additional voice-line audio assets (currently `play_voice_line()` remaps onto existing SFX).
- Broader 1991-1995 Homeland War scope (Vukovar, Maslenica, Medak Pocket, Flash) — currently only Oluja is covered.
- Localization pass (briefings are bilingual Croatian/English; HUD strings are English-only).

The original phase roadmap is preserved below for historical reference.

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

1. **Mission 2: "Breaking the Line"** (`scenes/missions/Mission2.tscn`):
   - Setting: Fortified defense line with bunkers.
   - Objectives: Destroy bunkers (ordered), then breach east. Reinforcements on bunker damage.
2. **Mission 3: "Open Road"** (`scenes/missions/Mission3.tscn`):
   - Setting: Rural highway.
   - Objectives: Stop APC convoy before escape, destroy T-55, liberate village.
3. **Mission 4: "The Heart"** (`scenes/missions/Mission4.tscn`):
   - Setting: Urban streets with building prefabs.
   - Objectives: Clear street segments, destroy mortars, reach fortress approach.
4. **Mission 5: "Victory"** (`scenes/missions/Mission5.tscn`):
   - Setting: Knin fortress summit.
   - Objectives: Approach climb → T-55 → courtyard → flag raise.

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
