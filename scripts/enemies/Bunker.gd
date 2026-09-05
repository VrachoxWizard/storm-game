extends EnemyBase

## Fortified MG nest — stationary, arc suppression, armored front / weak rear.

signal destroyed

@export var bullet_scene: PackedScene
@export var fire_arc_degrees: float = 60.0
@export var front_armor_mult: float = 0.25
@export var rear_damage_mult: float = 2.0

var _facing: Vector2 = Vector2.RIGHT


func _ready() -> void:
	super._ready()
	max_health = 200
	health = max_health
	speed = 0.0
	attack_range = 320.0
	detection_range = 360.0
	damage = 10
	attack_cooldown = 0.12
	_facing = Vector2.RIGHT.rotated(rotation)
	add_to_group("emplacement")
	add_to_group("bunker")


func _physics_process(delta: float) -> void:
	# Stationary — never chase/patrol move
	match current_state:
		State.PATROL, State.ALERT:
			if target and is_instance_valid(target):
				_enter_attack()
		State.CHASE:
			current_state = State.ATTACK
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			pass


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	var final_amount: int = amount
	if target == null and get_tree():
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0]
	if target and is_instance_valid(target):
		var to_attacker := (target.global_position - global_position).normalized()
		var facing_dot := _facing.dot(to_attacker)
		if facing_dot > 0.2:
			final_amount = int(float(amount) * front_armor_mult)
		elif facing_dot < -0.2:
			final_amount = int(float(amount) * rear_damage_mult)
	super.take_damage(maxi(final_amount, 1))


func _die() -> void:
	current_state = State.DEAD
	destroyed.emit()
	enemy_died.emit(self)
	var sm = get_node_or_null("/root/ScoreManager")
	if sm:
		sm.record_emplacement_destroyed()
	queue_free()


func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return
	var to_target := (target.global_position - global_position).normalized()
	var angle_diff := absf(angle_difference(_facing.angle(), to_target.angle()))
	if rad_to_deg(angle_diff) > fire_arc_degrees * 0.5:
		_facing = _facing.lerp(to_target, 0.15).normalized()
		look_at(global_position + _facing)
		return
	_facing = to_target
	look_at(target.global_position)
	var spread := randf_range(-0.08, 0.08)
	var fire_rot := to_target.angle() + spread
	var pool := ProjectilePool.get_pool(get_tree())
	if pool:
		pool.spawn_enemy_bullet(global_position, fire_rot, 500.0, damage)
	elif bullet_scene:
		var bullet: Area2D = bullet_scene.instantiate()
		var container := get_tree().root.get_node_or_null("Main/Projectiles")
		if container:
			container.add_child(bullet)
			bullet.activate(global_position, fire_rot, 500.0, damage)
