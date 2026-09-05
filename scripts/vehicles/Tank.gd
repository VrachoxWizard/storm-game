extends VehicleBase

## T-55 Tank mini-boss — slow turret, explosive shells, rear weak point.

@export var shell_scene: PackedScene
@export var shell_damage: int = 40
@export var shell_radius: float = 70.0
@export var fire_cooldown: float = 2.5

var _can_fire: bool = true
var _turret_angle: float = 0.0


func _ready() -> void:
	max_health = 500
	armor_threshold = 18
	speed = 45.0
	super._ready()


func _vehicle_ai(delta: float) -> void:
	if target and is_instance_valid(target):
		var desired := (target.global_position - global_position).angle()
		_turret_angle = lerp_angle(_turret_angle, desired, 1.2 * delta)
		rotation = _turret_angle
		var dist := global_position.distance_to(target.global_position)
		if dist > 250.0:
			velocity = Vector2.RIGHT.rotated(rotation) * speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		if _can_fire and dist < 420.0:
			_fire_shell()
	else:
		velocity = Vector2.ZERO


func take_damage(amount: int) -> void:
	# Rear weak point: attacker behind tank takes 3x
	if target and is_instance_valid(target):
		var to_attacker := (target.global_position - global_position).normalized()
		var rear := -Vector2.RIGHT.rotated(rotation)
		if rear.dot(to_attacker) > 0.5:
			super.take_damage(amount * 3)
			return
	super.take_damage(amount)


func _fire_shell() -> void:
	_can_fire = false
	var origin := global_position + Vector2.RIGHT.rotated(_turret_angle) * 40.0
	if shell_scene:
		var shell: Area2D = shell_scene.instantiate()
		get_tree().root.get_node("Main/Projectiles").add_child(shell)
		if shell.has_method("launch"):
			shell.launch(origin, _turret_angle, 320.0, shell_damage, shell_radius, shell_damage, false)
	else:
		# Fallback splash at predicted point
		if target:
			ExplosionHelper.explode(get_tree(), target.global_position, shell_radius, shell_damage, 14.0, true)
	get_tree().create_timer(fire_cooldown).timeout.connect(func() -> void:
		_can_fire = true
	)
