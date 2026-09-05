extends Area2D

## A single projectile. Managed by an object pool — never freed, only activated/deactivated.

var speed: float = 0.0
var damage: int = 0
var _active: bool = false

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	lifetime_timer.timeout.connect(deactivate)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	deactivate()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	position += Vector2.RIGHT.rotated(rotation) * speed * delta


func activate(pos: Vector2, rot: float, spd: float, dmg: int) -> void:
	global_position = pos
	rotation = rot
	speed = spd
	damage = dmg
	_active = true
	visible = true
	monitoring = true
	monitorable = true
	lifetime_timer.start()


func deactivate() -> void:
	_active = false
	visible = false
	monitoring = false
	monitorable = false
	lifetime_timer.stop()
	global_position = Vector2(-9999, -9999)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		ScoreManager.record_shot_hit()
	deactivate()


func _on_area_entered(_area: Area2D) -> void:
	deactivate()
