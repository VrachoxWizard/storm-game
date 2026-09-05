extends Area2D

## Slow rocket projectile that explodes on impact.

signal exploded(position: Vector2)

var speed: float = 280.0
var damage: int = 40
var explosion_radius: float = 80.0
var explosion_damage: int = 40
var _active: bool = false
var _from_player: bool = true

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	lifetime_timer.timeout.connect(_on_lifetime)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	position += Vector2.RIGHT.rotated(rotation) * speed * delta


func launch(
	pos: Vector2,
	rot: float,
	spd: float,
	direct_damage: int,
	radius: float,
	splash_damage: int,
	from_player: bool = true
) -> void:
	global_position = pos
	rotation = rot
	speed = spd
	damage = direct_damage
	explosion_radius = radius
	explosion_damage = splash_damage
	_from_player = from_player
	_active = true
	visible = true
	monitoring = true
	if from_player:
		collision_layer = 4  # PlayerBullets
		collision_mask = 2 | 32 | 64  # Enemies, Environment, Vehicles
	else:
		collision_layer = 8  # EnemyBullets
		collision_mask = 1 | 32  # Player, Environment
	lifetime_timer.start()


func _on_lifetime() -> void:
	_detonate()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if _from_player:
			var sm = get_node_or_null("/root/ScoreManager")
			if sm and sm.has_method("record_shot_hit"):
				sm.record_shot_hit()
	_detonate()


func _on_area_entered(_area: Area2D) -> void:
	_detonate()


func _detonate() -> void:
	if not _active:
		return
	_active = false
	monitoring = false
	var pos := global_position
	exploded.emit(pos)
	ExplosionHelper.explode(
		get_tree(),
		pos,
		explosion_radius,
		explosion_damage,
		12.0,
		not _from_player
	)
	queue_free()
