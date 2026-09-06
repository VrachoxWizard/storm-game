extends EnemyBase

## Shotgunner enemy — rushes player, fires spread shot with recoil and muzzle flash.

@export var bullet_scene: PackedScene

const SHOTGUN_PELLETS: int = 5
const SHOTGUN_SPREAD: float = 0.4


func _ready() -> void:
	unit_key = "shotgunner"
	super._ready()
	speed = 150.0
	max_health = 35
	health = max_health
	attack_range = 80.0
	attack_cooldown = 1.5
	damage = 8


func _process_attack(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return
	_update_rig_aim(target.global_position)
	# Keep closing during attack
	var dir := (target.global_position - global_position).normalized()
	velocity = dir * speed * speed_buff * 0.7
	move_and_slide()
	_update_legs(delta)
	if not has_clear_shot() or global_position.distance_to(target.global_position) > attack_range * 1.8:
		_enter_chase()


func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	var base_angle := dir.angle()
	var pool := ProjectilePool.get_pool(get_tree())

	for i in range(SHOTGUN_PELLETS):
		var spread := randf_range(-SHOTGUN_SPREAD, SHOTGUN_SPREAD)
		var fire_rot := base_angle + spread
		if pool:
			pool.spawn_enemy_bullet(spawn_pos, fire_rot, 350.0, damage)
		elif bullet_scene:
			var bullet: Area2D = bullet_scene.instantiate()
			var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
			if container:
				container.add_child(bullet)
			else:
				get_tree().root.add_child(bullet)
			bullet.activate(spawn_pos, fire_rot, 350.0, damage)

	apply_recoil(6.0)
	var flash_rot := torso_container.rotation if torso_container else base_angle
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "shotgun")
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx("shoot_enemy", 0.1, -4.0)
