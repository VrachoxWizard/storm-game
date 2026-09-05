extends CanvasLayer

## Full-screen paper/ink post-process — samples the screen buffer
## with parchment fibers, ink bleed, and combat chromatic shock pulse.

var _mat: ShaderMaterial = null
var _shock_tween: Tween = null


func _ready() -> void:
	add_to_group("paper_overlay")
	layer = 80
	# Ensure we can read the back buffer
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)

	_mat = ShaderMaterial.new()
	_mat.shader = load("res://assets/shaders/paper_overlay.gdshader")
	var parchment_tex: Texture2D = load("res://assets/sprites/ui/paper_parchment_bg.png")
	if parchment_tex:
		_mat.set_shader_parameter("paper_texture", parchment_tex)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 1)
	rect.material = _mat
	add_child(rect)


## Triggers a quick chromatic aberration shockwave pulse that fades to 0 over 0.1s.
func trigger_combat_shock(intensity: float = 0.03) -> void:
	if _mat == null:
		return
	if _shock_tween and _shock_tween.is_valid():
		_shock_tween.kill()
	_mat.set_shader_parameter("shock_aberration", intensity)
	_shock_tween = create_tween()
	_shock_tween.tween_method(
		func(val: float) -> void:
			if _mat:
				_mat.set_shader_parameter("shock_aberration", val),
		intensity,
		0.0,
		0.1
	)
