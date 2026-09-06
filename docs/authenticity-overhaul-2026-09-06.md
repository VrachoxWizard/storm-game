# Authenticity Overhaul — 6 September 2026

This pass deepens the Operation Storm campaign into a fully authentic portrayal of Oluja (Aug 4-7, 1995) with explicit Croatian HV vs Serbian SVK (Republika Srpska Krajina) faction identity, and fixes a slate of gameplay bugs surfaced by the audit.

## 1. Faction Identity System

- New `scripts/factions/FactionResource.gd` (`class_name FactionResource`) with `side` (HV/SVK), `display_name`, `short_name`, `flag_texture`, `insignia_texture`, `uniform_tint`, `accent_color`, `unit_names`.
- New `resources/factions/hv_faction.tres` (Hrvatska vojska, šahovnica, olive-green) and `svk_faction.tres` (Srpska vojska Krajine, tricolor, darker olive).
- `EnemyBase` and `VehicleBase` gained `@export var faction: FactionResource` (defaults to SVK) and `unit_key`; `_apply_faction_visuals()` / `_apply_faction_mark()` render insignia/flag badges and uniform tints.
- `Player` gained `@export var faction` defaulting to HV.
- Minimap blip colors now follow faction accents (HV red, SVK blue).

## 2. Story & Briefings

- `MissionBriefings.gd` rewritten: each mission now carries `title`, `date`, `sector`, `hv_unit`, `svk_unit`, `description`, `debrief`.
  - M1 First Thunder — Aug 4 dawn, Lika/Gospić, HV 9th Guards "Vukovi" / 4th Guards vs SVK 15th Lika Corps.
  - M2 Breaking the Line — Aug 4-5, Medak axis, HV 9th Guards vs SVK 15th Lika Corps.
  - M3 Open Road — Aug 5, Sinj/Vrlika, HV armored spearhead vs SVK 7th Dalmatian Corps (M-80 + T-55).
  - M4 The Heart — Aug 5 afternoon, Knin streets, HV 118th Brigade / 9th Guards vs SVK Knindže.
  - M5 Victory — Aug 5 evening, Knin Fortress, raise the šahovnica.
- `BriefingScreen.gd` shows HV brigade patch + SVK tricolor intel icons and a metadata row (date · sector · HV unit · SVK unit).
- `ResultsScreen.gd` shows a narrative debrief paragraph per mission (`Briefings.get_debrief`).
- `GameManager.gd` exposes `MISSION_META` and `get_mission_meta()`.
- Mission controller HUD strings updated to reference real SVK units/locations (Gospić depot, Medak line, Kijevo/Vrlika, Knin streets, šahovnica).

## 3. Visuals

- `tools/generate_war_journal_assets.py`:
  - New `generate_croatian_flag()` — proper 5×5 red-white šahovnica shield on red/white/blue tricolor (replaces red/white bands).
  - New `generate_svk_flag()` — Serbian horizontal tricolor (red-blue-white).
  - New `generate_svk_insignia()` — SAO Krajina shield with tricolor bands.
  - New `generate_hv_insignia()` — compact HV šahovnica badge.
  - Enemy sprites: SVK tricolor armband on all enemy types; bearded officer/grenadier militia; darker SVK olive palette constants.
  - Player sprite: 5×5 šahovnica shoulder patch + 9th Guards "Vukovi" wolf-motif badge.
  - `generate_terrain_urban()` relabeled Petrinja → Knin (matches M4 briefing).
  - Stamp text `ZADATAK IZVRŠEN` → `ZADAĆA IZVRŠENA`.
- `tests/test_assets_generation.py` extended with 5 new faction asset entries (47 total).

## 4. Vehicles & Weapons

- `Apc.gd` renamed B-80 APC → SVK M-80 IFV; `unit_key = "apc"`.
- `Tank.gd` `unit_key = "tank"`.
- `Grenade.gd` named M75 (`WEAPON_NAME = "M75"`); `GrenadePickup.gd` doc updated; HUD gear label `M75:%d`.
- `skorpion_smg.tres` `weapon_name` `Skorpion vz.61` → `Škorpion vz.61`; `SoundManager.play_weapon_shoot` accepts both spellings.

