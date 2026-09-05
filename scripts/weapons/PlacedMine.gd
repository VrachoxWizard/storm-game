extends Area2D

## Player-placed mine that detonates when enemies or vehicles enter.

@export var explosion_radius: float = 60.0
@export var explosion_damage: int = 50

var _armed: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 64  # Enemies, Vehicles
	body_entered.connect(_on_body_entered)
	# Arm after brief delay so placer doesn't trigger
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		_armed = true
		monitoring = true
	)
	monitoring = false


func _on_body_entered(body: Node2D) -> void:
	if not _armed:
		return
	if body.is_in_group("player"):
		return
	ExplosionHelper.explode(get_tree(), global_position, explosion_radius, explosion_damage, 8.0, false)
	queue_free()
