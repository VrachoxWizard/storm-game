extends Area2D

## A single projectile. Managed by an object pool — never freed, only activated/deactivated.

var speed: float = 0.0
var damage: int = 0
var _active: bool = false

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if lifetime_timer and not lifetime_timer.timeout.is_connected(deactivate):
		lifetime_timer.timeout.connect(deactivate)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
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
	if lifetime_timer and lifetime_timer.is_inside_tree():
		lifetime_timer.start()


func deactivate() -> void:
	_active = false
	visible = false
	monitoring = false
	monitorable = false
	if lifetime_timer and is_instance_valid(lifetime_timer) and lifetime_timer.is_inside_tree():
		lifetime_timer.stop()
	global_position = Vector2(-9999, -9999)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if (collision_layer & 4) != 0:
			var sm = get_node_or_null("/root/ScoreManager")
			if sm and sm.has_method("record_shot_hit"):
				sm.record_shot_hit()
		var vfx := get_tree().root.get_node_or_null("Main/CombatVfx")
		if vfx and body.is_in_group("enemies") and vfx.has_method("spawn_blood"):
			vfx.spawn_blood(global_position)
		elif vfx and vfx.has_method("spawn_dust"):
			vfx.spawn_dust(global_position)
	deactivate()


func _on_area_entered(_area: Area2D) -> void:
	var vfx := get_tree().root.get_node_or_null("Main/CombatVfx")
	if vfx and vfx.has_method("spawn_dust"):
		vfx.spawn_dust(global_position)
	deactivate()
