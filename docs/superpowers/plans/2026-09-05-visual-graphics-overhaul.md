# Visual & Graphics Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Operation Storm from its initial prototype state into an authentic War-Journal & Military Cartography aesthetic with modular 2D animated character rigs, detailed vehicles with rotating turrets, illustrated tactical environments replacing placeholder shapes, visceral multi-stage combat VFX, persistent decals, atmospheric dynamic 2D lighting, and hand-drawn UI polish.

**Architecture:** A Python asset generation pipeline creates hand-inked sprites, seamless field-map terrains, and props. A new `DecalManager` pools and recycles battlefield decals (ink blood, scorches, casings, tire treads). Characters adopt a 3-layer modular rig (`ShadowSprite`, `LegsSprite` walk cycle, and 360° `TorsoContainer` with weapon recoil), vehicles feature independent turrets and wreck states, and all 5 missions receive dedicated terrain themes, illustrated structures, and `CanvasModulate` atmospheric day/night grading.

**Tech Stack:** Godot 4.3+ (GDScript), Python 3.10+ (Pillow 12.2.0), GLSL CanvasItem Shaders, Godot 2D Dynamic Lighting (`PointLight2D`, `CanvasModulate`), `GPUParticles2D`.

## Global Constraints

- **Engine**: Godot 4.x (CharacterBody2D, GDScript only, type hints on all functions, snake_case methods).
- **Art Aesthetic**: War-Journal style (hand-drawn ink outlines, paper parchment texture, cross-hatching, charcoal smoke, ink-wash blood).
- **Collision Layers**: 1: Player, 2: Enemies, 3: PlayerBullets, 4: EnemyBullets, 5: Pickups, 6: Environment, 7: Vehicles.
- **Performance**: Decal pool capped at 250 items with FIFO recycling; dynamic point lights transient (≤0.25s) or limited to active emitters.

---

### Task 1: War-Journal High-Definition Asset Generation Tool & Sprite Library

**Files:**
- Create: `tools/generate_war_journal_assets.py`
- Test: `tests/test_assets_generation.py`
- Output Assets:
  - `assets/sprites/characters/player_torso.png` (48×48)
  - `assets/sprites/characters/enemy_rifleman_torso.png` (48×48)
  - `assets/sprites/characters/enemy_shotgunner_torso.png` (48×48)
  - `assets/sprites/characters/enemy_mg_torso.png` (48×48)
  - `assets/sprites/characters/enemy_sniper_torso.png` (48×48)
  - `assets/sprites/characters/enemy_officer_torso.png` (48×48)
  - `assets/sprites/characters/enemy_grenadier_torso.png` (48×48)
  - `assets/sprites/characters/soldier_legs_sheet.png` (128×32, 4 frames)
  - `assets/sprites/characters/soldier_shadow.png` (32×16)
  - `assets/sprites/characters/casualty_decals.png` (64×64)
  - `assets/sprites/vehicles/apc_hull.png` (128×64)
  - `assets/sprites/vehicles/apc_turret.png` (48×32)
  - `assets/sprites/vehicles/apc_wreck.png` (128×64)
  - `assets/sprites/vehicles/tank_hull.png` (160×96)
  - `assets/sprites/vehicles/tank_turret.png` (112×48)
  - `assets/sprites/vehicles/tank_wreck.png` (160×96)
  - `assets/sprites/terrain/terrain_staging.png` (512×512)
  - `assets/sprites/terrain/terrain_trenches.png` (512×512)
  - `assets/sprites/terrain/terrain_highway.png` (512×512)
  - `assets/sprites/terrain/terrain_urban.png` (512×512)
  - `assets/sprites/terrain/terrain_fortress.png` (512×512)
  - `assets/sprites/props/building_roof_tiles.png` (160×120)
  - `assets/sprites/props/building_roof_tin.png` (140×100)
  - `assets/sprites/props/bunker_concrete.png` (96×72)
  - `assets/sprites/props/sandbag_straight.png` (64×24)
  - `assets/sprites/props/sandbag_corner.png` (48×48)
  - `assets/sprites/props/ammo_crate_wooden.png` (32×32)
  - `assets/sprites/props/fuel_drum.png` (28×28)
  - `assets/sprites/props/barbed_wire.png` (64×20)
  - `assets/sprites/props/tree_ink_sketch.png` (80×80)
  - `assets/sprites/vfx/muzzle_flash_m70.png` (32×32)
  - `assets/sprites/vfx/muzzle_flash_shotgun.png` (48×32)
  - `assets/sprites/vfx/explosion_charcoal.png` (64×64)
  - `assets/sprites/vfx/shell_casing_rifle.png` (8×4)
  - `assets/sprites/vfx/shell_casing_shotgun.png` (8×6)
  - `assets/sprites/vfx/blood_splatter_decals.png` (64×64)
  - `assets/sprites/vfx/scorch_mark.png` (64×64)
  - `assets/sprites/ui/paper_parchment_bg.png` (512×512)
  - `assets/sprites/ui/hud_health_frame.png` (220×32)
  - `assets/sprites/ui/hud_ammo_frame.png` (180×44)
  - `assets/sprites/ui/minimap_compass.png` (48×48)
  - `assets/sprites/ui/stamp_mission_complete.png` (160×64)

