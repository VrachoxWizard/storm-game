extends EnemyBase

## Officer — buffs nearby enemies with speed and fire-rate aura.

@export var bullet_scene: PackedScene
@export var aura_radius: float = 150.0
@export var speed_bonus: float = 1.25
@export var fire_rate_bonus: float = 1.2

var _aura: Area2D
var _buffed: Dictionary = {}


func _ready() -> void:
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
	if target and is_instance_valid(target) and current_state == State.CHASE:
		var dist := global_position.distance_to(target.global_position)
		if dist < 120.0:
			var away := (global_position - target.global_position).normalized()
			velocity = away * speed * speed_buff
			move_and_slide()
			_update_legs(delta)


func _on_aura_enter(body: Node2D) -> void:
	if body == self:
		return
	if body is EnemyBase and body != self:
		(body as EnemyBase).speed_buff = speed_bonus
		(body as EnemyBase).fire_rate_buff = fire_rate_bonus
		_buffed[body] = true


func _on_aura_exit(body: Node2D) -> void:
	if body is EnemyBase and _buffed.has(body):
		(body as EnemyBase).speed_buff = 1.0
		(body as EnemyBase).fire_rate_buff = 1.0
		_buffed.erase(body)


func _die() -> void:
	for body in _buffed.keys():
		if is_instance_valid(body) and body is EnemyBase:
			(body as EnemyBase).speed_buff = 1.0
			(body as EnemyBase).fire_rate_buff = 1.0
	_buffed.clear()
	super._die()


func _perform_attack() -> void:
	if bullet_scene == null or target == null:
		return
	var bullet: Area2D = bullet_scene.instantiate()
	var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
	if container:
		container.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	bullet.activate(spawn_pos, dir.angle(), 480.0, damage)
	apply_recoil(3.0)
	var flash_rot: float = torso_container.rotation if torso_container else dir.angle()
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "pistol")
