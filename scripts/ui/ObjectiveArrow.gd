class_name ObjectiveArrow
extends Control

## Screen-edge arrow pointing toward the active off-screen objective target.

const PIXELS_PER_METER: float = 16.0
const EDGE_MARGIN: float = 48.0
const GOLD: Color = Color(0.95, 0.82, 0.28, 0.95)

var _targets: Array[Node2D] = []
var _player: Node2D = null
var _arrow: Polygon2D
var _distance_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([
		Vector2(0, -14),
		Vector2(10, 10),
		Vector2(0, 4),
		Vector2(-10, 10),
	])
	_arrow.color = GOLD
	_arrow.visible = false
	add_child(_arrow)

	_distance_label = Label.new()
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_distance_label.add_theme_font_size_override("font_size", 12)
	_distance_label.add_theme_color_override("font_color", GOLD)
	_distance_label.visible = false
	_distance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_distance_label)


func set_targets(targets: Array) -> void:
	_targets.clear()
	for t in targets:
		if is_instance_valid(t) and t is Node2D:
			_targets.append(t as Node2D)
	if _targets.is_empty():
		_hide()


func clear_targets() -> void:
	_targets.clear()
	_hide()


func _process(_delta: float) -> void:
	_resolve_player()
	_prune_targets()
	if _player == null or _targets.is_empty():
		_hide()
		return

	var target: Node2D = _pick_closest_target()
	if target == null:
		_hide()
		return

	var camera := get_viewport().get_camera_2d()
	if camera == null:
		_hide()
		return

	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * target.global_position
	var viewport_size: Vector2 = get_viewport_rect().size
	var on_screen: bool = (
		screen_pos.x >= EDGE_MARGIN
		and screen_pos.x <= viewport_size.x - EDGE_MARGIN
		and screen_pos.y >= EDGE_MARGIN
		and screen_pos.y <= viewport_size.y - EDGE_MARGIN
	)
	if on_screen:
		_hide()
		return

	var center: Vector2 = viewport_size * 0.5
	var dir: Vector2 = (screen_pos - center).normalized()
	if dir.length_squared() < 0.0001:
		_hide()
		return

	var edge_pos: Vector2 = _clamp_to_edge(center, dir, viewport_size)
	_arrow.visible = true
	_arrow.position = edge_pos
	_arrow.rotation = dir.angle() + PI * 0.5

	var dist_m: int = int(round((_player.global_position.distance_to(target.global_position)) / PIXELS_PER_METER))
	_distance_label.text = "%d m" % dist_m
	_distance_label.visible = true
	_distance_label.reset_size()
	_distance_label.position = edge_pos + Vector2(-24.0, 16.0)


func _pick_closest_target() -> Node2D:
	var best: Node2D = null
	var best_d: float = INF
	for t in _targets:
		if not is_instance_valid(t):
			continue
		var d: float = _player.global_position.distance_squared_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t
	return best


func _clamp_to_edge(center: Vector2, dir: Vector2, viewport_size: Vector2) -> Vector2:
	var half: Vector2 = viewport_size * 0.5 - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var scale_x: float = INF if absf(dir.x) < 0.0001 else half.x / absf(dir.x)
	var scale_y: float = INF if absf(dir.y) < 0.0001 else half.y / absf(dir.y)
	var scale: float = minf(scale_x, scale_y)
	return center + dir * scale


func _resolve_player() -> void:
	if is_instance_valid(_player):
		return
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node2D:
		_player = players[0] as Node2D


func _prune_targets() -> void:
	var kept: Array[Node2D] = []
	for t in _targets:
		if not is_instance_valid(t):
			continue
		if t is EnemyBase and t.current_state == EnemyBase.State.DEAD:
			continue
		if t.get("is_destroyed") == true:
			continue
		kept.append(t)
	_targets = kept


func _hide() -> void:
	if _arrow:
		_arrow.visible = false
	if _distance_label:
		_distance_label.visible = false