**Interfaces:**
- Consumes: Python standard library, PIL (Pillow).
- Produces: High-resolution RGBA PNG files in `assets/sprites/` across all subdirectories with hand-inked line work, cross-hatching, and transparent backgrounds.

- [ ] **Step 1: Write the failing test**

```python
# tests/test_assets_generation.py
import os
import unittest
from PIL import Image

REQUIRED_ASSETS = [
    ("assets/sprites/characters/player_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_rifleman_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_shotgunner_torso.png", (48, 48)),
    ("assets/sprites/characters/soldier_legs_sheet.png", (128, 32)),
    ("assets/sprites/characters/soldier_shadow.png", (32, 16)),
    ("assets/sprites/vehicles/apc_hull.png", (128, 64)),
    ("assets/sprites/vehicles/apc_turret.png", (48, 32)),
    ("assets/sprites/vehicles/tank_hull.png", (160, 96)),
    ("assets/sprites/vehicles/tank_turret.png", (112, 48)),
    ("assets/sprites/terrain/terrain_staging.png", (512, 512)),
    ("assets/sprites/terrain/terrain_trenches.png", (512, 512)),
    ("assets/sprites/terrain/terrain_highway.png", (512, 512)),
    ("assets/sprites/terrain/terrain_urban.png", (512, 512)),
    ("assets/sprites/terrain/terrain_fortress.png", (512, 512)),
    ("assets/sprites/props/building_roof_tiles.png", (160, 120)),
    ("assets/sprites/props/bunker_concrete.png", (96, 72)),
    ("assets/sprites/props/sandbag_straight.png", (64, 24)),
    ("assets/sprites/vfx/explosion_charcoal.png", (64, 64)),
    ("assets/sprites/vfx/blood_splatter_decals.png", (64, 64)),
    ("assets/sprites/vfx/scorch_mark.png", (64, 64)),
    ("assets/sprites/ui/paper_parchment_bg.png", (512, 512)),
]

class TestWarJournalAssets(unittest.TestCase):
    def test_all_assets_exist_and_valid(self):
        for path, (exp_w, exp_h) in REQUIRED_ASSETS:
            self.assertTrue(os.path.exists(path), f"Asset missing: {path}")
            with Image.open(path) as img:
                self.assertEqual(img.mode, "RGBA", f"Asset not RGBA: {path}")
                self.assertEqual(img.size, (exp_w, exp_h), f"Incorrect size for {path}: {img.size} vs {(exp_w, exp_h)}")

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest tests/test_assets_generation.py`  
Expected: FAIL with "Asset missing"

- [ ] **Step 3: Implement `tools/generate_war_journal_assets.py`**

