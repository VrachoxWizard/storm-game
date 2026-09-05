# Operation Storm — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully playable vertical slice — core movement/shooting, weapon pickups, enemy AI, and Mission 1 ("First Thunder") as a complete level with briefing, gameplay, and results screens.

**Architecture:** Godot 4 project with autoload singletons (GameManager, ScoreManager, SaveManager) managing global state. Player is a CharacterBody2D with a child WeaponManager. Enemies inherit from a shared EnemyBase with a simple state machine. Projectiles use object pooling. UI is a persistent CanvasLayer with signals-driven HUD.

**Tech Stack:** Godot 4.x, GDScript, TileMap for levels

## Global Constraints

- Godot 4.x APIs only (NOT Godot 3 — `CharacterBody2D`, `@export`, `@onready`, `.emit()`)
- GDScript only — no `.cs` files, no GDExtension
- Type hints on ALL function parameters and return types
- snake_case for variables/functions, PascalCase for classes/nodes, SCREAMING_SNAKE_CASE for constants
- Scripts under 300 lines — split into child nodes if larger
- `@onready` for node references, `@export` for inspector properties
- Signals for cross-system communication — no direct node path references across systems
- Collision layers: Player=1, Enemies=2, PlayerBullets=3, EnemyBullets=4, Pickups=5, Environment=6, Vehicles=7
- All design decisions must align with the design spec at `docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md`

## File Structure

```
res://
├── project.godot
├── scenes/
│   ├── Main.tscn                    # Root scene — manages world + UI
│   ├── player/
│   │   └── Player.tscn              # CharacterBody2D + children
│   ├── enemies/
│   │   ├── EnemyBase.tscn           # Base enemy scene
│   │   ├── Rifleman.tscn            # Inherits EnemyBase
│   │   └── Shotgunner.tscn          # Inherits EnemyBase
│   ├── weapons/
│   │   └── Projectile.tscn          # Pooled bullet Area2D
│   ├── pickups/
│   │   ├── PickupBase.tscn          # Base pickup Area2D
│   │   ├── HealthKit.tscn           # Inherits PickupBase
│   │   ├── AmmoCrate.tscn           # Inherits PickupBase
│   │   └── WeaponPickup.tscn        # Inherits PickupBase
│   ├── ui/
│   │   ├── HUD.tscn                 # In-game overlay
│   │   ├── MainMenu.tscn            # Title screen
│   │   ├── BriefingScreen.tscn      # Journal-style mission briefing
│   │   ├── ResultsScreen.tscn       # Post-mission score/rank
│   │   └── PauseMenu.tscn           # Pause overlay
│   └── missions/
│       └── Mission1.tscn            # "First Thunder" level
├── scripts/
│   ├── autoloads/
│   │   ├── GameManager.gd           # Scene transitions, game state
│   │   ├── ScoreManager.gd          # Kill tracking, accuracy, scoring
│   │   └── SaveManager.gd           # Persistence to user://
│   ├── player/
│   │   ├── Player.gd                # Movement, rotation, health, dodge
│   │   └── WeaponManager.gd         # Weapon slots, switching, firing
│   ├── enemies/
│   │   ├── EnemyBase.gd             # State machine, shared behavior
│   │   ├── Rifleman.gd              # Rifleman-specific overrides
│   │   └── Shotgunner.gd            # Shotgunner-specific overrides
│   ├── weapons/
│   │   ├── WeaponResource.gd        # Resource class for weapon data
│   │   └── Projectile.gd            # Bullet movement, hit detection
│   ├── pickups/
│   │   ├── PickupBase.gd            # Base pickup logic
│   │   ├── HealthPickup.gd          # Health restore
│   │   ├── AmmoPickup.gd            # Ammo refill
│   │   └── WeaponPickup.gd          # Weapon swap/add
│   └── ui/
│       ├── HUD.gd                   # Health bar, ammo, weapon slots
│       ├── MainMenu.gd              # Menu navigation
│       ├── BriefingScreen.gd        # Mission intro display
│       ├── ResultsScreen.gd         # Score display, rank calculation
│       └── PauseMenu.gd             # Pause/resume/quit
├── resources/
│   └── weapons/                     # WeaponResource .tres files
│       ├── zastava_m70.tres
│       ├── php_pistol.tres
│       ├── skorpion_smg.tres
│       └── hawk_shotgun.tres
└── assets/
    ├── sprites/                     # Placeholder sprites initially
    ├── audio/
    └── fonts/
```

---

### Task 1: Project Setup & Godot Configuration

**Files:**
- Create: `project.godot`
- Create: `scenes/Main.tscn`

**Interfaces:**
- Produces: Runnable Godot project with input map, autoload registration points, Main.tscn as entry scene

- [ ] **Step 1: Create the Godot project**

Open Godot 4, create a new project in the `2d-arcade-shooter-desktop` directory. This generates `project.godot`. Set the main scene to `res://scenes/Main.tscn`.

- [ ] **Step 2: Configure the input map**

In Project Settings → Input Map, add these actions with their bindings:

| Action | Key/Event |
|--------|-----------|
| `move_up` | W |
| `move_down` | S |
| `move_left` | A |
| `move_right` | D |
| `shoot` | Left Mouse Button |
| `interact` | E, Right Mouse Button |
| `reload` | R |
| `dodge` | Space |
| `weapon_1` | 1 |
| `weapon_2` | 2 |
| `weapon_3` | 3 |
| `pause` | Escape |

- [ ] **Step 3: Configure collision layers**

In Project Settings → Layer Names → 2D Physics, set:

| Layer | Name |
|-------|------|
| 1 | Player |
| 2 | Enemies |
| 3 | PlayerBullets |
| 4 | EnemyBullets |
| 5 | Pickups |
| 6 | Environment |
| 7 | Vehicles |

- [ ] **Step 4: Create placeholder Main.tscn**

Create `scenes/Main.tscn` with a root `Node` named `Main`. This will be expanded in later tasks.

- [ ] **Step 5: Create the directory structure**

Create empty directories for the project structure:
```
scenes/player/
scenes/enemies/
scenes/weapons/
scenes/pickups/
scenes/ui/
scenes/missions/
scripts/autoloads/
scripts/player/
scripts/enemies/
scripts/weapons/
scripts/pickups/
scripts/ui/
resources/weapons/
assets/sprites/
assets/audio/
assets/fonts/
```

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: initialize Godot 4 project with input map and collision layers"
```

---

### Task 2: Player Movement & Rotation

**Files:**
- Create: `scenes/player/Player.tscn`
- Create: `scripts/player/Player.gd`

**Interfaces:**
- Consumes: Input map actions from Task 1 (`move_up`, `move_down`, `move_left`, `move_right`, `dodge`)
- Produces: `Player` scene (CharacterBody2D) with movement, rotation, health system, dodge-roll. Signals: `health_changed(new_health: int)`, `died`

- [ ] **Step 1: Create Player.tscn scene**

Create a new scene with this node structure:
```
Player (CharacterBody2D)
├── Sprite2D         # placeholder ColorRect or sprite
├── CollisionShape2D # CircleShape2D, radius ~16px
├── Camera2D         # centered on player
├── DodgeTimer (Timer) # one_shot=true, wait_time=1.5 (cooldown)
├── DodgeDurationTimer (Timer) # one_shot=true, wait_time=0.3 (invincibility)
└── HitFlashTimer (Timer) # one_shot=true, wait_time=0.1
```

Set the CharacterBody2D collision layer to 1 (Player) and collision mask to 2 (Enemies), 4 (EnemyBullets), 5 (Pickups), 6 (Environment).

- [ ] **Step 2: Write Player.gd**

```gdscript
extends CharacterBody2D

