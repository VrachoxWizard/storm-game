extends EnemyBase

## Rifleman enemy — fires burst shots at the player with weapon recoil and muzzle flash.

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
	var fire_rot: float = dir.angle() + randf_range(-0.1, 0.1)
	bullet.activate(spawn_pos, fire_rot, 400.0, damage)
	apply_recoil(4.0)
	var flash_rot := torso_container.rotation if torso_container else fire_rot
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "rifle")
