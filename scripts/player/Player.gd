extends CharacterBody2D

## Player character — modular 3-layer rig, movement, weapons, dodge-roll, equipment.

signal health_changed(new_health: int)
signal armor_changed(new_armor: int)
signal grenades_changed(count: int)
signal mines_changed(count: int)
signal died

const DODGE_SPEED_MULTIPLIER: float = 3.0
const MAX_GRENADES: int = 5
const MAX_MINES: int = 3
const POOL_SIZE: int = 100
const Equipment = preload("res://scripts/player/PlayerEquipment.gd")

const CombatVfxScript = preload("res://scripts/effects/CombatVfx.gd")
const DecalManagerScript = preload("res://scripts/effects/DecalManager.gd")

@export var speed: float = 200.0
@export var max_health: int = 100
@export var shake_strength: float = 5.0
@export var shake_decay: float = 8.0
## Croatian HV faction identity for UI / future ally systems.
@export var faction: FactionResource = preload("res://resources/factions/hv_faction.tres")

var health: int = max_health
var armor: int = 0
var grenade_count: int = 0
var mine_count: int = 0
var is_dodging: bool = false
var can_dodge: bool = true
var _is_dead: bool = false
var _dodge_direction: Vector2 = Vector2.ZERO
var _checkpoint_data: Dictionary = {}
var _shake_amount: float = 0.0
var _walk_cycle_time: float = 0.0
var _respawn_protection: float = 0.0

var _projectile_pool: Array[Area2D] = []
var _projectile_scene: PackedScene = preload("res://scenes/weapons/Projectile.tscn")
var _rocket_scene: PackedScene = preload("res://scenes/weapons/RocketProjectile.tscn")
var _grenade_scene: PackedScene = preload("res://scenes/weapons/Grenade.tscn")
var _mine_scene: PackedScene = preload("res://scenes/weapons/PlacedMine.tscn")

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var legs_sprite: Sprite2D = $LegsSprite
@onready var torso_container: Node2D = $TorsoContainer
@onready var body_sprite: Sprite2D = $TorsoContainer/BodySprite
@onready var weapon_sprite: Sprite2D = $TorsoContainer/WeaponSprite
@onready var muzzle: Marker2D = $TorsoContainer/MuzzleMarker
@onready var brass_marker: Marker2D = $TorsoContainer/BrassMarker
@onready var sprite: Sprite2D = $TorsoContainer/BodySprite

@onready var dodge_timer: Timer = $DodgeTimer
@onready var dodge_duration_timer: Timer = $DodgeDurationTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var camera: Camera2D = $Camera2D
@onready var weapon_manager: WeaponManager = $WeaponManager

func _enter_tree() -> void:
	_ensure_rig()

func _ensure_rig() -> void:
	if shadow_sprite == null: shadow_sprite = get_node_or_null("ShadowSprite")
	if legs_sprite == null: legs_sprite = get_node_or_null("LegsSprite")
	if torso_container == null: torso_container = get_node_or_null("TorsoContainer")
	if body_sprite == null: body_sprite = get_node_or_null("TorsoContainer/BodySprite")
	if weapon_sprite == null: weapon_sprite = get_node_or_null("TorsoContainer/WeaponSprite")
	if muzzle == null: muzzle = get_node_or_null("TorsoContainer/MuzzleMarker")
	if brass_marker == null: brass_marker = get_node_or_null("TorsoContainer/BrassMarker")
	if sprite == null: sprite = body_sprite

func _ready() -> void:
	z_index = 1
	add_to_group("player")
	health = max_health
	if dodge_timer: dodge_timer.timeout.connect(func() -> void: can_dodge = true)
	if dodge_duration_timer: dodge_duration_timer.timeout.connect(_on_dodge_duration_finished)
	if hit_flash_timer: hit_flash_timer.timeout.connect(func() -> void: if body_sprite: body_sprite.modulate = Color.WHITE)
	if weapon_manager:
		weapon_manager.weapon_fired.connect(_on_weapon_fired)
		if not weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
			weapon_manager.weapon_switched.connect(_on_weapon_switched)
		call_deferred("_update_held_sprite", weapon_manager.get_current_weapon())
	_init_projectile_pool()
	# Deferred so HUD signal listeners are connected before kit emits.
	call_deferred("_apply_difficulty_kit")