## Player character — movement, rotation, health, dodge-roll.

signal health_changed(new_health: int)
signal died

const DODGE_SPEED_MULTIPLIER: float = 3.0

@export var speed: float = 200.0
@export var max_health: int = 100

var health: int = max_health
var is_dodging: bool = false
var can_dodge: bool = true
var _dodge_direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var dodge_timer: Timer = $DodgeTimer
@onready var dodge_duration_timer: Timer = $DodgeDurationTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	health = max_health
	dodge_timer.timeout.connect(_on_dodge_cooldown_finished)
	dodge_duration_timer.timeout.connect(_on_dodge_duration_finished)
	hit_flash_timer.timeout.connect(_on_hit_flash_finished)


func _physics_process(_delta: float) -> void:
	_handle_rotation()
	_handle_movement()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge") and can_dodge and not is_dodging:
		_start_dodge()


func take_damage(amount: int) -> void:
	if is_dodging:
		return  # invincible during dodge

	health = clampi(health - amount, 0, max_health)
	health_changed.emit(health)
	_flash_hit()

	if health <= 0:
		died.emit()


func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health)


func _handle_rotation() -> void:
	look_at(get_global_mouse_position())


func _handle_movement() -> void:
	if is_dodging:
		velocity = _dodge_direction * speed * DODGE_SPEED_MULTIPLIER
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_dir * speed

	move_and_slide()


func _start_dodge() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		_dodge_direction = Vector2.RIGHT.rotated(rotation)
	else:
		_dodge_direction = input_dir.normalized()

	is_dodging = true
	can_dodge = false
	dodge_duration_timer.start()
	sprite.modulate.a = 0.5  # visual feedback


func _on_dodge_duration_finished() -> void:
	is_dodging = false
	sprite.modulate.a = 1.0
	dodge_timer.start()


func _on_dodge_cooldown_finished() -> void:
	can_dodge = true


func _flash_hit() -> void:
	sprite.modulate = Color.RED
	hit_flash_timer.start()


func _on_hit_flash_finished() -> void:
	sprite.modulate = Color.WHITE
```

- [ ] **Step 3: Test the player**

Add the Player scene to Main.tscn temporarily. Run the project (F5). Verify:
- WASD moves in 8 directions with normalized diagonals
- Mouse rotates the player
- Space triggers dodge-roll with speed burst, transparency, and cooldown
- Player collides with nothing yet (no environment) — just moves freely

- [ ] **Step 4: Commit**

```powershell
git add -A; git commit -m "feat: add player character with movement, rotation, and dodge-roll"
```

---

### Task 3: Weapon Resource & WeaponManager

**Files:**
- Create: `scripts/weapons/WeaponResource.gd`
- Create: `scripts/player/WeaponManager.gd`
- Create: `resources/weapons/zastava_m70.tres`
- Create: `resources/weapons/php_pistol.tres`
- Modify: `scenes/player/Player.tscn` — add WeaponManager child node

**Interfaces:**
- Consumes: Player scene from Task 2, input actions (`shoot`, `reload`, `weapon_1`, `weapon_2`, `weapon_3`)
- Produces: `WeaponResource` resource class (defines weapon stats), `WeaponManager` node (manages slots, switching, firing, ammo). Signals: `weapon_switched(weapon_resource: WeaponResource)`, `ammo_changed(current: int, max_ammo: int)`, `weapon_fired`

- [ ] **Step 1: Create WeaponResource.gd**

```gdscript
class_name WeaponResource
extends Resource

## Defines the stats and behavior of a single weapon type.

@export var weapon_name: String = ""
@export var damage: int = 10
@export var fire_rate: float = 0.2  ## seconds between shots
@export var max_ammo: int = 30
@export var reload_time: float = 1.5
@export var spread_angle: float = 0.0  ## radians of random spread
@export var bullet_speed: float = 600.0
@export var is_automatic: bool = false  ## hold to fire vs tap
@export var projectile_count: int = 1  ## >1 for shotgun
@export var is_pistol: bool = false  ## permanent slot, unlimited ammo
```

- [ ] **Step 2: Create weapon resource files**

Create `.tres` resource files for the starting weapons:

`resources/weapons/zastava_m70.tres`:
```
[gd_resource type="Resource" script_class="WeaponResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/weapons/WeaponResource.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_name = "Zastava M70"
damage = 15
fire_rate = 0.15
max_ammo = 30
reload_time = 1.8
spread_angle = 0.05
bullet_speed = 700.0
is_automatic = true
projectile_count = 1
is_pistol = false
```

`resources/weapons/php_pistol.tres`:
```
[gd_resource type="Resource" script_class="WeaponResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/weapons/WeaponResource.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_name = "PHP Pistol"
damage = 8
fire_rate = 0.25
max_ammo = -1
reload_time = 0.0
spread_angle = 0.03
bullet_speed = 600.0
is_automatic = false
projectile_count = 1
is_pistol = true
```

- [ ] **Step 3: Create WeaponManager.gd**

```gdscript
extends Node

## Manages weapon slots, switching, firing, and ammo for the player.

signal weapon_switched(weapon_resource: WeaponResource)
signal ammo_changed(current: int, max_ammo: int)
signal weapon_fired

const SLOT_COUNT: int = 3
const PISTOL_SLOT: int = 2  ## slot index for permanent pistol

@export var default_weapon: WeaponResource
@export var pistol_weapon: WeaponResource

var slots: Array[WeaponResource] = []
var ammo: Array[int] = []  ## current ammo per slot (-1 = unlimited)
var current_slot: int = 0
var can_fire: bool = true
var is_reloading: bool = false

@onready var fire_timer: Timer = $FireTimer
@onready var reload_timer: Timer = $ReloadTimer


func _ready() -> void:
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_cooldown_finished)
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_finished)

	# Initialize slots: [primary, secondary, pistol]
	slots.resize(SLOT_COUNT)
	ammo.resize(SLOT_COUNT)

	slots[0] = default_weapon
	ammo[0] = default_weapon.max_ammo if default_weapon else 0
	slots[1] = null
	ammo[1] = 0
	slots[PISTOL_SLOT] = pistol_weapon
	ammo[PISTOL_SLOT] = -1  # unlimited

	current_slot = 0
	_emit_current_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_1"):
		switch_to_slot(0)
	elif event.is_action_pressed("weapon_2"):
		switch_to_slot(1)
	elif event.is_action_pressed("weapon_3"):
		switch_to_slot(PISTOL_SLOT)
	elif event.is_action_pressed("reload"):
		_start_reload()


func _physics_process(_delta: float) -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return

	if weapon.is_automatic:
		if Input.is_action_pressed("shoot") and can_fire and not is_reloading:
			fire()
	else:
		if Input.is_action_just_pressed("shoot") and can_fire and not is_reloading:
			fire()


func get_current_weapon() -> WeaponResource:
	if current_slot < 0 or current_slot >= SLOT_COUNT:
		return null
	return slots[current_slot]


func fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return

	# Check ammo
	if ammo[current_slot] == 0:
		_start_reload()
		return

	# Consume ammo (skip if unlimited)
	if ammo[current_slot] > 0:
		ammo[current_slot] -= 1

	can_fire = false
	fire_timer.wait_time = weapon.fire_rate
	fire_timer.start()

	weapon_fired.emit()
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)


func switch_to_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	if slots[slot] == null:
		return
	if is_reloading:
		is_reloading = false
		reload_timer.stop()

	current_slot = slot
	can_fire = true
	_emit_current_state()


