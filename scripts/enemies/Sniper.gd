extends EnemyBase

## Long-range sniper with red laser telegraph before firing.

@export var aim_time: float = 1.5
@export var bullet_damage: int = 35

var _aiming: bool = false
var _laser: Line2D


func _ready() -> void:
	super._ready()
	max_health = 40
	health = max_health
	speed = 40.0
	attack_range = 450.0
	detection_range = 500.0
	damage = bullet_damage
	attack_cooldown = 3.0
	_laser = Line2D.new()
	_laser.width = 2.0
	_laser.default_color = Color(1.0, 0.1, 0.1, 0.8)
	_laser.visible = false
	add_child(_laser)


func _physics_process(delta: float) -> void:
	if _aiming and target and is_instance_valid(target):
		_laser.clear_points()
		_laser.add_point(Vector2.ZERO)
		_laser.add_point(to_local(target.global_position))
		look_at(target.global_position)
		return
	super._physics_process(delta)


func _perform_attack() -> void:
	if _aiming or target == null:
		return
	_aiming = true
	_laser.visible = true
	# Stay still while aiming
	velocity = Vector2.ZERO
	get_tree().create_timer(aim_time).timeout.connect(_fire_sniper_shot)


func _fire_sniper_shot() -> void:
	_aiming = false
	_laser.visible = false
	_laser.clear_points()
	if target == null or not is_instance_valid(target):
		return
	if current_state == State.DEAD:
		return
	if target.has_method("take_damage"):
		# Hitscan with slight miss chance if player dodging
		if target.get("is_dodging"):
			return
		target.take_damage(bullet_damage)
