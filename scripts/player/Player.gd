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

var _projectile_pool: Array[Area2D] = []
var _projectile_scene: PackedScene = preload("res://scenes/weapons/Projectile.tscn")
const POOL_SIZE: int = 100

@onready var sprite: Sprite2D = $Sprite2D
@onready var dodge_timer: Timer = $DodgeTimer
@onready var dodge_duration_timer: Timer = $DodgeDurationTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var camera: Camera2D = $Camera2D
@onready var weapon_manager: Node = $WeaponManager
@onready var muzzle: Marker2D = $MuzzleMarker


func _ready() -> void:
	add_to_group("player")
	health = max_health
	dodge_timer.timeout.connect(_on_dodge_cooldown_finished)
	dodge_duration_timer.timeout.connect(_on_dodge_duration_finished)
	hit_flash_timer.timeout.connect(_on_hit_flash_finished)
	weapon_manager.weapon_fired.connect(_on_weapon_fired)
	_init_projectile_pool()


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
	ScoreManager.record_shot_fired()
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