func add_weapon(weapon_res: WeaponResource, weapon_ammo: int) -> WeaponResource:
	## Adds a weapon to the first empty slot, or swaps with current.
	## Returns the displaced weapon (or null if slot was empty).
	for i in range(PISTOL_SLOT):  # only check slots 0 and 1
		if slots[i] == null:
			slots[i] = weapon_res
			ammo[i] = weapon_ammo
			switch_to_slot(i)
			return null

	# All slots full — swap with current (unless pistol)
	var swap_slot := current_slot if current_slot != PISTOL_SLOT else 0
	var old_weapon := slots[swap_slot]
	slots[swap_slot] = weapon_res
	ammo[swap_slot] = weapon_ammo
	switch_to_slot(swap_slot)
	return old_weapon


func add_ammo(amount: int) -> void:
	## Adds ammo to the currently held weapon.
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	ammo[current_slot] = mini(ammo[current_slot] + amount, weapon.max_ammo)
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)


func _start_reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	if ammo[current_slot] == weapon.max_ammo:
		return

	is_reloading = true
	reload_timer.wait_time = weapon.reload_time
	reload_timer.start()


func _on_reload_finished() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return
	ammo[current_slot] = weapon.max_ammo
	is_reloading = false
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)


func _on_fire_cooldown_finished() -> void:
	can_fire = true


func _emit_current_state() -> void:
	var weapon := get_current_weapon()
	if weapon:
		weapon_switched.emit(weapon)
		ammo_changed.emit(ammo[current_slot], weapon.max_ammo)
```

- [ ] **Step 4: Add WeaponManager to Player.tscn**

Add a child node to Player:
```
WeaponManager (Node)
├── FireTimer (Timer)   # one_shot=true
└── ReloadTimer (Timer) # one_shot=true
```

Attach `scripts/player/WeaponManager.gd`. Set the `default_weapon` export to `res://resources/weapons/zastava_m70.tres` and `pistol_weapon` to `res://resources/weapons/php_pistol.tres`.

- [ ] **Step 5: Test weapon switching**

Run the project. Verify:
- Press 1/2/3 to switch weapon slots (slot 2 should be empty initially)
- Press R to reload (check via print statements or debugger)
- Click to fire (no projectiles yet — just verify the signal fires and ammo decrements)

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: add WeaponResource and WeaponManager with slots, switching, and ammo"
```

---

### Task 4: Projectile System (Object Pool)

**Files:**
- Create: `scenes/weapons/Projectile.tscn`
- Create: `scripts/weapons/Projectile.gd`
- Modify: `scripts/player/Player.gd` — add `_on_weapon_fired()` to spawn projectiles via WeaponManager
- Modify: `scenes/Main.tscn` — add Projectiles container

**Interfaces:**
- Consumes: `WeaponManager.weapon_fired` signal, `WeaponResource` data (damage, bullet_speed, spread_angle, projectile_count)
- Produces: `Projectile` scene (Area2D) with `activate(pos: Vector2, rot: float, spd: float, dmg: int)` and `deactivate()` methods. Projectile pool container node in Main scene.

- [ ] **Step 1: Create Projectile.tscn**

Scene structure:
```
Projectile (Area2D)
├── Sprite2D         # small rectangle/circle, ~4x8px
├── CollisionShape2D # RectangleShape2D, ~4x8px
└── LifetimeTimer (Timer) # one_shot=true, wait_time=3.0
```

Set collision layer to 3 (PlayerBullets). Set collision mask to 2 (Enemies), 6 (Environment), 7 (Vehicles).

- [ ] **Step 2: Write Projectile.gd**

```gdscript
extends Area2D

## A single projectile. Managed by an object pool — never freed, only activated/deactivated.

var speed: float = 0.0
var damage: int = 0
var _active: bool = false

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	lifetime_timer.timeout.connect(deactivate)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	deactivate()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	position += Vector2.RIGHT.rotated(rotation) * speed * delta


func activate(pos: Vector2, rot: float, spd: float, dmg: int) -> void:
	global_position = pos
	rotation = rot
	speed = spd
	damage = dmg
	_active = true
	visible = true
	monitoring = true
	monitorable = true
	lifetime_timer.start()


func deactivate() -> void:
	_active = false
	visible = false
	monitoring = false
	monitorable = false
	lifetime_timer.stop()
	global_position = Vector2(-9999, -9999)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	deactivate()


func _on_area_entered(_area: Area2D) -> void:
	deactivate()
```

- [ ] **Step 3: Add projectile pool to Main.tscn and Player.gd**

In `Main.tscn`, add a `Node2D` child called `Projectiles`.

Update `Player.gd` — add a muzzle marker and projectile spawning:

Add to Player.tscn:
```
MuzzleMarker (Marker2D) # positioned at the gun tip, ~24px in front of center
```

Add to `Player.gd`:

```gdscript
@onready var weapon_manager: Node = $WeaponManager
@onready var muzzle: Marker2D = $MuzzleMarker

var _projectile_pool: Array[Area2D] = []
var _projectile_scene: PackedScene = preload("res://scenes/weapons/Projectile.tscn")
const POOL_SIZE: int = 100


func _ready() -> void:
	# ... existing code ...
	weapon_manager.weapon_fired.connect(_on_weapon_fired)
	_init_projectile_pool()


func _init_projectile_pool() -> void:
	var pool_container := get_tree().root.get_node("Main/Projectiles")
	for i in range(POOL_SIZE):
		var bullet: Area2D = _projectile_scene.instantiate()
		pool_container.add_child(bullet)
		_projectile_pool.append(bullet)


func _get_pooled_bullet() -> Area2D:
	for bullet in _projectile_pool:
		if not bullet.visible:
			return bullet
	return null


func _on_weapon_fired() -> void:
	var weapon := weapon_manager.get_current_weapon()
	if weapon == null:
		return

	for i in range(weapon.projectile_count):
		var bullet := _get_pooled_bullet()
		if bullet == null:
			break

		var spread := randf_range(-weapon.spread_angle, weapon.spread_angle)
		var fire_rotation := muzzle.global_rotation + spread
		bullet.activate(
			muzzle.global_position,
			fire_rotation,
			weapon.bullet_speed,
			weapon.damage
		)
```

- [ ] **Step 4: Test projectile system**

Run the project. Verify:
- Left-click fires projectiles from the muzzle point
- Projectiles travel in the aimed direction with slight spread
- Projectiles disappear after 3 seconds (lifetime)
- Holding click with Zastava M70 fires automatically
- Switching to pistol (key 3) fires single shots on click

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: add projectile system with object pooling"
```

---

### Task 5: Enemy Base & Rifleman

**Files:**
- Create: `scenes/enemies/EnemyBase.tscn`
- Create: `scripts/enemies/EnemyBase.gd`
- Create: `scenes/enemies/Rifleman.tscn`
- Create: `scripts/enemies/Rifleman.gd`

**Interfaces:**
- Consumes: Player global position (for chase/attack), Projectile damage via `take_damage(amount: int)`
- Produces: `EnemyBase` scene (CharacterBody2D) with state machine AI. Signals: `enemy_died(enemy: CharacterBody2D)`. `Rifleman` extends EnemyBase with specific stats and shoot behavior.

- [ ] **Step 1: Create EnemyBase.tscn**

Scene structure:
```
EnemyBase (CharacterBody2D)
├── Sprite2D             # placeholder colored rectangle
├── CollisionShape2D     # CircleShape2D, radius ~14px
├── DetectionArea (Area2D)
│   └── CollisionShape2D # CircleShape2D, radius ~200px (sight range)
├── AttackTimer (Timer)  # one_shot=true
└── StateTimer (Timer)   # one_shot=true, for alert timeout
```

Set collision layer to 2 (Enemies). Set collision mask to 1 (Player), 3 (PlayerBullets), 6 (Environment).
DetectionArea collision mask to 1 (Player) only.