## Applies starting HP / armor / grenades from DifficultyManager.
func _apply_difficulty_kit() -> void:
	if not is_inside_tree() or _is_dead:
		return
	var dm := get_node_or_null("/root/DifficultyManager")
	if dm == null:
		return
	max_health = maxi(1, dm.get_player_kit("player_hp"))
	health = max_health
	health_changed.emit(health)
	add_armor(dm.get_player_kit("player_armor"))
	add_grenades(dm.get_player_kit("player_grenades"))
	# The mission-entry checkpoint was saved BEFORE this kit applied — refresh it
	# so a respawn never strips the starting armor/grenades.
	if not _checkpoint_data.is_empty():
		save_checkpoint(_checkpoint_data.get("position", global_position))


func _process(delta: float) -> void:
	if _shake_amount > 0.0 and camera:
		camera.offset = Vector2(randf_range(-_shake_amount, _shake_amount), randf_range(-_shake_amount, _shake_amount))
		_shake_amount = lerpf(_shake_amount, 0.0, 1.0 - exp(-shake_decay * delta))
		if _shake_amount < 0.1: _shake_amount = 0.0; camera.offset = Vector2.ZERO


func _physics_process(delta: float) -> void:
	_respawn_protection = maxf(0.0, _respawn_protection - delta)
	if _is_dead:
		velocity = Vector2.ZERO
		return
	_ensure_rig()
	if torso_container and get_viewport(): torso_container.look_at(get_global_mouse_position())
	velocity = (_dodge_direction * speed * DODGE_SPEED_MULTIPLIER) if is_dodging else (Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed)
	if is_inside_tree(): move_and_slide()
	if legs_sprite:
		if velocity.length() > 5.0:
			legs_sprite.rotation = velocity.angle()
			_walk_cycle_time += delta * 12.0 * (velocity.length() / speed)
			legs_sprite.frame = int(_walk_cycle_time) % 4
		else: legs_sprite.frame = 0

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead: return
	if event.is_action_pressed("dodge") and can_dodge and not is_dodging: _start_dodge()
	elif event.is_action_pressed("throw_grenade"): _throw_grenade()
	elif event.is_action_pressed("place_mine"): _place_mine()

func take_damage(amount: int) -> void:
	_ensure_rig()
	if _is_dead or is_dodging or _respawn_protection > 0.0 or amount <= 0 or not can_process():
		return
	var remaining: int = amount
	if armor > 0:
		var absorbed: int = mini(armor, int(ceil(float(amount) * 0.5)))
		armor -= absorbed; remaining -= absorbed; armor_changed.emit(armor)

	health = clampi(health - remaining, 0, max_health)
	health_changed.emit(health)
	if body_sprite: body_sprite.modulate = Color.RED
	if hit_flash_timer: hit_flash_timer.start()
	_shake_amount = shake_strength
	var settings: Dictionary = {}
	var save_m = get_node_or_null("/root/SaveManager")
	if save_m:
		settings = save_m.data.get("settings", {})
	if not bool(settings.get("screen_shake", true)):
		_shake_amount = 0.0
	_play_sfx("hit")
	_set_audio_low_pass(health < int(max_health * 0.25))
	if health <= 0:
		_is_dead = true
		velocity = Vector2.ZERO
		weapon_manager.process_mode = Node.PROCESS_MODE_DISABLED
		_play_sfx("death")
		DecalManagerScript.stamp_blood(global_position)
		DecalManagerScript.stamp_casualty(global_position, torso_container.rotation if torso_container else 0.0)
		died.emit()

func heal(amount: int) -> void:
	if _is_dead: return
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health)
	_set_audio_low_pass(health < int(max_health * 0.25))
func add_armor(amount: int) -> void: armor = clampi(armor + amount, 0, 100); armor_changed.emit(armor)
func add_grenades(amount: int) -> void: grenade_count = clampi(grenade_count + amount, 0, MAX_GRENADES); grenades_changed.emit(grenade_count)
func add_mines(amount: int) -> void: mine_count = clampi(mine_count + amount, 0, MAX_MINES); mines_changed.emit(mine_count)
func shake_camera(intensity: float = -1.0) -> void:
	var settings: Dictionary = {}
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		settings = sm.data.get("settings", {})
	if not bool(settings.get("screen_shake", true)):
		return
	_shake_amount = intensity if intensity >= 0.0 else shake_strength

