class_name DecalManager
extends Node2D

## Persistent battlefield decal manager.
## Maintains a FIFO capped queue (max 250 decals) for blood stains, blast scorches,
## spent brass casings, and tread marks with smooth alpha-fading on eviction.

const MAX_DECALS: int = 250

const BLOOD_TEX: Texture2D = preload("res://assets/sprites/vfx/blood_splatter_decals.png")
const SCORCH_TEX: Texture2D = preload("res://assets/sprites/vfx/scorch_mark.png")
const CASING_RIFLE_TEX: Texture2D = preload("res://assets/sprites/vfx/shell_casing_rifle.png")
const CASING_SHOTGUN_TEX: Texture2D = preload("res://assets/sprites/vfx/shell_casing_shotgun.png")

static var instance: DecalManager = null

var _decals: Array[Node2D] = []
var _tank_tread_tex: ImageTexture = null
var _apc_tread_tex: ImageTexture = null


func _init() -> void:
	if instance == null:
		instance = self


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


# ---------------------------------------------------------
# Static API (Callable globally on DecalManager or instances)
# ---------------------------------------------------------

static func stamp_blood(pos: Vector2, normal: Vector2 = Vector2.ZERO) -> void:
	if instance:
		instance._do_stamp_blood(pos, normal)


static func stamp_scorch(pos: Vector2, scale_factor: float = 1.0) -> void:
	if instance:
		instance._do_stamp_scorch(pos, scale_factor)


static func spawn_casing(pos: Vector2, eject_dir: Vector2, is_shotgun: bool = false) -> void:
	if instance:
		instance._do_spawn_casing(pos, eject_dir, is_shotgun)


static func stamp_tread(pos: Vector2, rot: float, is_tank: bool = false) -> void:
	if instance:
		instance._do_stamp_tread(pos, rot, is_tank)


static func clear_decals() -> void:
	if instance:
		instance._do_clear_decals()


static func get_decal_count() -> int:
	if instance:
		return instance._do_get_decal_count()
	return 0


# ---------------------------------------------------------
# Internal Implementation
# ---------------------------------------------------------

func _register_decal(decal: Node2D) -> void:
	add_child(decal)
	_decals.append(decal)
	while _decals.size() > MAX_DECALS:
		var oldest: Node2D = _decals.pop_front()
		_recycle_decal(oldest)


func _recycle_decal(decal: Node2D) -> void:
	if not is_instance_valid(decal):
		return
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(decal, "modulate:a", 0.0, 0.3)
			tween.tween_callback(decal.queue_free)
			return
	decal.queue_free()


func _do_stamp_blood(pos: Vector2, normal: Vector2 = Vector2.ZERO) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = BLOOD_TEX
	sprite.global_position = pos

	# Directional splatter or random radial orientation
	if normal != Vector2.ZERO:
		sprite.rotation = normal.angle() + randf_range(-0.35, 0.35)
	else:
		sprite.rotation = randf_range(0.0, TAU)

	var base_scale: float = randf_range(0.7, 1.15)
	var ink_shade: float = randf_range(0.45, 0.7)
	sprite.modulate = Color(ink_shade, 0.06, 0.06, randf_range(0.8, 0.95))

	if is_inside_tree():
		sprite.scale = Vector2.ONE * (base_scale * 0.65)
		_register_decal(sprite)
		var tween := create_tween()
		if tween:
			tween.tween_property(sprite, "scale", Vector2.ONE * base_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		sprite.scale = Vector2.ONE * base_scale
		_register_decal(sprite)


func _do_stamp_scorch(pos: Vector2, scale_factor: float = 1.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = SCORCH_TEX
	sprite.global_position = pos
	sprite.rotation = randf_range(0.0, TAU)

	var target_scale: Vector2 = Vector2.ONE * (scale_factor * randf_range(0.85, 1.15))
	sprite.modulate = Color(0.18, 0.15, 0.12, randf_range(0.8, 0.95))

	if is_inside_tree():
		sprite.scale = target_scale * 0.8
		_register_decal(sprite)
		var tween := create_tween()
		if tween:
			tween.tween_property(sprite, "scale", target_scale, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		sprite.scale = target_scale
		_register_decal(sprite)


func _do_spawn_casing(pos: Vector2, eject_dir: Vector2, is_shotgun: bool = false) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = CASING_SHOTGUN_TEX if is_shotgun else CASING_RIFLE_TEX
	sprite.global_position = pos
	sprite.rotation = randf_range(0.0, TAU)

	if is_shotgun:
		sprite.modulate = Color(0.9, 0.35, 0.35, 1.0)
	else:
		sprite.modulate = Color(0.95, 0.85, 0.5, 1.0)

	_register_decal(sprite)

	var spread_angle: float = randf_range(-0.4, 0.4)
	var dir: Vector2 = eject_dir.rotated(spread_angle).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	var travel_dist: float = randf_range(24.0, 36.0)
	var bounce_dist: float = randf_range(6.0, 12.0)
	var bounce_pos: Vector2 = pos + dir * travel_dist
	var final_pos: Vector2 = bounce_pos + dir.rotated(randf_range(-0.5, 0.5)) * bounce_dist
	var final_rot: float = sprite.rotation + randf_range(-PI, PI) * 2.0

	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.set_parallel(false)
			tween.tween_property(sprite, "position", bounce_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "position", final_pos, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			var rot_tween := create_tween()
			rot_tween.tween_property(sprite, "rotation", final_rot, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _do_stamp_tread(pos: Vector2, rot: float, is_tank: bool = false) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _get_tread_texture(is_tank)
	sprite.global_position = pos
	sprite.rotation = rot
	sprite.modulate = Color(0.2, 0.17, 0.14, 0.45 if is_tank else 0.35)

	_register_decal(sprite)


func _get_tread_texture(is_tank: bool) -> ImageTexture:
	if is_tank:
		if _tank_tread_tex == null:
			_tank_tread_tex = _generate_tread_texture(24, 16, 4, 14)
		return _tank_tread_tex
	else:
		if _apc_tread_tex == null:
			_apc_tread_tex = _generate_tread_texture(20, 12, 2, 12)
		return _apc_tread_tex


func _generate_tread_texture(width: int, height: int, track_width: int, spacing: int) -> ImageTexture:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink_col := Color(0.12, 0.1, 0.08, 0.9)
	var left_start: int = max(0, int((width - spacing) / 2.0) - track_width)
	var right_start: int = min(width - track_width, int((width + spacing) / 2.0))
	for y in range(height):
		if y % 3 != 0:
			for x in range(left_start, left_start + track_width):
				if x >= 0 and x < width:
					img.set_pixel(x, y, ink_col)
			for x in range(right_start, right_start + track_width):
				if x >= 0 and x < width:
					img.set_pixel(x, y, ink_col)
	return ImageTexture.create_from_image(img)


func _do_clear_decals() -> void:
	for decal in _decals:
		if is_instance_valid(decal):
			decal.queue_free()
	_decals.clear()


func _do_get_decal_count() -> int:
	return _decals.size()