- [ ] **Step 2: Write EnemyBase.gd**

```gdscript
extends CharacterBody2D

## Base class for all enemies. Simple state machine AI.

signal enemy_died(enemy: CharacterBody2D)

enum State { PATROL, ALERT, CHASE, ATTACK, DEAD }

@export var max_health: int = 50
@export var speed: float = 100.0
@export var attack_range: float = 150.0
@export var detection_range: float = 200.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0

var health: int = max_health
var current_state: State = State.PATROL
var target: CharacterBody2D = null
var _patrol_direction: Vector2 = Vector2.RIGHT
var _patrol_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var state_timer: Timer = $StateTimer


func _ready() -> void:
	health = max_health
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.one_shot = true
	state_timer.one_shot = true
	_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)


func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			pass  # no processing


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	health -= amount
	_flash_hit()

	if health <= 0:
		_die()
	elif current_state == State.PATROL:
		_enter_alert()


func _die() -> void:
	current_state = State.DEAD
	enemy_died.emit(self)
	# Drop pickups handled by mission spawner
	queue_free()


func _process_patrol(delta: float) -> void:
	_patrol_timer += delta
	if _patrol_timer > 3.0:
		_patrol_timer = 0.0
		_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)

	velocity = _patrol_direction * speed * 0.3
	look_at(global_position + _patrol_direction)
	move_and_slide()


func _process_alert(_delta: float) -> void:
	if target and is_instance_valid(target):
		look_at(target.global_position)
		_enter_chase()


func _process_chase(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return

	var dir := (target.global_position - global_position).normalized()
	velocity = dir * speed
	look_at(target.global_position)
	move_and_slide()

	var dist := global_position.distance_to(target.global_position)
	if dist <= attack_range:
		_enter_attack()


func _process_attack(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return

	look_at(target.global_position)
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range * 1.2:
		_enter_chase()


func _enter_alert() -> void:
	current_state = State.ALERT


func _enter_chase() -> void:
	current_state = State.CHASE


func _enter_attack() -> void:
	current_state = State.ATTACK
	_perform_attack()
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()


## Override in subclasses for specific attack behavior.
func _perform_attack() -> void:
	pass


func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACK:
		_perform_attack()
		attack_timer.start()


func _on_detection_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		target = body
		if current_state == State.PATROL:
			_enter_alert()


func _on_detection_body_exited(body: Node2D) -> void:
	if body == target:
		if current_state == State.CHASE or current_state == State.ATTACK:
			target = null
			current_state = State.PATROL


func _flash_hit() -> void:
	sprite.modulate = Color.RED
	get_tree().create_timer(0.1).timeout.connect(func() -> void: sprite.modulate = Color.WHITE)
```

- [ ] **Step 3: Create Rifleman.tscn and Rifleman.gd**

Inherit `EnemyBase.tscn` for `Rifleman.tscn`. Override the sprite color to distinguish it.

```gdscript
extends "res://scripts/enemies/EnemyBase.gd"

## Rifleman enemy — fires burst shots at the player.

var _burst_count: int = 0
const BURST_SIZE: int = 3
const BURST_INTERVAL: float = 0.15

@export var bullet_scene: PackedScene


func _perform_attack() -> void:
	_burst_count = 0
	_fire_burst()


func _fire_burst() -> void:
	if target == null or not is_instance_valid(target):
		return
	if current_state != State.ATTACK:
		return

	_spawn_enemy_bullet()
	_burst_count += 1

	if _burst_count < BURST_SIZE:
		get_tree().create_timer(BURST_INTERVAL).timeout.connect(_fire_burst)


func _spawn_enemy_bullet() -> void:
	## Spawns an enemy projectile toward the target.
	## Uses ScoreManager to track shots for accuracy.
	if bullet_scene == null:
		return

	var bullet: Area2D = bullet_scene.instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(bullet)

	var dir := (target.global_position - global_position).normalized()
	var spread := randf_range(-0.1, 0.1)
	bullet.activate(
		global_position,
		dir.angle() + spread,
		400.0,
		damage
	)
```

- [ ] **Step 4: Create enemy bullet variant**

Duplicate `Projectile.tscn` or modify `Projectile.gd` to support enemy bullets. The simplest approach: create a separate scene `scenes/weapons/EnemyProjectile.tscn` identical to `Projectile.tscn` but with collision layer 4 (EnemyBullets) and mask 1 (Player), 6 (Environment). Reuse the same `Projectile.gd` script.

- [ ] **Step 5: Add player to "player" group**

In `Player.gd` `_ready()`, add:
```gdscript
add_to_group("player")
```

- [ ] **Step 6: Test enemy behavior**

Place a Rifleman in Main.tscn near the player. Run and verify:
- Rifleman patrols randomly when player is far
- Rifleman detects and chases the player when in range
- Rifleman fires burst shots when in attack range
- Rifleman takes damage from player bullets and dies
- Rifleman flashes red on hit

- [ ] **Step 7: Commit**

```powershell
git add -A; git commit -m "feat: add EnemyBase state machine and Rifleman enemy type"
```

---

### Task 6: Shotgunner Enemy

**Files:**
- Create: `scenes/enemies/Shotgunner.tscn`
- Create: `scripts/enemies/Shotgunner.gd`

**Interfaces:**
- Consumes: `EnemyBase` from Task 5
- Produces: `Shotgunner` scene — rush enemy with close-range shotgun blast

- [ ] **Step 1: Create Shotgunner.gd**

```gdscript
extends "res://scripts/enemies/EnemyBase.gd"

## Shotgunner enemy — rushes player, fires spread shot at close range.

@export var bullet_scene: PackedScene

const SHOTGUN_PELLETS: int = 5
const SHOTGUN_SPREAD: float = 0.4  ## radians


func _ready() -> void:
	super._ready()
	speed = 150.0  # faster than rifleman
	max_health = 35  # less health
	health = max_health
	attack_range = 80.0  # must be close
	attack_cooldown = 1.5
	damage = 8  # per pellet


func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return
	if bullet_scene == null:
		return

	var dir := (target.global_position - global_position).normalized()
	var base_angle := dir.angle()

	for i in range(SHOTGUN_PELLETS):
		var bullet: Area2D = bullet_scene.instantiate()
		get_tree().root.get_node("Main/Projectiles").add_child(bullet)

		var spread := randf_range(-SHOTGUN_SPREAD, SHOTGUN_SPREAD)
		bullet.activate(
			global_position,
			base_angle + spread,
			350.0,
			damage
		)
```

- [ ] **Step 2: Create Shotgunner.tscn**

Inherit `EnemyBase.tscn`. Override sprite color (darker/red-tinted). Attach `scripts/enemies/Shotgunner.gd`. Set `bullet_scene` export to `res://scenes/weapons/EnemyProjectile.tscn`.

- [ ] **Step 3: Test shotgunner**

Place a Shotgunner in the scene. Verify:
- Moves faster than the Rifleman
- Rushes toward the player aggressively
- Fires a spread of pellets at close range
- Dies faster (lower HP)

- [ ] **Step 4: Commit**

```powershell
git add -A; git commit -m "feat: add Shotgunner enemy type"
```

---

### Task 7: Pickup System

**Files:**
- Create: `scenes/pickups/PickupBase.tscn`
- Create: `scripts/pickups/PickupBase.gd`
- Create: `scenes/pickups/HealthKit.tscn`
- Create: `scripts/pickups/HealthPickup.gd`
- Create: `scenes/pickups/AmmoCrate.tscn`
- Create: `scripts/pickups/AmmoPickup.gd`
- Create: `scenes/pickups/WeaponPickup.tscn`
- Create: `scripts/pickups/WeaponPickup.gd`