Write the complete Python script using PIL (`Image`, `ImageDraw`, `ImageFilter`) to procedurally generate each war-journal asset category:
- Inked characters with helmet, shoulder straps, Croatian insignia, and weapon hands.
- 4-frame boot walk cycle spritesheet.
- 8-wheeled APC chassis and dual-barrel machine gun turret.
- T-55 tank hull with detailed road wheels, side skirts, and rifled cannon turret.
- Seamless 512×512 field-map textures with pencil contour lines, terrain patches, and tactical coordinate ticks.
- Architectural cross-hatched tile and tin roofs with soft ink drop shadows.
- Multi-stage charcoal explosion curls, blood splatters, scorch marks, and spent brass casings.
- Sketched UI parchment frames and military stamps.
Execute: `python tools/generate_war_journal_assets.py`

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m unittest tests/test_assets_generation.py`  
Expected: PASS (all assets generated with matching dimensions and RGBA mode)

- [ ] **Step 5: Commit**

```bash
git add tools/generate_war_journal_assets.py tests/test_assets_generation.py assets/sprites/
git commit -m "feat(assets): implement war-journal asset generator and generate sprite library"
```

---

### Task 2: Persistent Decal System (`DecalManager`)

**Files:**
- Create: `scripts/effects/DecalManager.gd`
- Create: `scenes/effects/DecalManager.tscn`
- Modify: `scenes/Main.tscn` (add DecalManager to scene tree beneath WorldContainer)
- Test: `tests/test_decal_manager.gd`

**Interfaces:**
- Consumes: `assets/sprites/vfx/blood_splatter_decals.png`, `scorch_mark.png`, `shell_casing_rifle.png`, `shell_casing_shotgun.png`
- Produces:
  - `DecalManager.stamp_blood(pos: Vector2, normal: Vector2 = Vector2.ZERO) -> void`
  - `DecalManager.stamp_scorch(pos: Vector2, scale_factor: float = 1.0) -> void`
  - `DecalManager.spawn_casing(pos: Vector2, eject_dir: Vector2, is_shotgun: bool = false) -> void`
  - `DecalManager.stamp_tread(pos: Vector2, rot: float, is_tank: bool = false) -> void`
  - `DecalManager.clear_decals() -> void`
  - Internal FIFO queue capped at `MAX_DECALS = 250` with smooth alpha fade on eviction.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_decal_manager.gd
extends SceneTree

func _init() -> void:
	var decal_script = load("res://scripts/effects/DecalManager.gd")
	if decal_script == null:
		print("FAIL: DecalManager.gd not found")
		quit(1)
		return
	var dm = Node2D.new()
	dm.set_script(decal_script)
	root.add_child(dm)
	
	# Test stamping up to 300 decals and assert cap at 250
	for i in range(300):
		dm.stamp_blood(Vector2(i * 2, i * 2))
	
	if dm.get_decal_count() > 250:
		print("FAIL: Decal count exceeded cap: %d" % dm.get_decal_count())
		quit(1)
		return
	
	# Test scorch and casing
	dm.stamp_scorch(Vector2(100, 100), 1.5)
	dm.spawn_casing(Vector2(200, 200), Vector2(1, 0), false)
	
	print("PASS: DecalManager test passed successfully")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_decal_manager.gd --quit`  
Expected: FAIL with "DecalManager.gd not found"

- [ ] **Step 3: Implement `scripts/effects/DecalManager.gd` and `DecalManager.tscn`**

