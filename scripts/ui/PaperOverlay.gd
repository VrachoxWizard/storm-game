extends CanvasLayer

## Full-screen paper/ink post-process — samples the screen buffer.

func _ready() -> void:
	layer = 80
	# Ensure we can read the back buffer
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)

	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/paper_overlay.gdshader")

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 1)
	rect.material = mat
	add_child(rect)
