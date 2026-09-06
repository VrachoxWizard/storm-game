extends Camera2D

## Stable tactical view. Enemy movement and kills never change magnification.
@export var field_zoom: float = 1.15
var _ground: Control

func _ready() -> void:
	_ground = get_parent().get_parent().get_node_or_null("Ground") as Control
	get_viewport().size_changed.connect(_configure_view)
	_configure_view()

func _configure_view() -> void:
	var magnification: float = field_zoom
	if is_instance_valid(_ground):
		var bounds := _ground.get_global_rect()
		var viewport_size := get_viewport_rect().size
		magnification = maxf(field_zoom, maxf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y))
		limit_left = int(bounds.position.x)
		limit_top = int(bounds.position.y)
		limit_right = int(bounds.end.x)
		limit_bottom = int(bounds.end.y)
	zoom = Vector2.ONE * magnification
	reset_smoothing()
