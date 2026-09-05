extends CharacterBody2D

## Player character — movement, rotation, health, dodge-roll, grenades, mines.

signal health_changed(new_health: int)
signal armor_changed(new_armor: int)
signal grenades_changed(count: int)
signal mines_changed(count: int)
signal died

const DODGE_SPEED_MULTIPLIER: float = 3.0
const MAX_GRENADES: int = 5
const MAX_MINES: int = 3

@export var speed: float = 200.0
@export var max_health: int = 100
@export var shake_strength: float = 5.0
@export var shake_decay: float = 8.0

var health: int = max_health
var armor: int = 0
var grenade_count: int = 0
var mine_count: int = 0
var is_dodging: bool = false
var can_dodge: bool = true
var _dodge_direction: Vector2 = Vector2.ZERO
var _checkpoint_data: Dictionary = {}
var _shake_amount: float = 0.0

var _projectile_pool: Array[Area2D] = []
var _projectile_scene: PackedScene = preload("res://scenes/weapons/Projectile.tscn")
var _rocket_scene: PackedScene = preload("res://scenes/weapons/RocketProjectile.tscn")
var _grenade_scene: PackedScene = preload("res://scenes/weapons/Grenade.tscn")
var _mine_scene: PackedScene = preload("res://scenes/weapons/PlacedMine.tscn")
const POOL_SIZE: int = 100

@onready var sprite: Sprite2D = $Sprite2D
@onready var dodge_timer: Timer = $DodgeTimer
@onready var dodge_duration_timer: Timer = $DodgeDurationTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var camera: Camera2D = $Camera2D
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var muzzle: Marker2D = $MuzzleMarker
var _base_zoom: Vector2 = Vector2.ONE
var _combat_zoom: Vector2 = Vector2(0.85, 0.85)


func _ready() -> void:
	add_to_group("player")
	health = max_health
	dodge_timer.timeout.connect(_on_dodge_cooldown_finished)
	dodge_duration_timer.timeout.connect(_on_dodge_duration_finished)
	hit_flash_timer.timeout.connect(_on_hit_flash_finished)
	weapon_manager.weapon_fired.connect(_on_weapon_fired)
	_init_projectile_pool()


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
	_update_camera_zoom(delta)


func _update_camera_zoom(delta: float) -> void:
	var enemy_count: int = 0
	for n in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(n) and global_position.distance_to(n.global_position) < 400.0:
			enemy_count += 1
	var target_zoom: Vector2 = _combat_zoom if enemy_count >= 4 else _base_zoom
	camera.zoom = camera.zoom.lerp(target_zoom, 3.0 * delta)


func _physics_process(_delta: float) -> void:
	_handle_rotation()
	_handle_movement()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge") and can_dodge and not is_dodging:
		_start_dodge()
	elif event.is_action_pressed("throw_grenade"):
		_throw_grenade()
	elif event.is_action_pressed("place_mine"):
		_place_mine()


func take_damage(amount: int) -> void:
	if is_dodging:
		return

	var remaining: int = amount
	if armor > 0:
		var absorbed: int = mini(armor, int(ceil(float(amount) * 0.5)))
		armor -= absorbed
		remaining = amount - absorbed
		armor_changed.emit(armor)

	health = clampi(health - remaining, 0, max_health)
	health_changed.emit(health)
	_flash_hit()
	shake_camera()
	SoundManager.play_sfx("hit")
	SoundManager.set_low_pass(health < int(max_health * 0.25))

	if health <= 0:
		SoundManager.play_sfx("death")
		died.emit()


func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health)


func add_armor(amount: int) -> void:
	armor = clampi(armor + amount, 0, 100)
	armor_changed.emit(armor)


func add_grenades(amount: int) -> void:
	grenade_count = clampi(grenade_count + amount, 0, MAX_GRENADES)
	grenades_changed.emit(grenade_count)


func add_mines(amount: int) -> void:
	mine_count = clampi(mine_count + amount, 0, MAX_MINES)
	mines_changed.emit(mine_count)