**Interfaces:**
- Consumes: `Player.heal(amount: int)`, `WeaponManager.add_ammo(amount: int)`, `WeaponManager.add_weapon(weapon: WeaponResource, ammo: int)`
- Produces: `PickupBase` scene (Area2D), concrete pickup types (HealthKit, AmmoCrate, WeaponPickup) that interact with the player on contact

- [ ] **Step 1: Create PickupBase.tscn and PickupBase.gd**

Scene structure:
```
PickupBase (Area2D)
├── Sprite2D         # pickup icon
└── CollisionShape2D # CircleShape2D, radius ~12px
```

Collision layer 5 (Pickups). Collision mask 1 (Player).

```gdscript
extends Area2D

## Base class for all pickups. Detects player collision and applies effect.

signal picked_up


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_apply_effect(body)
		picked_up.emit()
		queue_free()


## Override in subclasses to define what the pickup does.
func _apply_effect(_player: Node2D) -> void:
	pass
```

- [ ] **Step 2: Create HealthPickup.gd**

```gdscript
extends "res://scripts/pickups/PickupBase.gd"

## Restores player health on pickup.

@export var heal_amount: int = 30


func _apply_effect(player: Node2D) -> void:
	if player.has_method("heal"):
		player.heal(heal_amount)
```

Create `HealthKit.tscn` inheriting `PickupBase.tscn`. Set sprite to a white/red colored rectangle. Attach `HealthPickup.gd`.

- [ ] **Step 3: Create AmmoPickup.gd**

```gdscript
extends "res://scripts/pickups/PickupBase.gd"

## Refills ammo for the player's current weapon.

@export var ammo_amount: int = 15


func _apply_effect(player: Node2D) -> void:
	var weapon_manager: Node = player.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.has_method("add_ammo"):
		weapon_manager.add_ammo(ammo_amount)
```

Create `AmmoCrate.tscn` inheriting `PickupBase.tscn`. Set sprite to a green colored rectangle. Attach `AmmoPickup.gd`.

- [ ] **Step 4: Create WeaponPickup.gd**

```gdscript
extends "res://scripts/pickups/PickupBase.gd"

## Gives the player a new weapon, or swaps with current if slots are full.

@export var weapon_resource: WeaponResource
@export var ammo_count: int = -1  ## -1 means use weapon's max_ammo


func _apply_effect(player: Node2D) -> void:
	if weapon_resource == null:
		return

	var weapon_manager: Node = player.get_node_or_null("WeaponManager")
	if weapon_manager == null:
		return

	var actual_ammo := ammo_count
	if actual_ammo < 0:
		actual_ammo = weapon_resource.max_ammo

	var displaced: WeaponResource = weapon_manager.add_weapon(weapon_resource, actual_ammo)
	if displaced:
		_spawn_dropped_weapon(displaced)


func _spawn_dropped_weapon(_weapon: WeaponResource) -> void:
	## TODO: Spawn a new WeaponPickup at this position with the displaced weapon.
	## For Phase 1, displaced weapons are simply lost.
	pass
```

Create `WeaponPickup.tscn` inheriting `PickupBase.tscn`. Attach `WeaponPickup.gd`.

- [ ] **Step 5: Test pickups**

Place a HealthKit, AmmoCrate, and WeaponPickup in the scene. Verify:
- Walking over HealthKit restores health
- Walking over AmmoCrate refills current weapon ammo
- Walking over WeaponPickup adds weapon to empty slot or swaps

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: add pickup system with health, ammo, and weapon pickups"
```

---

### Task 8: Autoload Singletons (GameManager, ScoreManager, SaveManager)

**Files:**
- Create: `scripts/autoloads/GameManager.gd`
- Create: `scripts/autoloads/ScoreManager.gd`
- Create: `scripts/autoloads/SaveManager.gd`
- Modify: `project.godot` — register autoloads

**Interfaces:**
- Consumes: Enemy `enemy_died` signals, WeaponManager `weapon_fired` signal, Projectile hits
- Produces: `GameManager` (scene transitions, game state), `ScoreManager` (kill/accuracy/score tracking), `SaveManager` (JSON persistence to `user://save_data.json`)

- [ ] **Step 1: Create GameManager.gd**

```gdscript
extends Node

## Singleton — manages game state, scene transitions, and mission flow.

signal mission_started(mission_index: int)
signal mission_completed(mission_index: int)
signal game_paused(is_paused: bool)

enum GameState { MENU, BRIEFING, PLAYING, PAUSED, RESULTS }

var current_state: GameState = GameState.MENU
var current_mission: int = 0
var _previous_state: GameState = GameState.MENU

const MISSION_SCENES: Array[String] = [
	"res://scenes/missions/Mission1.tscn",
]


func start_mission(mission_index: int) -> void:
	current_mission = mission_index
	current_state = GameState.BRIEFING
	ScoreManager.reset()


func begin_gameplay() -> void:
	current_state = GameState.PLAYING
	mission_started.emit(current_mission)


func complete_mission() -> void:
	current_state = GameState.RESULTS
	mission_completed.emit(current_mission)
	SaveManager.save_mission_score(
		current_mission,
		ScoreManager.get_total_score(),
		ScoreManager.get_rank(),
		ScoreManager.elapsed_time
	)


func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		_previous_state = current_state
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit(true)
	elif current_state == GameState.PAUSED:
		current_state = _previous_state
		get_tree().paused = false
		game_paused.emit(false)


func return_to_menu() -> void:
	get_tree().paused = false
	current_state = GameState.MENU
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
```

- [ ] **Step 2: Create ScoreManager.gd**

```gdscript
extends Node

## Singleton — tracks kills, accuracy, time, and calculates score/rank.

var kills: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var vehicles_destroyed: int = 0
var emplacements_destroyed: int = 0
var deaths: int = 0
var elapsed_time: float = 0.0
var _is_tracking: bool = false

const KILL_POINTS: int = 100
const VEHICLE_POINTS: int = 500
const EMPLACEMENT_POINTS: int = 300
const NO_DEATH_BONUS: int = 1000
const TIME_BONUS_THRESHOLD: float = 300.0  ## seconds — bonus if under


func _process(delta: float) -> void:
	if _is_tracking:
		elapsed_time += delta


func reset() -> void:
	kills = 0
	shots_fired = 0
	shots_hit = 0
	vehicles_destroyed = 0
	emplacements_destroyed = 0
	deaths = 0
	elapsed_time = 0.0
	_is_tracking = false


func start_tracking() -> void:
	_is_tracking = true


func stop_tracking() -> void:
	_is_tracking = false


func record_kill() -> void:
	kills += 1


func record_shot_fired() -> void:
	shots_fired += 1


func record_shot_hit() -> void:
	shots_hit += 1


func record_vehicle_destroyed() -> void:
	vehicles_destroyed += 1


func record_emplacement_destroyed() -> void:
	emplacements_destroyed += 1


func record_death() -> void:
	deaths += 1


func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return float(shots_hit) / float(shots_fired) * 100.0


func get_total_score() -> int:
	var score: int = 0
	score += kills * KILL_POINTS
	score += vehicles_destroyed * VEHICLE_POINTS
	score += emplacements_destroyed * EMPLACEMENT_POINTS

	# Accuracy multiplier
	var acc := get_accuracy()
	if acc >= 80.0:
		score = int(score * 1.5)
	elif acc >= 60.0:
		score = int(score * 1.25)
	elif acc >= 40.0:
		score = int(score * 1.0)
	else:
		score = int(score * 0.75)

	# Time bonus
	if elapsed_time < TIME_BONUS_THRESHOLD:
		score += int((TIME_BONUS_THRESHOLD - elapsed_time) * 2.0)

	# No-death bonus
	if deaths == 0:
		score += NO_DEATH_BONUS

	return score


func get_rank() -> String:
	var score := get_total_score()
	var max_possible := 5000  ## rough estimate for Mission 1
	var percentage := float(score) / float(max_possible) * 100.0

	if percentage >= 90.0:
		return "A"
	elif percentage >= 70.0:
		return "B"
	elif percentage >= 50.0:
		return "C"
	else:
		return "D"
```