## 5. Audio

- `SoundManager.play_voice_line(line_id)` remaps Croatian cues onto existing SFX: `naprijed`, `pokrivaj`, `za_dom`, `oluja`.
- `BriefingScreen` plays `naprijed` on mission start; `Mission5Controller` plays `oluja` on flag raise.
- `set_music_volume` / `set_sfx_volume` now call `SaveManager.save_data()` (settings persist immediately).

## 6. Bug Fixes

| ID | File | Fix |
|----|------|-----|
| W1 | `Tank.gd`, `Projectile.gd` | Removed duplicate `weak_point_area.area_entered.connect`; added `_weak_point_handled` guard on bullet + tank handler to prevent 6× double-damage. |
| E1 | `Sniper.gd` | Hitscan now checks `target._respawn_protection > 0` (respects 2s post-checkpoint protection). |
| P1 | `WeaponManager.gd` | `dry_fire` only plays when `reserve <= 0` (no dry-fire on valid reload from empty). |
| P2 | `Player.gd` | Shotgun pellets acquired before ammo decrement; refund on pool-full failure. Accuracy counts one shot per trigger pull. |
| W5 | `ProjectilePool.gd` | Enemy bullet pool hard cap 120; `acquire_enemy_bullet()` returns null when full. |
| E2 | `EnemySteering.gd` | Falls back to `desired` direction when all obstacle probes fail (no more freeze). |
| W3 | `RocketProjectile.gd` | `_on_area_entered` filters by collision layer (enemies/env/vehicles/player) — no detonation on non-solid areas. |
| E3 | `Bunker.gd`, `Projectile.gd` | `take_damage(amount, hit_from)` uses hit position, not bunker→player vector; bullets stamp `last_hit_from` meta on bunker. |
| E4 | `Apc.gd` | Deployed infantry now receive `order_assault(player)` (engage instead of idling in PATROL). |
| E5 | `Mission4Controller.gd` | Replaced hardcoded `_on_progress(0, 2)` with real `ObjectiveTracker` total (3 streets + mortars + approach). |
| E6 | `Mission5Controller.gd` | Tracker now mirrors only the tank objective; HUD stage text stays authoritative for approach/courtyard/flag. |
| E7 | `Officer.gd` | Replaced `get_script() == get_script()` with `node is Officer` (`class_name Officer` added). |
| E8 | `Rifleman.gd`, `MachineGunner.gd` | Burst callbacks carry a generation token; `_die()` bumps it so post-death pending bursts can't fire. |
| A1/A2 | `ScoreManager.gd`, `Player.gd`, `ExplosionHelper.gd` | One `record_shot_fired` per trigger pull; `ExplosionHelper.explode(..., from_player)` records hits for player explosions. |
| A3 | `SoundManager.gd` | Volume setters call `SaveManager.save_data()` immediately. |
| A4 | `SaveManager.gd` | `load_data()` merges saved dict with defaults (older saves keep new settings keys). |
| V3 | `CombatVfx.gd` | Burning-wreck emitters capped at 6 (`MAX_BURNING_WRECKS`); oldest freed FIFO. |
| P3 | `Player.gd` | `heal()` no longer triggers low-pass while dodging. |
| — | `Player.gd` | `restore_checkpoint()` adds null guards on rig nodes. |

## 7. Verification

- `pytest tests/test_assets_generation.py` — 3 passed (47 assets validated).
- `python tools/run_visual_tests.py` — all 9 suites passed their assertions without runtime errors.
  - Gameplay Reliability: 24/24 checks pass (including "Swept rear hit preserves tank weak-point multiplier" and "Weak point cannot count the same bullet twice").
  - Campaign Progression, Decal Manager, Combat VFX, Character Rigs, Vehicles, Environment, UI, Bullet Firing — all pass.
- Known limitation: Godot headless shutdown reports benign resource/ObjectDB warnings (pre-existing, documented in `docs/verification-2026-09-06.md`).