Create `DecalManager.gd` implementing:
- `var _decals: Array[Node2D] = []`
- `const MAX_DECALS: int = 250`
- Pooling and instancing sprite nodes with random rotation, frame selection, and modulation.
- Ejected brass casings with lightweight bounce velocity tween (travel 30px, bounce, rest).
- FIFO queue recycling: when `_decals.size() >= MAX_DECALS`, pop front, tween modulate alpha to 0 in 0.3s, and `queue_free()`.
- Register in `Main.tscn` under `WorldContainer`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_decal_manager.gd --quit`  
Expected: PASS ("DecalManager test passed successfully")

- [ ] **Step 5: Commit**

```bash
git add scripts/effects/DecalManager.gd scenes/effects/DecalManager.tscn scenes/Main.tscn tests/test_decal_manager.gd
git commit -m "feat(vfx): implement persistent FIFO DecalManager for blood, scorch, and casings"
```

---

### Task 3: Combat VFX & Dynamic 2D Lighting Pipeline

**Files:**
- Modify: `scripts/effects/CombatVfx.gd`
- Test: `tests/test_combat_vfx.gd`

**Interfaces:**
- Consumes: `DecalManager`, `assets/sprites/vfx/muzzle_flash_m70.png`, `muzzle_flash_shotgun.png`, `explosion_charcoal.png`
- Produces:
  - `spawn_muzzle_flash(pos: Vector2, rot: float, weapon_type: String = "rifle") -> void`
  - `spawn_multi_stage_explosion(pos: Vector2, radius: float = 80.0) -> void`
  - `spawn_ricochet(pos: Vector2, normal: Vector2) -> void`
  - `spawn_burning_wreck_fire(pos: Vector2) -> Node2D`
  - Dynamic `PointLight2D` integration for muzzle flashes (0.05s flash) and explosions (0.25s expanding light pulse).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_combat_vfx.gd
extends SceneTree

func _init() -> void:
	var vfx_script = load("res://scripts/effects/CombatVfx.gd")
	var vfx = Node2D.new()
	vfx.set_script(vfx_script)
	root.add_child(vfx)
	
	if not vfx.has_method("spawn_multi_stage_explosion"):
		print("FAIL: spawn_multi_stage_explosion method missing")
		quit(1)
		return
	
	vfx.spawn_muzzle_flash(Vector2(50, 50), 0.0, "shotgun")
	vfx.spawn_multi_stage_explosion(Vector2(100, 100), 100.0)
	vfx.spawn_ricochet(Vector2(150, 150), Vector2(-1, 0))
	
	print("PASS: CombatVfx methods verified")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_combat_vfx.gd --quit`  
Expected: FAIL with "spawn_multi_stage_explosion method missing"

- [ ] **Step 3: Upgrade `scripts/effects/CombatVfx.gd`**

Implement:
- Multi-stage explosions:
  - Core fire flash: expanding orange/yellow circle with dynamic `PointLight2D` (energy 2.5, color amber).
  - Shockwave ring: fading expanding ring mesh.
  - Charcoal smoke plume: GPUParticles2D emitting textured black smoke clouds billowing upward and dispersing.
  - Debris and spark emitters: dirt chunks and high-velocity orange sparks.
  - Automatic `DecalManager.stamp_scorch(pos)` invocation.
- Weapon-specific muzzle flashes:
  - Scale and shape varies by `weapon_type`: pistol (small needle), rifle (starburst), shotgun (wide cone), RPG/cannon (huge blast).
  - Spawns transient 0.04s `PointLight2D` at the muzzle tip.
  - Ejects spent shell casing via `DecalManager.spawn_casing`.
