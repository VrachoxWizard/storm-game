extends EnemyBase

## Slow machine gunner — high rate of fire area suppression with recoil and flashes.

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
	var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
	if container:
		container.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)

	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	var fire_rot: float = dir.angle() + randf_range(-0.25, 0.25)
	bullet.activate(spawn_pos, fire_rot, 420.0, damage)
	apply_recoil(3.5)
	var flash_rot := torso_container.rotation if torso_container else fire_rot
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "heavy")
