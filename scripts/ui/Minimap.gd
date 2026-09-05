extends Control

## Tactical field-map radar showing player, enemies, vehicles, emplacements, and compass rose.

@export var radar_range: float = 600.0
@export var radar_size: float = 120.0
@export var redraw_hz: float = 12.0

const COMPASS_TEX: Texture2D = preload("res://assets/sprites/ui/minimap_compass.png")
const INK_DARK: Color = Color(0.14, 0.11, 0.09, 0.95)
const INK_MUTED: Color = Color(0.32, 0.28, 0.24, 0.6)
const PARCHMENT_BG: Color = Color(0.91, 0.86, 0.77, 0.88)
const GRID_COLOR: Color = Color(0.38, 0.34, 0.28, 0.32)

var _player: Node2D = null
var _redraw_timer: float = 0.0
var _cache_timer: float = 0.0
var _cached_blips: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = Vector2(radar_size, radar_size)
	size = Vector2(radar_size, radar_size)


func setup(player: Node2D) -> void:
	_player = player


func _process(delta: float) -> void:
	_cache_timer += delta
	if _cache_timer >= 0.2:
		_cache_timer = 0.0
		_refresh_blip_cache()
	_redraw_timer += delta
	if _redraw_timer >= 1.0 / maxf(redraw_hz, 1.0):
		_redraw_timer = 0.0
		queue_redraw()


func _refresh_blip_cache() -> void:
	_cached_blips.clear()
	if _player == null or not is_instance_valid(_player) or not is_inside_tree():
		return
	_cache_group("bunker", Color(0.55, 0.18, 0.65), 3.5, false)
	_cache_group("emplacement", Color(0.55, 0.18, 0.65), 3.5, false)
	_cache_group("vehicle", Color(0.92, 0.52, 0.12), 3.5, true)
	_cache_group("enemies", Color(0.85, 0.15, 0.15), 3.0, false)
	_cache_group("objective", Color(0.95, 0.8, 0.2), 4.0, false)
	_cache_group("flag", Color(0.95, 0.8, 0.2), 4.0, false)


func _cache_group(group: String, color: Color, blip_radius: float, is_box: bool) -> void:
	for node in get_tree().get_nodes_in_group(group):
		if node == _player or not (node is Node2D):
			continue
		var offset: Vector2 = (node as Node2D).global_position - _player.global_position
		if offset.length() > radar_range:
			continue
		_cached_blips.append({
			"offset": offset,
			"color": color,
			"radius": blip_radius,
			"box": is_box,
		})


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(radar_size, radar_size))
	var center := Vector2(radar_size * 0.5, radar_size * 0.5)

	draw_rect(rect, PARCHMENT_BG)
	draw_rect(rect, INK_DARK, false, 2.0)
	draw_rect(rect.grow(-3.0), INK_MUTED, false, 1.0)
	draw_circle(Vector2(6.0, 6.0), 3.5, Color(0.75, 0.6, 0.2, 0.95))
	draw_circle(Vector2(5.5, 5.5), 1.5, Color(0.95, 0.85, 0.45, 0.95))

	var grid_step: float = radar_size / 4.0
	for i in range(1, 4):
		var offset: float = i * grid_step
		draw_line(Vector2(offset, 4), Vector2(offset, radar_size - 4), GRID_COLOR, 1.0)
		draw_line(Vector2(4, offset), Vector2(radar_size - 4, offset), GRID_COLOR, 1.0)

	if COMPASS_TEX:
		var compass_sz := Vector2(48.0, 48.0)
		var compass_pos := center - compass_sz * 0.5
		draw_texture_rect(COMPASS_TEX, Rect2(compass_pos, compass_sz), false, Color(1, 1, 1, 0.38))

	draw_arc(center, radar_size * 0.44, 0, TAU, 32, INK_MUTED, 1.0)

	if _player == null or not is_instance_valid(_player):
		return

	for blip in _cached_blips:
		var mapped: Vector2 = center + (blip["offset"] / radar_range) * (radar_size * 0.44)
		var color: Color = blip["color"]
		var blip_radius: float = blip["radius"]
		if blip["box"]:
			var half := blip_radius
			draw_rect(Rect2(mapped - Vector2(half, half), Vector2(half * 2.0, half * 2.0)), color)
			draw_rect(Rect2(mapped - Vector2(half, half), Vector2(half * 2.0, half * 2.0)), INK_DARK, false, 1.0)
		else:
			draw_circle(mapped, blip_radius, color)
			draw_arc(mapped, blip_radius, 0, TAU, 12, INK_DARK, 1.0)

	var heading: float = _player.torso_container.global_rotation if ("torso_container" in _player and _player.torso_container) else _player.rotation
	var p_tip: Vector2 = center + Vector2(6.0, 0.0).rotated(heading)
	var p_left: Vector2 = center + Vector2(-4.0, -4.0).rotated(heading)
	var p_right: Vector2 = center + Vector2(-4.0, 4.0).rotated(heading)
	draw_colored_polygon([p_tip, p_left, p_right], Color(0.12, 0.32, 0.78, 0.95))
	draw_polyline([p_tip, p_left, p_right, p_tip], INK_DARK, 1.2)