func _start_dodge() -> void:
	_ensure_rig()
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dodge_direction = input_dir.normalized() if input_dir != Vector2.ZERO else Vector2.RIGHT.rotated(torso_container.rotation if torso_container else 0.0)
	is_dodging = true; can_dodge = false
	if dodge_duration_timer: dodge_duration_timer.start()
	if shadow_sprite: shadow_sprite.modulate.a = 0.25; shadow_sprite.scale = Vector2(0.6, 0.6)
	if body_sprite: body_sprite.modulate.a = 0.6
	if is_inside_tree() and torso_container:
		var tween := create_tween()
		if tween:
			tween.tween_property(torso_container, "scale", Vector2(0.7, 0.7), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(torso_container, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_play_sfx("dodge"); _set_audio_low_pass(true)

func _on_dodge_duration_finished() -> void:
	_ensure_rig()
	is_dodging = false
	if body_sprite: body_sprite.modulate.a = 1.0
	if torso_container: torso_container.scale = Vector2.ONE
	if shadow_sprite: shadow_sprite.modulate.a = 1.0; shadow_sprite.scale = Vector2.ONE
	if dodge_timer: dodge_timer.start()
	_set_audio_low_pass(health < int(max_health * 0.25))

func _init_projectile_pool() -> void:
	var pool_container: Node = null
	if get_tree() and get_tree().root:
		pool_container = get_tree().root.get_node_or_null("Main/Projectiles")
	if pool_container == null:
		pool_container = self
	for i in range(POOL_SIZE):
		var bullet: Area2D = _projectile_scene.instantiate()
		pool_container.add_child(bullet)
		bullet.deactivate()
		_projectile_pool.append(bullet)

func _apply_recoil() -> void:
	_ensure_rig()
	if torso_container == null: return
	torso_container.position = Vector2.LEFT.rotated(torso_container.rotation) * 4.0
	if is_inside_tree():
		var tween := create_tween()
		if tween: tween.tween_property(torso_container, "position", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_weapon_switched(weapon: WeaponResource) -> void:
	_update_held_sprite(weapon)


## Swaps the visible held weapon to match the current WeaponResource.
func _update_held_sprite(weapon: WeaponResource) -> void:
	_ensure_rig()
	if weapon_sprite == null:
		return
	if weapon and weapon.held_sprite:
		weapon_sprite.texture = weapon.held_sprite
		weapon_sprite.visible = true
	else:
		weapon_sprite.texture = null
		weapon_sprite.visible = false


## How many pooled player projectiles can fire right now (used by WeaponManager
## to avoid burning ammo when the pool is exhausted).
func count_free_projectiles() -> int:
	var free_count: int = 0
	for b in _projectile_pool:
		if is_instance_valid(b) and not b._active:
			free_count += 1
	return free_count


func _on_weapon_fired() -> void:
	_apply_recoil()
	if weapon_manager == null: return
	var weapon: WeaponResource = weapon_manager.get_current_weapon()
	if weapon == null: return
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var fire_rot: float = torso_container.global_rotation if torso_container else rotation
	var wtype: String = String(weapon.weapon_id) if weapon.weapon_id != &"" else "rifle"
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_weapon_shoot"):
		snd.play_weapon_shoot(wtype)
	else:
		_play_sfx("shoot")
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, fire_rot, wtype, false)
	# Eject brass from the brass marker (not the muzzle) with a sideways toss.
	if brass_marker and not weapon.is_explosive:
		var eject_dir: Vector2 = Vector2.DOWN.rotated(fire_rot) * randf_range(18.0, 30.0)
		DecalManagerScript.spawn_casing(brass_marker.global_position, eject_dir, wtype == "hawk")
	var sm = get_node_or_null("/root/ScoreManager")
	if weapon.is_explosive:
		if sm and sm.has_method("record_shot_fired"):
			sm.record_shot_fired()
		_fire_rocket(weapon); _play_sfx("shoot_rpg"); return
	# Count one trigger pull for accuracy, not one shot per pellet.
	if sm and sm.has_method("record_shot_fired"):
		sm.record_shot_fired()
	# Only spawn as many pellets as the pool granted during fire() pre-check.
	var needed: int = maxi(1, weapon_manager.last_pellet_count)
	var acquired: Array[Area2D] = []
	for b in _projectile_pool:
		if acquired.size() >= needed:
			break
		if is_instance_valid(b) and not b._active:
			acquired.append(b)
	if acquired.is_empty():
		return
	# Effective spread = base spread + sustained-fire bloom.
	var total_spread: float = weapon.spread_angle + weapon_manager.current_bloom
	for i in range(acquired.size()):
		var bullet: Area2D = acquired[i]
		bullet.activate(spawn_pos, fire_rot + randf_range(-total_spread, total_spread), weapon.bullet_speed, weapon.damage)

func _fire_rocket(weapon: WeaponResource) -> void:
	var container: Node = null
	if get_tree() and get_tree().root:
		container = get_tree().root.get_node_or_null("Main/Projectiles")
	if container == null:
		container = get_parent()
	if container:
		var rocket: Area2D = _rocket_scene.instantiate()
		container.add_child(rocket)
		var dmg := weapon.explosion_damage if weapon.explosion_damage > 0 else weapon.damage
		var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
		var fire_rot: float = torso_container.global_rotation if torso_container else rotation
		rocket.launch(spawn_pos, fire_rot, weapon.bullet_speed, weapon.damage, weapon.explosion_radius, dmg, true)

func _throw_grenade() -> void:
	Equipment.throw_grenade(self, _grenade_scene)

func _place_mine() -> void:
	Equipment.place_mine(self, _mine_scene)

func save_checkpoint(checkpoint_pos: Vector2) -> void:
	if _is_dead or health <= 0: return
	_checkpoint_data = {
		"position": checkpoint_pos, "health": health, "armor": armor, "grenades": grenade_count, "mines": mine_count,
		"weapon_slots": weapon_manager.slots.duplicate() if weapon_manager else [],
		"weapon_ammo": weapon_manager.ammo.duplicate() if weapon_manager else [],
		"weapon_reserve": weapon_manager.reserve.duplicate() if weapon_manager else [],
		"current_slot": weapon_manager.current_slot if weapon_manager else 0,
	}

func restore_checkpoint() -> void:
	if _checkpoint_data.is_empty(): return
	global_position = _checkpoint_data["position"]; health = _checkpoint_data["health"]; armor = _checkpoint_data.get("armor", 0)
	grenade_count = _checkpoint_data.get("grenades", 0); mine_count = _checkpoint_data.get("mines", 0)
	health_changed.emit(health); armor_changed.emit(armor); grenades_changed.emit(grenade_count); mines_changed.emit(mine_count)
	if weapon_manager:
		weapon_manager.process_mode = Node.PROCESS_MODE_INHERIT
		weapon_manager.reset_action_state()
		weapon_manager.slots = _checkpoint_data["weapon_slots"].duplicate()
		weapon_manager.ammo = _checkpoint_data["weapon_ammo"].duplicate()
		weapon_manager.reserve = _checkpoint_data.get("weapon_reserve", weapon_manager.reserve).duplicate()
		weapon_manager.switch_to_slot(_checkpoint_data["current_slot"])
	is_dodging = false
	can_dodge = true
	_is_dead = false
	_respawn_protection = 2.0
	_shake_amount = 0.0
	_ensure_rig()
	if camera:
		camera.offset = Vector2.ZERO
		camera.reset_smoothing()
	if dodge_timer:
		dodge_timer.stop()
	if dodge_duration_timer:
		dodge_duration_timer.stop()
	if hit_flash_timer:
		hit_flash_timer.stop()
	if body_sprite:
		body_sprite.modulate = Color.WHITE
	if torso_container:
		torso_container.scale = Vector2.ONE
	if shadow_sprite:
		shadow_sprite.modulate = Color.WHITE
		shadow_sprite.scale = Vector2.ONE
	_set_audio_low_pass(health < int(max_health * 0.25))

func _play_sfx(sfx_id: String) -> void:
	if not is_inside_tree() or get_tree() == null: return
	var snd = get_tree().root.get_node_or_null("SoundManager")
	if snd and snd.has_method("play_sfx"): snd.play_sfx(sfx_id)

func _set_audio_low_pass(active: bool) -> void:
	if not is_inside_tree() or get_tree() == null: return
	var snd = get_tree().root.get_node_or_null("SoundManager")
	if snd and snd.has_method("set_low_pass"): snd.set_low_pass(active)
