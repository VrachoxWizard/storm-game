extends EnemyBase

## SVK machine gunner — high rate of fire area suppression with recoil and flashes.

@export var bullet_scene: PackedScene
@export var shots_per_burst: int = 8
@export var shot_interval: float = 0.08

var _shots_fired: int = 0
var _burst_generation: int = 0
var _planted: bool = false


func _ready() -> void:
	unit_key = "machine_gunner"
	super._ready()
	max_health = 70
	health = max_health
	speed = 70.0
	attack_range = 220.0
	detection_range = 280.0
	damage = 8
	attack_cooldown = 2.0


func _process_attack(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		_planted = false
		return
	_update_rig_aim(target.global_position)
	velocity = Vector2.ZERO
	_update_legs(delta)
	if not has_clear_shot() or global_position.distance_to(target.global_position) > attack_range * 1.2:
		_planted = false
		_enter_chase()


func _perform_attack() -> void:
	_shots_fired = 0
	_burst_generation += 1
	_planted = true
	_fire_next(_burst_generation)


func _fire_next(generation: int) -> void:
	if generation != _burst_generation:
		return
	if target == null or not is_instance_valid(target):
		return
	if current_state != State.ATTACK or current_state == State.DEAD or not has_clear_shot():
		return
	_spawn_enemy_bullet()
	_shots_fired += 1
	if _shots_fired < shots_per_burst:
		get_tree().create_timer(shot_interval).timeout.connect(func() -> void:
			if is_instance_valid(self):
				_fire_next(generation))


func _die() -> void:
	_burst_generation += 1
	super._die()


func _spawn_enemy_bullet() -> void:
	if target == null:
		return
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	var spread: float = 0.12 if _planted else 0.25
	var fire_rot: float = dir.angle() + randf_range(-spread, spread)
	var pool := ProjectilePool.get_pool(get_tree())
	if pool:
		pool.spawn_enemy_bullet(spawn_pos, fire_rot, 420.0, damage)
	elif bullet_scene:
		var bullet: Area2D = bullet_scene.instantiate()
		var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
		if container:
			container.add_child(bullet)
		else:
			get_tree().root.add_child(bullet)
		bullet.activate(spawn_pos, fire_rot, 420.0, damage)
	apply_recoil(3.5)
	var flash_rot := torso_container.rotation if torso_container else fire_rot
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "heavy")
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx("shoot_enemy", 0.12, -8.0)