- Ricochet spark bursts with debris particles.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_combat_vfx.gd --quit`  
Expected: PASS ("CombatVfx methods verified")

- [ ] **Step 5: Commit**

```bash
git add scripts/effects/CombatVfx.gd tests/test_combat_vfx.gd
git commit -m "feat(vfx): implement multi-stage charcoal explosions, dynamic point lights, and weapon flashes"
```

---

### Task 4: Modular Character Rigging for Player & Enemies

**Files:**
- Modify: `scenes/player/Player.tscn`, `scripts/player/Player.gd`
- Modify: `scenes/enemies/EnemyBase.tscn`, `scripts/enemies/EnemyBase.gd`
- Modify: `scripts/enemies/Rifleman.gd`, `scripts/enemies/Shotgunner.gd`, `scripts/enemies/MachineGunner.gd`, `scripts/enemies/Sniper.gd`, `scripts/enemies/Officer.gd`, `scripts/enemies/Grenadier.gd`
- Test: `tests/test_character_rigs.gd`

**Interfaces:**
- Consumes: `assets/sprites/characters/*`, `DecalManager`, `CombatVfx`
- Produces:
  - Modular node structure: `ShadowSprite`, `LegsSprite` (4-frame walk animation tracking velocity vector), `TorsoContainer` (360° mouse/target rotation), `BodySprite`, `WeaponSprite`, `MuzzleMarker`, `BrassMarker`.
  - Procedural weapon recoil kickback tween on fire.
  - Dodge-roll tumble animation (scale squash & shadow fade).
  - Death collapse animation and persistent casualty ground stamp.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_character_rigs.gd
extends SceneTree

func _init() -> void:
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	# Verify modular hierarchy
	if not player.has_node("LegsSprite") or not player.has_node("TorsoContainer") or not player.has_node("ShadowSprite"):
		print("FAIL: Player missing modular rig components")
		quit(1)
		return
	
	var enemy_scene = load("res://scenes/enemies/Rifleman.tscn")
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	
	if not enemy.has_node("LegsSprite") or not enemy.has_node("TorsoContainer"):
		print("FAIL: Enemy missing modular rig components")
		quit(1)
		return
		
	print("PASS: Character rig hierarchy verified")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_character_rigs.gd --quit`  
Expected: FAIL with "Player missing modular rig components"

- [ ] **Step 3: Implement modular character rigs in `Player` and `EnemyBase`**

1. Update `scenes/player/Player.tscn`:
   - Add `ShadowSprite` with `soldier_shadow.png`.
   - Add `LegsSprite` with `soldier_legs_sheet.png` (hframes=4).
   - Add `TorsoContainer` (Node2D) containing `BodySprite` (`player_torso.png`), `WeaponSprite`, `MuzzleMarker`, and `BrassMarker`.
2. Update `scripts/player/Player.gd`:
   - Animate `LegsSprite` frame and rotation based on velocity direction (`velocity.angle()`).
   - Rotate `TorsoContainer` toward `get_global_mouse_position()`.
   - Add weapon kickback tween in `TorsoContainer` on fire (-4px along X, recovers in 0.08s).
   - Animate `ShadowSprite` fade/scale during `dodge_roll`.
3. Update `scenes/enemies/EnemyBase.tscn` and `scripts/enemies/EnemyBase.gd`:
   - Implement the identical modular hierarchy for enemies.
   - Distinct torso sprites for Rifleman, Shotgunner, MG, Sniper, Officer, Grenadier.
   - On `die()`, spawn blood decal via `DecalManager.stamp_blood(global_position)`, play quick crumple tween, and stamp casualty decal before `queue_free()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_character_rigs.gd --quit`  
Expected: PASS ("Character rig hierarchy verified")

- [ ] **Step 5: Commit**

```bash
git add scenes/player/Player.tscn scripts/player/Player.gd scenes/enemies/ scripts/enemies/ tests/test_character_rigs.gd
git commit -m "feat(characters): implement modular 2D rig with independent legs, 360 aim, and recoil feedback"
```

---

### Task 5: Armored Vehicle Visual Polish & Destruction States

**Files:**
- Modify: `scenes/vehicles/Apc.tscn`, `scripts/vehicles/Apc.gd`
- Modify: `scenes/vehicles/Tank.tscn`, `scripts/vehicles/Tank.gd`
- Modify: `scripts/vehicles/VehicleBase.gd`
- Test: `tests/test_vehicles_visual.gd`

**Interfaces:**
- Consumes: `assets/sprites/vehicles/*`, `DecalManager`, `CombatVfx`
- Produces:
  - Independent 360° rotating turret cupola for APC and Tank.
  - Continuous tread/tire imprint decals left while traversing.
  - Destroyed state: hull swaps to blackened wreck sprite, turret dislodges, spawns persistent burning fire and billowing charcoal smoke.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_vehicles_visual.gd
extends SceneTree

func _init() -> void:
	var apc_scene = load("res://scenes/vehicles/Apc.tscn")
	var apc = apc_scene.instantiate()
	root.add_child(apc)
	
	var tank_scene = load("res://scenes/vehicles/Tank.tscn")
	var tank = tank_scene.instantiate()
	root.add_child(tank)
	
	if not apc.has_node("Turret") or not tank.has_node("Turret"):
		print("FAIL: Vehicles missing independent Turret node")
		quit(1)
		return
	
	if not apc.has_method("destroy_vehicle") or not tank.has_method("destroy_vehicle"):
		print("FAIL: VehicleBase destroy_vehicle missing")
		quit(1)
		return
		
	print("PASS: Vehicle visual architecture verified")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_vehicles_visual.gd --quit`  
Expected: FAIL with "Vehicles missing independent Turret node"

- [ ] **Step 3: Implement vehicle visual enhancements in `Apc`, `Tank`, and `VehicleBase`**

1. Update `scenes/vehicles/Apc.tscn`:
   - Hull Sprite using `apc_hull.png`.
   - `Turret` (Node2D) using `apc_turret.png` with `MuzzleMarker`.
   - Add wheel roll dust GPUParticles2D.
2. Update `scenes/vehicles/Tank.tscn`:
   - Hull Sprite using `tank_hull.png`.
   - `Turret` (Node2D) using `tank_turret.png` with heavy cannon `MuzzleMarker`.
   - Engine louvers weak point collision area marked at the rear.
3. Update `scripts/vehicles/VehicleBase.gd`, `Apc.gd`, `Tank.gd`:
   - Turret tracks player target smoothly (`look_at`).
   - Every 20px moved, stamps tread decal via `DecalManager.stamp_tread`.
   - Implement `destroy_vehicle()`: spawns massive explosion (`CombatVfx.spawn_multi_stage_explosion`), swaps hull to `wreck.png`, spawns burning fire loop (`CombatVfx.spawn_burning_wreck_fire`), and disables movement/collision.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_vehicles_visual.gd --quit`  
Expected: PASS ("Vehicle visual architecture verified")

- [ ] **Step 5: Commit**

```bash
git add scenes/vehicles/ scripts/vehicles/ tests/test_vehicles_visual.gd
git commit -m "feat(vehicles): implement rotating turrets, tread decals, and burning wreck destruction states"
```

---

### Task 6: Environment, Illustrated Structures & Mission Map Overhaul

**Files:**
- Create: `scenes/environment/BuildingTileRoof.tscn`
- Create: `scenes/environment/BuildingTinRoof.tscn`
- Create: `scenes/environment/BunkerEmplacement.tscn`
- Modify: `scenes/missions/Mission1.tscn`, `Mission2.tscn`, `Mission3.tscn`, `Mission4.tscn`, `Mission5.tscn`
- Test: `tests/test_missions_visual.gd`

**Interfaces:**
- Consumes: `assets/sprites/terrain/*`, `assets/sprites/props/*`
- Produces:
  - 5 themed missions with dedicated high-res seamless field map backgrounds.
  - `CanvasModulate` node in each mission defining time-of-day atmospheric grading.
  - Zero placeholder `ColorRect` buildings in Mission 4 (replaced with `BuildingTileRoof` and `BuildingTinRoof` prefabs containing ink drop shadows and collision shape).
  - Hand-inked sandbags, bunkers, wire coils, and Balkan pine trees placed across all missions.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_missions_visual.gd
extends SceneTree

func _init() -> void:
	for m in range(1, 6):
		var path = "res://scenes/missions/Mission%d.tscn" % m
		var scn = load(path)
		if scn == null:
			print("FAIL: Mission%d failed to load" % m)
			quit(1)
			return
		var inst = scn.instantiate()
		root.add_child(inst)
		
		# Check CanvasModulate
		if not inst.has_node("CanvasModulate"):
			print("FAIL: Mission%d missing CanvasModulate atmospheric lighting" % m)
			quit(1)
			return
		
		# For Mission 4, ensure no ColorRect nodes under Buildings
		if m == 4:
			var b_node = inst.get_node_or_null("Buildings")
			if b_node:
				for child in b_node.get_children():
					if child.has_node("ColorRect"):
						print("FAIL: Mission 4 still contains placeholder ColorRect buildings")
						quit(1)
						return
		inst.queue_free()
		
	print("PASS: All 5 missions verified with visual upgrades")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_missions_visual.gd --quit`  
Expected: FAIL with "Mission1 missing CanvasModulate atmospheric lighting"

- [ ] **Step 3: Implement architectural prefabs and update Missions 1 through 5**

1. Create `scenes/environment/BuildingTileRoof.tscn` and `BuildingTinRoof.tscn`:
   - StaticBody2D (collision_layer = 32).
   - Inked shadow Sprite2D offset south-east.
   - Roof Sprite2D using `building_roof_tiles.png` / `tin.png`.
   - CollisionShape2D matching building footprint.
2. Create `scenes/environment/BunkerEmplacement.tscn`:
   - StaticBody2D with `bunker_concrete.png` and sandbag reinforcement.
3. Update `scenes/missions/Mission1.tscn` through `Mission5.tscn`:
   - Replace ground `TextureRect` texture with corresponding `terrain_staging.png`, `terrain_trenches.png`, `terrain_highway.png`, `terrain_urban.png`, `terrain_fortress.png`.
   - Add `CanvasModulate` node with mission ambient hex colors (`#E8DCB8`, `#C4CCC4`, `#F2EBE0`, `#D0BDAA`, `#DEC0B0`).
   - In Mission 4: replace B1, B2, B3 `ColorRect` buildings with `BuildingTileRoof` and `BuildingTinRoof` instances.
   - Update sandbag and cover sprites across all missions to use `sandbag_straight.png`, `sandbag_corner.png`, and `barbed_wire.png`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_missions_visual.gd --quit`  
Expected: PASS ("All 5 missions verified with visual upgrades")

- [ ] **Step 5: Commit**

```bash
git add scenes/environment/ scenes/missions/ tests/test_missions_visual.gd
git commit -m "feat(maps): overhaul all 5 campaign missions with themed terrain, illustrated buildings, and CanvasModulate"
```

---

### Task 7: UI, Paper Overlay Shader & Screen Polish

**Files:**
- Modify: `assets/shaders/paper_overlay.gdshader`
- Modify: `scripts/ui/PaperOverlay.gd`
- Modify: `scenes/ui/HUD.tscn`, `scripts/ui/HUD.gd`
- Modify: `scripts/ui/Minimap.gd`
- Modify: `scenes/ui/BriefingScreen.tscn`, `scripts/ui/BriefingScreen.gd`
- Modify: `scenes/ui/ResultsScreen.tscn`, `scripts/ui/ResultsScreen.gd`
- Test: `tests/test_ui_visual.gd`

**Interfaces:**
- Consumes: `assets/sprites/ui/*`, upgraded `paper_overlay.gdshader`
- Produces:
  - Upgraded paper shader with paper parchment sampling, soft ink-bleed border edge feathering, edge moisture vignette, and combat chromatic shock pulse.
  - Sketched ink frames for Health bar, Ammo readout, and weapon silhouette badges.
  - Pinned field-map minimap with vintage compass rose.
  - Stamped official military report styling on Briefing and Results screens.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_ui_visual.gd
extends SceneTree

func _init() -> void:
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	
	if not hud.has_node("HealthFrame") or not hud.has_node("AmmoFrame"):
		print("FAIL: HUD missing sketched frames")
		quit(1)
		return
	
	var paper_shader = load("res://assets/shaders/paper_overlay.gdshader")
	if paper_shader == null:
		print("FAIL: paper_overlay.gdshader not found")
		quit(1)
		return
		
	var mat = ShaderMaterial.new()
	mat.shader = paper_shader
	# Test parameter binding
	mat.set_shader_parameter("shock_aberration", 0.02)
	
	print("PASS: UI visual architecture verified")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_ui_visual.gd --quit`  
Expected: FAIL with "HUD missing sketched frames"

- [ ] **Step 3: Implement shader and UI visual upgrades**

1. Upgrade `assets/shaders/paper_overlay.gdshader`:
   - Add uniforms: `uniform sampler2D paper_texture`, `uniform float ink_bleed`, `uniform float shock_aberration`.
   - Sample paper texture fibers and blend with screen color.
   - Implement chromatic aberration offset on R/B channels driven by `shock_aberration`.
2. Update `scripts/ui/PaperOverlay.gd`:
   - Bind `paper_parchment_bg.png` texture to shader material.
   - Add `trigger_combat_shock(intensity: float = 0.03)` tweening `shock_aberration` down to 0 in 0.1s.
3. Update `scenes/ui/HUD.tscn` and `scripts/ui/HUD.gd`:
   - Add `HealthFrame` with `hud_health_frame.png` and `AmmoFrame` with `hud_ammo_frame.png`.
   - Inked weapon silhouette display for active weapon.
4. Update `scripts/ui/Minimap.gd`:
   - Draw compass rose from `minimap_compass.png`, pencil grid lines, and inked blips.
5. Update `BriefingScreen.gd` and `ResultsScreen.gd`:
   - Background styled with parchment paper texture, photo clips, and stamped red ink "MISSION ACCOMPLISHED" / "KIA" seals.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/test_ui_visual.gd --quit`  
Expected: PASS ("UI visual architecture verified")

- [ ] **Step 5: Commit**

```bash
git add assets/shaders/ scripts/ui/ scenes/ui/ tests/test_ui_visual.gd
git commit -m "feat(ui): upgrade paper shader, sketched HUD frames, minimap compass, and stamped reports"
```

---

### Task 8: End-to-End Campaign Verification & Documentation Updates

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Create: `tests/run_all_visual_tests.gd`

**Interfaces:**
- Consumes: All completed visual subsystems (Tasks 1–7).
- Produces: Automated test suite execution verifying scenes, textures, shaders, and rigs without crashes; comprehensive documentation updates.

- [ ] **Step 1: Write `tests/run_all_visual_tests.gd` master test suite**

```gdscript
# tests/run_all_visual_tests.gd
extends SceneTree

func _init() -> void:
	print("=== Running Operation Storm Visual Overhaul Master Test Suite ===")
	
	var tests = [
		"res://tests/test_decal_manager.gd",
		"res://tests/test_combat_vfx.gd",
		"res://tests/test_character_rigs.gd",
		"res://tests/test_vehicles_visual.gd",
		"res://tests/test_missions_visual.gd",
		"res://tests/test_ui_visual.gd",
	]
	
	for t in tests:
		print("Testing: %s ..." % t)
		var scn_test = load(t)
		if scn_test == null:
			print("FAILED to load test: %s" % t)
			quit(1)
			return
			
	print("=== All visual test scenes load and compile cleanly! ===")
	quit(0)
```

- [ ] **Step 2: Run master test suite**

Run: `& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --headless --script tests/run_all_visual_tests.gd --quit`  
Expected: PASS

- [ ] **Step 3: Update `AGENTS.md` and `README.md`**

Update `AGENTS.md` to reflect:
- Completed Phase 5: Visual Polish & War-Journal Aesthetic.
- Architecture details for `DecalManager`, modular character rigs, dynamic lighting, and `tools/generate_war_journal_assets.py`.
Update `README.md` with visual feature highlights, screenshots/art guidelines, and asset generation commands.

- [ ] **Step 4: Commit and finalize**

```bash
git add AGENTS.md README.md tests/run_all_visual_tests.gd
git commit -m "docs: update AGENTS.md and README.md with visual overhaul systems and verify end-to-end"
```