- [ ] **Step 3: Create SaveManager.gd**

```gdscript
extends Node

## Singleton — persists mission progress and high scores to user://save_data.json.

const SAVE_PATH: String = "user://save_data.json"

var data: Dictionary = {
	"missions_unlocked": 1,
	"high_scores": {},
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"screen_shake": true,
	},
}


func _ready() -> void:
	load_data()


func save_mission_score(mission_index: int, score: int, rank: String, time: float) -> void:
	var key := "mission_%d" % (mission_index + 1)
	var existing: Dictionary = data["high_scores"].get(key, {})

	if score > existing.get("score", 0):
		data["high_scores"][key] = {
			"score": score,
			"rank": rank,
			"time": time,
		}

	# Unlock next mission
	if mission_index + 2 > data["missions_unlocked"]:
		data["missions_unlocked"] = mission_index + 2

	save_data()


func is_mission_unlocked(mission_index: int) -> bool:
	return mission_index < data["missions_unlocked"]


func get_high_score(mission_index: int) -> Dictionary:
	var key := "mission_%d" % (mission_index + 1)
	return data["high_scores"].get(key, {})


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		file.close()
		if error == OK and json.data is Dictionary:
			data = json.data
```

- [ ] **Step 4: Register autoloads**

In Godot editor: Project Settings → Autoload, add:
- `GameManager` → `res://scripts/autoloads/GameManager.gd`
- `ScoreManager` → `res://scripts/autoloads/ScoreManager.gd`
- `SaveManager` → `res://scripts/autoloads/SaveManager.gd`

- [ ] **Step 5: Wire ScoreManager to Player/WeaponManager**

In `Player.gd`, add to `_on_weapon_fired()`:
```gdscript
ScoreManager.record_shot_fired()
```

In `Projectile.gd`, add to `_on_body_entered()`:
```gdscript
if body.has_method("take_damage"):
    ScoreManager.record_shot_hit()
```

In `EnemyBase.gd`, add to `_die()`:
```gdscript
ScoreManager.record_kill()
```

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: add GameManager, ScoreManager, and SaveManager autoload singletons"
```

---

### Task 9: HUD & Pause Menu

**Files:**
- Create: `scenes/ui/HUD.tscn`
- Create: `scripts/ui/HUD.gd`
- Create: `scenes/ui/PauseMenu.tscn`
- Create: `scripts/ui/PauseMenu.gd`

**Interfaces:**
- Consumes: `Player.health_changed`, `WeaponManager.ammo_changed`, `WeaponManager.weapon_switched`, `GameManager.game_paused`
- Produces: HUD overlay (health bar, ammo count, weapon name), PauseMenu overlay (resume, quit)

- [ ] **Step 1: Create HUD.tscn**

Scene structure (CanvasLayer):
```
HUD (CanvasLayer)
└── MarginContainer
    └── VBoxContainer
        ├── TopBar (HBoxContainer)
        │   ├── HealthBar (ProgressBar) # min=0, max=100
        │   └── AmmoLabel (Label)       # "30 / 30"
        └── BottomBar (HBoxContainer)
            └── WeaponLabel (Label)     # "Zastava M70"
```

- [ ] **Step 2: Write HUD.gd**

```gdscript
extends CanvasLayer

## In-game HUD — displays health, ammo, and current weapon.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/TopBar/AmmoLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/BottomBar/WeaponLabel

var _player: CharacterBody2D = null
var _weapon_manager: Node = null


func setup(player: CharacterBody2D) -> void:
	_player = player
	_weapon_manager = player.get_node("WeaponManager")

	_player.health_changed.connect(_on_health_changed)
	_weapon_manager.ammo_changed.connect(_on_ammo_changed)
	_weapon_manager.weapon_switched.connect(_on_weapon_switched)

	# Initial state
	health_bar.max_value = _player.max_health
	health_bar.value = _player.health


func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	if current < 0:
		ammo_label.text = "∞"
	else:
		ammo_label.text = "%d / %d" % [current, max_ammo]


func _on_weapon_switched(weapon_resource: WeaponResource) -> void:
	weapon_label.text = weapon_resource.weapon_name
```

- [ ] **Step 3: Create PauseMenu.tscn and PauseMenu.gd**

Scene structure:
```
PauseMenu (CanvasLayer)
└── CenterContainer
    └── VBoxContainer
        ├── Label           # "PAUSED"
        ├── ResumeButton (Button)
        └── QuitButton (Button)
```

Set `process_mode` to `PROCESS_MODE_ALWAYS` so it works while paused.

```gdscript
extends CanvasLayer

