extends EnemyBase

## Slow machine gunner — high rate of fire area suppression.

@export var bullet_scene: PackedScene
@export var shots_per_burst: int = 8
@export var shot_interval: float = 0.08

var _shots_fired: int = 0


func _ready() -> void:
	super._ready()
	max_health = 70
	health = max_health
	speed = 70.0
	attack_range = 220.0
	detection_range = 280.0
	damage = 8
	attack_cooldown = 2.0


func _perform_attack() -> void:
	_shots_fired = 0
	_fire_next()


func _fire_next() -> void:
	if target == null or not is_instance_valid(target):
		return
	if current_state != State.ATTACK:
		return
	_spawn_enemy_bullet()
	_shots_fired += 1
	if _shots_fired < shots_per_burst:
		get_tree().create_timer(shot_interval).timeout.connect(_fire_next)


func _spawn_enemy_bullet() -> void:
	if bullet_scene == null:
		return
	var bullet: Area2D = bullet_scene.instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(bullet)
	var dir := (target.global_position - global_position).normalized()
	var spread := randf_range(-0.25, 0.25)
	bullet.activate(global_position, dir.angle() + spread, 420.0, damage)
