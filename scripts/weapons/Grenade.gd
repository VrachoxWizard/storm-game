extends Area2D

## M75 hand grenade — throwable with fuse and warning circle telegraph.

const WEAPON_NAME: String = "M75"

var fuse_time: float = 3.0
var explosion_radius: float = 70.0
var explosion_damage: int = 45
var throw_speed: float = 220.0
var _velocity: Vector2 = Vector2.ZERO
var _fuse_left: float = 0.0
var _from_player: bool = true
var _landing: Vector2
var _flight_left: float = 0.0

@onready var warning: Sprite2D = $WarningCircle
@onready var sprite: Sprite2D = $Sprite2D


func throw_at(origin: Vector2, direction: Vector2, from_player: bool = true) -> void:
	global_position = origin
	_landing = origin + direction.limit_length(320.0)
	_flight_left = 0.65
	_velocity = (_landing - origin) / _flight_left
	_fuse_left = fuse_time
	_from_player = from_player
	monitoring = false
	warning.scale = Vector2.ONE * (explosion_radius / 32.0)
	warning.modulate = Color(1, 0.2, 0.2, 0.35)


func _physics_process(delta: float) -> void:
	_fuse_left -= delta
	if _flight_left > 0.0:
		var step: float = minf(delta, _flight_left)
		global_position += _velocity * step
		_flight_left -= step
	warning.global_position = _landing
	warning.modulate.a = lerpf(0.15, 0.55, 1.0 - (_fuse_left / fuse_time))
	if _fuse_left <= 0.0:
		_detonate()


func _detonate() -> void:
	ExplosionHelper.explode(
		get_tree(),
		global_position,
		explosion_radius,
		explosion_damage,
		10.0,
		not _from_player,
		_from_player
	)
	queue_free()
