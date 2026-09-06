extends EnemyBase

## SVK rifleman — fires burst shots at the player with weapon recoil and muzzle flash.

var _burst_count: int = 0
var _burst_generation: int = 0
var _strafe_sign: float = 1.0
const BURST_SIZE: int = 3
const BURST_INTERVAL: float = 0.15

@export var bullet_scene: PackedScene


func _ready() -> void:
	unit_key = "rifleman"
	super._ready()


func _perform_attack() -> void:
	_burst_count = 0
	_burst_generation += 1
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0
	_fire_burst(_burst_generation)


func _process_attack(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return
	_update_rig_aim(target.global_position)
	var to_target := (target.global_position - global_position).normalized()
	var strafe := Vector2(-to_target.y, to_target.x) * _strafe_sign
	velocity = strafe * speed * speed_buff * 0.45
	move_and_slide()
	_update_legs(delta)
	if not has_clear_shot() or global_position.distance_to(target.global_position) > attack_range * 1.2:
		_enter_chase()


func _fire_burst(generation: int) -> void:
	if generation != _burst_generation:
		return
	if target == null or not is_instance_valid(target):
		return
	if current_state != State.ATTACK or current_state == State.DEAD or not has_clear_shot():
		return
	_spawn_enemy_bullet()
	_burst_count += 1
	if _burst_count < BURST_SIZE:
		get_tree().create_timer(BURST_INTERVAL).timeout.connect(_fire_burst.bind(generation))


func _die() -> void:
	_burst_generation += 1
	super._die()


func _spawn_enemy_bullet() -> void:
	if target == null:
		return
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	var fire_rot: float = dir.angle() + randf_range(-0.1, 0.1)
	var pool := ProjectilePool.get_pool(get_tree())
	if pool:
		pool.spawn_enemy_bullet(spawn_pos, fire_rot, 400.0, damage)
	elif bullet_scene:
		var bullet: Area2D = bullet_scene.instantiate()
		var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
		if container:
			container.add_child(bullet)
		else:
			get_tree().root.add_child(bullet)
		bullet.activate(spawn_pos, fire_rot, 400.0, damage)
	apply_recoil(4.0)
	var flash_rot := torso_container.rotation if torso_container else fire_rot
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "rifle")
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx("shoot_enemy", 0.1, -6.0)
