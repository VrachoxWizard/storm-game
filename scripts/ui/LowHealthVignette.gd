extends Control

## Red edge vignette when player health is low.

var _pulse: float = 0.0
var _active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	modulate = Color(1, 0, 0, 0)


func set_health_ratio(ratio: float) -> void:
	_active = ratio < 0.3 and ratio > 0.0


func _process(delta: float) -> void:
	if not _active:
		modulate.a = lerpf(modulate.a, 0.0, 5.0 * delta)
		return
	_pulse += delta * 4.0
	modulate = Color(0.8, 0.05, 0.05, 0.15 + 0.12 * absf(sin(_pulse)))


func _draw() -> void:
	var r := get_rect()
	var thickness := 48.0
	draw_rect(Rect2(0, 0, r.size.x, thickness), Color.WHITE)
	draw_rect(Rect2(0, r.size.y - thickness, r.size.x, thickness), Color.WHITE)
	draw_rect(Rect2(0, 0, thickness, r.size.y), Color.WHITE)
	draw_rect(Rect2(r.size.x - thickness, 0, thickness, r.size.y), Color.WHITE)