## Pause menu overlay.

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)
	visible = false
	GameManager.game_paused.connect(_on_game_paused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused


func _on_resume() -> void:
	GameManager.toggle_pause()


func _on_quit() -> void:
	GameManager.return_to_menu()
```

- [ ] **Step 4: Integrate HUD and PauseMenu into Main.tscn**

Add HUD and PauseMenu as children of Main.tscn. In the mission setup script, call `hud.setup(player)`.

- [ ] **Step 5: Test HUD and pause**

Run the project. Verify:
- Health bar updates when player takes damage
- Ammo count updates when firing and reloading
- Weapon name changes on weapon switch
- ESC opens/closes pause menu
- Game freezes while paused

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: add HUD and pause menu UI"
```

---

### Task 10: Main Menu, Briefing Screen & Results Screen

**Files:**
- Create: `scenes/ui/MainMenu.tscn`
- Create: `scripts/ui/MainMenu.gd`
- Create: `scenes/ui/BriefingScreen.tscn`
- Create: `scripts/ui/BriefingScreen.gd`
- Create: `scenes/ui/ResultsScreen.tscn`
- Create: `scripts/ui/ResultsScreen.gd`
- Modify: `scenes/Main.tscn` — wire up full game flow

**Interfaces:**
- Consumes: `GameManager` state transitions, `ScoreManager` results data, `SaveManager` unlock state
- Produces: Full menu → briefing → gameplay → results → menu flow

- [ ] **Step 1: Create MainMenu.tscn and MainMenu.gd**

```
MainMenu (Control)
└── CenterContainer
    └── VBoxContainer
        ├── TitleLabel (Label)       # "OPERATION STORM"
        ├── SubtitleLabel (Label)    # "Oluja 1995"
        ├── StartButton (Button)    # "Start Campaign"
        └── QuitButton (Button)     # "Quit"
```

```gdscript
extends Control

## Title screen / main menu.

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)


func _on_start() -> void:
	GameManager.start_mission(0)


func _on_quit() -> void:
	get_tree().quit()
```

- [ ] **Step 2: Create BriefingScreen.tscn and BriefingScreen.gd**

```
BriefingScreen (Control)
└── MarginContainer
    └── VBoxContainer
        ├── MissionTitle (Label)     # "Mission 1: First Thunder"
        ├── MissionDesc (RichTextLabel) # Mission description text
        └── StartButton (Button)     # "Begin Mission"
```

```gdscript
extends Control

## Journal-style mission briefing screen.

const BRIEFINGS: Array[Dictionary] = [
	{
		"title": "Mission 1: First Thunder",
		"description": "August 4, 1995 — Dawn.\n\nThe artillery barrage has begun. Operation Storm is underway.\n\nYour task: Hold the forward positions against enemy counterattacks while our forces prepare the main assault. Survive the waves. Hold the line.\n\nZa dom!",
	},
]

@onready var mission_title: Label = $MarginContainer/VBoxContainer/MissionTitle
@onready var mission_desc: RichTextLabel = $MarginContainer/VBoxContainer/MissionDesc
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)


func show_briefing(mission_index: int) -> void:
	if mission_index < BRIEFINGS.size():
		var briefing: Dictionary = BRIEFINGS[mission_index]
		mission_title.text = briefing["title"]
		mission_desc.text = briefing["description"]
	visible = true


func _on_start() -> void:
	visible = false
	GameManager.begin_gameplay()
```

- [ ] **Step 3: Create ResultsScreen.tscn and ResultsScreen.gd**

```
ResultsScreen (Control)
└── CenterContainer
    └── VBoxContainer
        ├── TitleLabel (Label)       # "MISSION COMPLETE"
        ├── ScoreLabel (Label)       # "Score: 12400"
        ├── KillsLabel (Label)       # "Kills: 24"
        ├── AccuracyLabel (Label)    # "Accuracy: 67%"
        ├── TimeLabel (Label)        # "Time: 3:45"
        ├── RankLabel (Label)        # "Rank: B"
        └── ContinueButton (Button)  # "Continue"
```

```gdscript
extends Control

## Post-mission results screen showing score, stats, and rank.

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var kills_label: Label = $CenterContainer/VBoxContainer/KillsLabel
@onready var accuracy_label: Label = $CenterContainer/VBoxContainer/AccuracyLabel
@onready var time_label: Label = $CenterContainer/VBoxContainer/TimeLabel
@onready var rank_label: Label = $CenterContainer/VBoxContainer/RankLabel
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue)


func show_results() -> void:
	score_label.text = "Score: %d" % ScoreManager.get_total_score()
	kills_label.text = "Kills: %d" % ScoreManager.kills
	accuracy_label.text = "Accuracy: %.0f%%" % ScoreManager.get_accuracy()

	var minutes := int(ScoreManager.elapsed_time) / 60
	var seconds := int(ScoreManager.elapsed_time) % 60
	time_label.text = "Time: %d:%02d" % [minutes, seconds]

	rank_label.text = "Rank: %s" % ScoreManager.get_rank()
	visible = true


func _on_continue() -> void:
	visible = false
	GameManager.return_to_menu()
```

- [ ] **Step 4: Wire game flow in Main.tscn**

Update `Main.tscn` to include all UI screens and a script that coordinates transitions:

```gdscript
extends Node

## Root scene — coordinates game flow between menu, briefing, gameplay, and results.

@onready var main_menu: Control = $MainMenu
@onready var briefing_screen: Control = $BriefingScreen
@onready var results_screen: Control = $ResultsScreen
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var world_container: Node2D = $WorldContainer

var _current_world: Node2D = null


func _ready() -> void:
	GameManager.mission_started.connect(_on_mission_started)
	GameManager.mission_completed.connect(_on_mission_completed)
	_show_main_menu()


func _show_main_menu() -> void:
	main_menu.visible = true
	briefing_screen.visible = false
	results_screen.visible = false
	hud.visible = false

	if _current_world:
		_current_world.queue_free()
		_current_world = null

	# Connect GameManager state change for briefing
	if not GameManager.is_connected("mission_started", _on_mission_started):
		GameManager.mission_started.connect(_on_mission_started)


func _on_game_state_changed() -> void:
	match GameManager.current_state:
		GameManager.GameState.BRIEFING:
			main_menu.visible = false
			briefing_screen.show_briefing(GameManager.current_mission)


func _on_mission_started(_mission_index: int) -> void:
	briefing_screen.visible = false
	hud.visible = true

	# Load mission scene
	var scene_path: String = GameManager.MISSION_SCENES[GameManager.current_mission]
	var mission_scene: PackedScene = load(scene_path)
	_current_world = mission_scene.instantiate()
	world_container.add_child(_current_world)

	# Setup HUD with player
	var player: CharacterBody2D = _current_world.get_node("Player")
	hud.setup(player)
	ScoreManager.start_tracking()


func _on_mission_completed(_mission_index: int) -> void:
	ScoreManager.stop_tracking()
	hud.visible = false
	results_screen.show_results()
```

- [ ] **Step 5: Test full game flow**

Run the project. Verify the flow:
1. Main menu appears → click "Start Campaign"
2. Briefing screen shows Mission 1 text → click "Begin Mission"
3. Gameplay loads with HUD
4. ESC pauses/unpauses
5. (Mission completion to be tested after Mission 1 is built)

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: add main menu, briefing screen, results screen, and full game flow"
```

---

### Task 11: Mission 1 — "First Thunder"

**Files:**
- Create: `scenes/missions/Mission1.tscn`

**Interfaces:**
- Consumes: Player scene, Rifleman/Shotgunner scenes, Pickup scenes, GameManager, ScoreManager
- Produces: Complete playable level with spawn waves, checkpoints, objective completion trigger

- [ ] **Step 1: Design the Mission 1 layout**

Create `Mission1.tscn` with this structure:
```
Mission1 (Node2D)
├── TileMap              # Ground terrain — open field with some cover
├── Player (instance)    # Player.tscn, starting position
├── Enemies (Node2D)     # Container for enemy instances
├── Pickups (Node2D)     # Pre-placed pickups
├── Projectiles (Node2D) # Bullet pool container
├── Checkpoints (Node2D)
│   ├── Checkpoint1 (Area2D + CollisionShape2D)
│   └── Checkpoint2 (Area2D + CollisionShape2D)
├── SpawnZones (Node2D)  # Areas that trigger enemy waves
│   ├── Wave1Trigger (Area2D)
│   ├── Wave2Trigger (Area2D)
│   └── Wave3Trigger (Area2D)
├── Objective (Area2D)   # Final area — mission complete when reached after all waves
└── MissionController (Node) # Script managing waves and objectives
```

Use a simple TileMap with:
- Open ground (grass/dirt tiles)
- Sandbag walls and crates for cover
- A few destroyed buildings as obstacles
- Boundary walls around the playable area

- [ ] **Step 2: Write MissionController.gd**

```gdscript
extends Node

## Controls Mission 1 wave spawning, checkpoints, and objective tracking.

@export var rifleman_scene: PackedScene
@export var shotgunner_scene: PackedScene

var _wave: int = 0
var _enemies_alive: int = 0
var _mission_complete: bool = false

const WAVES: Array[Dictionary] = [
	{"riflemen": 5, "shotgunners": 0},
	{"riflemen": 6, "shotgunners": 2},
	{"riflemen": 8, "shotgunners": 4},
]

@onready var enemies_container: Node2D = $"../Enemies"
@onready var spawn_markers: Node2D = $"../SpawnMarkers"


func _ready() -> void:
	_start_wave(0)


func _start_wave(wave_index: int) -> void:
	if wave_index >= WAVES.size():
		_complete_mission()
		return

	_wave = wave_index
	var wave_data: Dictionary = WAVES[wave_index]
	_enemies_alive = wave_data["riflemen"] + wave_data["shotgunners"]

	var spawn_points := spawn_markers.get_children()
	var spawn_index: int = 0

	for i in range(wave_data["riflemen"]):
		var enemy := rifleman_scene.instantiate()
		enemy.global_position = spawn_points[spawn_index % spawn_points.size()].global_position
		enemy.enemy_died.connect(_on_enemy_died)
		enemies_container.add_child(enemy)
		spawn_index += 1

	for i in range(wave_data["shotgunners"]):
		var enemy := shotgunner_scene.instantiate()
		enemy.global_position = spawn_points[spawn_index % spawn_points.size()].global_position
		enemy.enemy_died.connect(_on_enemy_died)
		enemies_container.add_child(enemy)
		spawn_index += 1


func _on_enemy_died(_enemy: CharacterBody2D) -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		# Brief pause then next wave
		get_tree().create_timer(2.0).timeout.connect(
			func() -> void: _start_wave(_wave + 1)
		)


func _complete_mission() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	GameManager.complete_mission()
```

- [ ] **Step 3: Place spawn markers and environment**

In the Godot editor:
- Add 6-8 `Marker2D` nodes as `SpawnMarkers` children at the edges of the map
- Place some pre-positioned pickups (2 HealthKits, 1 AmmoCrate, 1 WeaponPickup with Shotgun)
- Build a simple TileMap environment with cover positions

- [ ] **Step 4: Create additional weapon resources for pickups**

Create `resources/weapons/hawk_shotgun.tres` and `resources/weapons/skorpion_smg.tres`:

`resources/weapons/hawk_shotgun.tres`:
```
weapon_name = "Hawk 12ga"
damage = 12
fire_rate = 0.8
max_ammo = 8
reload_time = 2.5
spread_angle = 0.35
bullet_speed = 500.0
is_automatic = false
projectile_count = 5
is_pistol = false
```

`resources/weapons/skorpion_smg.tres`:
```
weapon_name = "Skorpion vz.61"
damage = 7
fire_rate = 0.08
max_ammo = 20
reload_time = 1.2
spread_angle = 0.12
bullet_speed = 550.0
is_automatic = true
projectile_count = 1
is_pistol = false
```

- [ ] **Step 5: Playtest Mission 1**

Run the full game flow. Verify:
1. Main menu → Briefing → Mission 1 loads
2. Wave 1 spawns (5 riflemen) — kill all to trigger Wave 2
3. Wave 2 spawns (6 riflemen + 2 shotgunners)
4. Wave 3 spawns (8 riflemen + 4 shotgunners)
5. After all waves cleared → Results screen shows score, kills, accuracy, rank
6. Player can pick up weapons and health during combat
7. Game feels playable and fun at a basic level

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: add Mission 1 'First Thunder' with wave spawning and objectives"
```

---

### Task 12: Checkpoint System & Player Death

**Files:**
- Modify: `scripts/player/Player.gd` — death handling, checkpoint restore
- Create: `scripts/missions/Checkpoint.gd`
- Modify: `scenes/missions/Mission1.tscn` — add checkpoint areas

**Interfaces:**
- Consumes: `Player.died` signal, checkpoint Area2D triggers
- Produces: Checkpoint save/restore cycle, death → respawn flow

- [ ] **Step 1: Create Checkpoint.gd**

```gdscript
extends Area2D

## Saves player state when entered. Used for respawn on death.

signal checkpoint_reached(checkpoint: Area2D)

var _activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if body.is_in_group("player"):
		_activated = true
		checkpoint_reached.emit(self)
```

- [ ] **Step 2: Add checkpoint handling to Player.gd**

Add to `Player.gd`:

```gdscript
var _checkpoint_data: Dictionary = {}

func save_checkpoint(checkpoint_pos: Vector2) -> void:
	_checkpoint_data = {
		"position": checkpoint_pos,
		"health": health,
		"weapon_slots": weapon_manager.slots.duplicate(),
		"weapon_ammo": weapon_manager.ammo.duplicate(),
		"current_slot": weapon_manager.current_slot,
	}


func restore_checkpoint() -> void:
	if _checkpoint_data.is_empty():
		return

	global_position = _checkpoint_data["position"]
	health = _checkpoint_data["health"]
	health_changed.emit(health)
	# Restore weapons
	weapon_manager.slots = _checkpoint_data["weapon_slots"].duplicate()
	weapon_manager.ammo = _checkpoint_data["weapon_ammo"].duplicate()
	weapon_manager.switch_to_slot(_checkpoint_data["current_slot"])
	is_dodging = false
	can_dodge = true
```

- [ ] **Step 3: Wire death → respawn in MissionController**

Add to `MissionController.gd`:

```gdscript
@onready var player: CharacterBody2D = $"../Player"

func _ready() -> void:
	# ... existing code ...
	player.died.connect(_on_player_died)
	# Save initial checkpoint at spawn
	player.save_checkpoint(player.global_position)

func _on_player_died() -> void:
	ScoreManager.record_death()
	# Brief delay then respawn
	get_tree().create_timer(1.0).timeout.connect(_respawn_player)

func _respawn_player() -> void:
	player.restore_checkpoint()
```

- [ ] **Step 4: Test death and respawn**

Verify:
- Player takes enough damage to die
- Brief pause → player respawns at last checkpoint with saved state
- ScoreManager records the death
- Walking through checkpoint areas saves state

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: add checkpoint system and player death/respawn"
```

---

### Task 13: Camera Effects & Screen Shake

**Files:**
- Modify: `scripts/player/Player.gd` — screen shake on hit, camera zoom

**Interfaces:**
- Consumes: `Player.take_damage()` events, combat intensity
- Produces: Screen shake effect, camera zoom behavior

- [ ] **Step 1: Add screen shake to Player.gd**

Add to `Player.gd`:

```gdscript
@export var shake_strength: float = 5.0
@export var shake_decay: float = 8.0

var _shake_amount: float = 0.0


func _process(delta: float) -> void:
	if _shake_amount > 0.0:
		camera.offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		_shake_amount = lerpf(_shake_amount, 0.0, shake_decay * delta)
		if _shake_amount < 0.1:
			_shake_amount = 0.0
			camera.offset = Vector2.ZERO


func shake_camera(intensity: float = -1.0) -> void:
	if intensity < 0.0:
		intensity = shake_strength
	_shake_amount = intensity
```

Update `take_damage()` to call `shake_camera()`:
```gdscript
func take_damage(amount: int) -> void:
	if is_dodging:
		return
	health = clampi(health - amount, 0, max_health)
	health_changed.emit(health)
	_flash_hit()
	shake_camera()
	if health <= 0:
		died.emit()
```

- [ ] **Step 2: Test screen shake**

Take damage from enemies. Verify:
- Camera shakes on hit
- Shake decays smoothly
- Multiple rapid hits compound the shake

- [ ] **Step 3: Commit**

```powershell
git add -A; git commit -m "feat: add screen shake on player damage"
```

---

## Verification Plan

### Manual Verification (Primary)

After completing all tasks, perform a full playthrough:

1. **Launch game** — Main menu appears
2. **Start campaign** — Briefing screen shows Mission 1 text
3. **Begin mission** — Player spawns with Zastava M70
4. **Test movement** — WASD in all 8 directions, normalized diagonals
5. **Test rotation** — Player always faces mouse cursor
6. **Test shooting** — Left-click fires, bullets travel and hit enemies
7. **Test dodge** — Space dodges, invincibility works, cooldown enforced
8. **Test weapons** — 1/2/3 switch slots, R reloads, ammo tracks correctly
9. **Test enemies** — Riflemen patrol, detect, chase, attack with bursts. Shotgunners rush.
10. **Test pickups** — Health restores HP, ammo refills, weapons swap into slots
11. **Kill all waves** — Wave 1 → 2 → 3 → mission complete
12. **Results screen** — Shows correct kills, accuracy, time, score, rank
13. **Pause menu** — ESC pauses, resume works, quit returns to menu
14. **Death & respawn** — Die, respawn at checkpoint with saved state
15. **Screen shake** — Camera shakes on damage, decays smoothly

### Performance Checks

- Verify bullet pool doesn't grow unbounded (watch node count in debugger)
- Verify enemy spawning doesn't exceed ~30-40 active enemies
- Check for physics lag during Wave 3 (12 enemies + player bullets)
