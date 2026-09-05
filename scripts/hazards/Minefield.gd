extends Area2D

## Minefield hazard — explodes on player contact unless dodging.

@export var damage: int = 40
@export var explosion_radius: float = 50.0

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Player
	body_entered.connect(_on_body_entered)
	add_to_group("minefield")


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	if body.get("is_dodging"):
		return
	_triggered = true
	if body.has_method("take_damage"):
		body.take_damage(damage)
	ExplosionHelper.explode(get_tree(), global_position, explosion_radius, damage / 2, 8.0, false)
	queue_free()
