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
