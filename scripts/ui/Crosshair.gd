extends Control

## Weapon-specific crosshair/reticle that follows the mouse position.

const INK: Color = Color(0.12, 0.1, 0.08, 0.9)
const INK_MUTED: Color = Color(0.25, 0.22, 0.18, 0.55)
const ALERT: Color = Color(0.85, 0.15, 0.15, 0.95)

var _weapon_manager: Node = null
var _player: Node = null
var _weapon_name: String = ""
var _spread_angle: float = 0.0
var _color: Color = INK
var _flash_tween: Tween = null


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func setup(weapon_manager: Node, player: Node) -> void:
	_weapon_manager = weapon_manager
	_player = player
	_refresh_weapon()
	if _weapon_manager and _weapon_manager.has_signal("weapon_switched"):
		if not _weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
			_weapon_manager.weapon_switched.connect(_on_weapon_switched)
	if _weapon_manager and _weapon_manager.has_signal("weapon_fired"):
		if not _weapon_manager.weapon_fired.is_connected(_on_weapon_fired):
			_weapon_manager.weapon_fired.connect(_on_weapon_fired)


func _process(_delta: float) -> void:
	if _player and is_instance_valid(_player) and bool(_player.get("_is_dead")):
		visible = false
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm and int(gm.get("current_state")) == int(gm.GameState.PAUSED):
		visible = false
		return
	visible = true
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = get_local_mouse_position()
	var w := _weapon_name.to_lower()
	if "shotgun" in w or "hawk" in w:
		_draw_shotgun_reticle(center)
	elif "sniper" in w or "m48" in w or "mauser" in w:
		_draw_sniper_reticle(center)
	elif "rpg" in w or "rocket" in w:
		_draw_rpg_reticle(center)
	else:
		_draw_default_reticle(center)


func _refresh_weapon() -> void:
	if _weapon_manager == null or not is_instance_valid(_weapon_manager):
		return
	if not _weapon_manager.has_method("get_current_weapon"):
		return
	var weapon = _weapon_manager.get_current_weapon()
	if weapon == null:
		return
	_weapon_name = str(weapon.weapon_name) if ("weapon_name" in weapon) else ""
	_spread_angle = float(weapon.spread_angle) if ("spread_angle" in weapon) else 0.0


func _on_weapon_switched(_weapon) -> void:
	_refresh_weapon()


func _on_weapon_fired() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_color = ALERT
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.08)
	_flash_tween.tween_callback(func() -> void:
		_color = INK
	)


func _draw_default_reticle(center: Vector2) -> void:
	draw_circle(center, 1.8, _color)
	draw_line(center + Vector2(-8, 0), center + Vector2(-3, 0), _color, 2.0)
	draw_line(center + Vector2(3, 0), center + Vector2(8, 0), _color, 2.0)
	draw_line(center + Vector2(0, -8), center + Vector2(0, -3), _color, 2.0)
	draw_line(center + Vector2(0, 3), center + Vector2(0, 8), _color, 2.0)


func _draw_shotgun_reticle(center: Vector2) -> void:
	var radius: float = clampf(_spread_angle * 200.0, 14.0, 34.0)
	# Corner ticks around a spread circle (no full circle to keep it clean).
	var t: float = 6.0
	var r: float = radius
	draw_line(center + Vector2(-r, -t), center + Vector2(-r, t), _color, 2.0)
	draw_line(center + Vector2(r, -t), center + Vector2(r, t), _color, 2.0)
	draw_line(center + Vector2(-t, -r), center + Vector2(t, -r), _color, 2.0)
	draw_line(center + Vector2(-t, r), center + Vector2(t, r), _color, 2.0)
	draw_circle(center, 1.6, _color)
	draw_arc(center, r, 0.0, TAU, 28, INK_MUTED, 1.0)


func _draw_sniper_reticle(center: Vector2) -> void:
	# Fine crosshair with a small center gap.
	var gap: float = 3.5
	var len: float = 14.0
	draw_circle(center, 1.4, _color)
	draw_line(center + Vector2(-len, 0), center + Vector2(-gap, 0), _color, 1.6)
	draw_line(center + Vector2(gap, 0), center + Vector2(len, 0), _color, 1.6)
	draw_line(center + Vector2(0, -len), center + Vector2(0, -gap), _color, 1.6)
	draw_line(center + Vector2(0, gap), center + Vector2(0, len), _color, 1.6)


func _draw_rpg_reticle(center: Vector2) -> void:
	var r: float = 22.0
	draw_arc(center, r, 0.0, TAU, 44, _color, 2.0)
	draw_circle(center, 2.0, _color)
