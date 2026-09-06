class_name ObjectiveMarker
extends Node2D

## World-space gold beacon that follows the active objective target.
## Registers in the "objective" (or "flag") group for minimap gold blips.

@export var is_flag: bool = false
@export var active: bool = true:
	set(value):
		active = value
		visible = value
		_sync_group()

var _target: Node2D = null
var _bob_time: float = 0.0
var _icon: Sprite2D
var _beam: Line2D
var _ring: Sprite2D


func _ready() -> void:
	z_index = 20
	_build_visuals()
	_sync_group()


func set_target(node: Node2D) -> void:
	_target = node
	if is_instance_valid(_target):
		global_position = _target.global_position
	active = true
	visible = true
	_sync_group()


func deactivate() -> void:
	active = false
	_target = null
	visible = false
	_sync_group()


func _process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(_target):
		deactivate()
		return
	if _target is EnemyBase and _target.current_state == EnemyBase.State.DEAD:
		deactivate()
		return
	if _target.get("is_destroyed") == true:
		deactivate()
		return
	global_position = _target.global_position
	_bob_time += delta * 3.0
	var bob: float = sin(_bob_time) * 4.0
	if _icon:
		_icon.position.y = -36.0 + bob
	if _beam:
		_beam.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, -36.0 + bob)])
	# Soft pulse on the icon.
	if _icon:
		var pulse: float = 0.85 + 0.15 * sin(_bob_time * 1.5)
		_icon.modulate.a = pulse


func _build_visuals() -> void:
	_beam = Line2D.new()
	_beam.width = 1.5
	_beam.default_color = Color(0.95, 0.8, 0.25, 0.55)
	_beam.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, -36.0)])
	add_child(_beam)

	_ring = Sprite2D.new()
	_ring.texture = _make_ring_texture()
	_ring.modulate = Color(0.95, 0.8, 0.25, 0.45)
	_ring.scale = Vector2(0.9, 0.55)
	add_child(_ring)

	_icon = Sprite2D.new()
	_icon.texture = _make_diamond_texture()
	_icon.position = Vector2(0.0, -36.0)
	_icon.modulate = Color(1.0, 0.88, 0.35, 1.0)
	add_child(_icon)


func _sync_group() -> void:
	var group_name: String = "flag" if is_flag else "objective"
	var other: String = "objective" if is_flag else "flag"
	if is_in_group(other):
		remove_from_group(other)
	if active and is_inside_tree():
		if not is_in_group(group_name):
			add_to_group(group_name)
	else:
		if is_in_group(group_name):
			remove_from_group(group_name)


func _make_diamond_texture() -> ImageTexture:
	var size: int = 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	for y in range(size):
		for x in range(size):
			var dx: float = absf(float(x) + 0.5 - cx)
			var dy: float = absf(float(y) + 0.5 - cy)
			if dx + dy < 6.5:
				var edge: bool = dx + dy > 5.0
				if edge:
					img.set_pixel(x, y, Color(0.35, 0.25, 0.08, 0.95))
				else:
					img.set_pixel(x, y, Color(0.98, 0.85, 0.3, 0.95))
	return ImageTexture.create_from_image(img)


func _make_ring_texture() -> ImageTexture:
	var size: int = 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: float = Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - cy).length()
			if d > 18.0 and d < 21.0:
				img.set_pixel(x, y, Color(0.95, 0.8, 0.25, 0.85))
			elif d > 16.0 and d < 22.5:
				img.set_pixel(x, y, Color(0.95, 0.8, 0.25, 0.25))
	return ImageTexture.create_from_image(img)
