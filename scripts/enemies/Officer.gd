class_name Officer
extends EnemyBase

## SVK officer — buffs nearby SVK infantry with speed and fire-rate aura.

@export var bullet_scene: PackedScene
@export var aura_radius: float = 150.0
@export var speed_bonus: float = 1.25
@export var fire_rate_bonus: float = 1.2
@export var hold_back_distance: float = 160.0

var _aura: Area2D
var _buffed: Dictionary = {}


func _ready() -> void:
	unit_key = "officer"
	super._ready()
	max_health = 60
	health = max_health
	speed = 90.0
	attack_range = 180.0
	detection_range = 250.0
	damage = 12
	attack_cooldown = 0.5
	_setup_aura()


func _setup_aura() -> void:
	_aura = Area2D.new()
	_aura.collision_layer = 0
	_aura.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = aura_radius
	shape.shape = circle
	_aura.add_child(shape)
	add_child(_aura)
	_aura.body_entered.connect(_on_aura_enter)
	_aura.body_exited.connect(_on_aura_exit)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if target and is_instance_valid(target) and (current_state == State.CHASE or current_state == State.ATTACK):
		var dist := global_position.distance_to(target.global_position)
		if dist < hold_back_distance:
			var away := (global_position - target.global_position).normalized()
			velocity = away * speed * speed_buff
			move_and_slide()
			_update_legs(delta)


func _on_aura_enter(body: Node2D) -> void:
	if body == self:
		return
	if body is EnemyBase and body != self:
		var enemy := body as EnemyBase
		enemy.speed_buff = maxf(enemy.speed_buff, speed_bonus)
		enemy.fire_rate_buff = maxf(enemy.fire_rate_buff, fire_rate_bonus)
		_buffed[body] = true


func _on_aura_exit(body: Node2D) -> void:
	if body is EnemyBase and _buffed.has(body):
		_buffed.erase(body)
		_refresh_buffs_on(body as EnemyBase)


func _refresh_buffs_on(enemy: EnemyBase) -> void:
	## Recompute buffs from any remaining living SVK officers.
	enemy.speed_buff = 1.0
	enemy.fire_rate_buff = 1.0
	if not is_inside_tree() or get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == enemy or not is_instance_valid(node):
			continue
		if node is Officer and node.has_method("_applies_aura_to"):
			if node._applies_aura_to(enemy):
				enemy.speed_buff = maxf(enemy.speed_buff, node.speed_bonus)
				enemy.fire_rate_buff = maxf(enemy.fire_rate_buff, node.fire_rate_bonus)


func _applies_aura_to(enemy: EnemyBase) -> bool:
	return _buffed.has(enemy) and current_state != State.DEAD


func _die() -> void:
	var affected: Array = _buffed.keys()
	_buffed.clear()
	for body in affected:
		if is_instance_valid(body) and body is EnemyBase:
			_refresh_buffs_on(body as EnemyBase)
	super._die()


func _perform_attack() -> void:
	if target == null:
		return
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	var fire_rot := dir.angle()
	var pool := ProjectilePool.get_pool(get_tree())
	if pool:
		pool.spawn_enemy_bullet(spawn_pos, fire_rot, 480.0, damage)
	elif bullet_scene:
		var bullet: Area2D = bullet_scene.instantiate()
		var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
		if container:
			container.add_child(bullet)
		else:
			get_tree().root.add_child(bullet)
		bullet.activate(spawn_pos, fire_rot, 480.0, damage)
	apply_recoil(3.0)
	var flash_rot: float = torso_container.rotation if torso_container else fire_rot
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "pistol")