func shake_camera(intensity: float = -1.0) -> void:
	if intensity < 0.0:
		intensity = shake_strength
	_shake_amount = intensity


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
	sprite.modulate.a = 0.5
	SoundManager.play_sfx("dodge")
	SoundManager.set_low_pass(true)


func _on_dodge_duration_finished() -> void:
	is_dodging = false
	sprite.modulate.a = 1.0
	dodge_timer.start()
	SoundManager.set_low_pass(health < int(max_health * 0.25))


func _on_dodge_cooldown_finished() -> void:
	can_dodge = true


func _flash_hit() -> void:
	sprite.modulate = Color.RED
	hit_flash_timer.start()


func _on_hit_flash_finished() -> void:
	sprite.modulate = Color.WHITE


func _init_projectile_pool() -> void:
	var pool_container: Node2D = get_tree().root.get_node("Main/Projectiles")
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
	ScoreManager.record_shot_fired()
	SoundManager.play_sfx("shoot")
	var weapon: WeaponResource = weapon_manager.get_current_weapon()
	if weapon == null:
		return

	var vfx := get_tree().root.get_node_or_null("Main/CombatVfx")
	if vfx and vfx.has_method("spawn_muzzle_flash"):
		vfx.spawn_muzzle_flash(muzzle.global_position, muzzle.global_rotation)

	if weapon.is_explosive:
		_fire_rocket(weapon)
		SoundManager.play_sfx("explosion")
		return

	for i in range(weapon.projectile_count):
		var bullet: Area2D = _get_pooled_bullet()
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


func _fire_rocket(weapon: WeaponResource) -> void:
	var rocket: Area2D = _rocket_scene.instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(rocket)
	rocket.launch(
		muzzle.global_position,
		muzzle.global_rotation,
		weapon.bullet_speed,
		weapon.damage,
		weapon.explosion_radius,
		weapon.explosion_damage if weapon.explosion_damage > 0 else weapon.damage,
		true
	)


func _throw_grenade() -> void:
	if grenade_count <= 0:
		return
	grenade_count -= 1
	grenades_changed.emit(grenade_count)
	var grenade: Area2D = _grenade_scene.instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(grenade)
	var dir := (get_global_mouse_position() - global_position).normalized()
	grenade.throw_at(global_position + dir * 20.0, dir, true)


func _place_mine() -> void:
	if mine_count <= 0:
		return
	mine_count -= 1
	mines_changed.emit(mine_count)
	var mine: Area2D = _mine_scene.instantiate()
	var world := get_parent()
	if world:
		world.add_child(mine)
	else:
		get_tree().root.get_node("Main/Projectiles").add_child(mine)
	mine.global_position = global_position


func save_checkpoint(checkpoint_pos: Vector2) -> void:
	_checkpoint_data = {
		"position": checkpoint_pos, "health": health, "armor": armor,
		"grenades": grenade_count, "mines": mine_count,
		"weapon_slots": weapon_manager.slots.duplicate(),
		"weapon_ammo": weapon_manager.ammo.duplicate(),
		"current_slot": weapon_manager.current_slot,
	}


func restore_checkpoint() -> void:
	if _checkpoint_data.is_empty():
		return
	global_position = _checkpoint_data["position"]
	health = _checkpoint_data["health"]
	armor = _checkpoint_data.get("armor", 0)
	grenade_count = _checkpoint_data.get("grenades", 0)
	mine_count = _checkpoint_data.get("mines", 0)
	health_changed.emit(health)
	armor_changed.emit(armor)
	grenades_changed.emit(grenade_count)
	mines_changed.emit(mine_count)
	weapon_manager.slots = _checkpoint_data["weapon_slots"].duplicate()
	weapon_manager.ammo = _checkpoint_data["weapon_ammo"].duplicate()
	weapon_manager.switch_to_slot(_checkpoint_data["current_slot"])
	is_dodging = false
	can_dodge = true
