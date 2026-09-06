class_name WeaponSlotPanel
extends Control

## Three-slot weapon UI panel with active highlight and inked silhouettes.

const INK: Color = Color(0.12, 0.1, 0.08, 0.95)
const INK_MUTED: Color = Color(0.32, 0.28, 0.24, 0.6)
const PARCHMENT: Color = Color(0.92, 0.88, 0.79, 0.9)
const ACTIVE_BORDER: Color = Color(0.95, 0.8, 0.25, 1.0)

var _slots: Array = []
var _current_slot: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(220, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_slots(slots: Array, current_slot: int) -> void:
	_slots = slots
	_current_slot = current_slot
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, PARCHMENT)
	draw_rect(rect, INK, false, 2.0)
	draw_rect(rect.grow(-2.0), INK_MUTED, false, 1.0)

	var pad: float = 6.0
	var cell_w: float = (size.x - pad * 2.0) / 3.0
	var cell_h: float = size.y - pad * 2.0
	for i in range(3):
		var cell := Rect2(Vector2(pad + cell_w * i, pad), Vector2(cell_w, cell_h))
		_draw_cell(i, cell)


func _draw_cell(i: int, cell: Rect2) -> void:
	var weapon = null
	if i >= 0 and i < _slots.size():
		weapon = _slots[i]
	var is_active := i == _current_slot and weapon != null

	draw_rect(cell, Color(1, 1, 1, 0.0))
	draw_rect(cell, ACTIVE_BORDER if is_active else INK_MUTED, false, 2.0 if is_active else 1.0)
	draw_rect(cell.grow(-2.0), INK, false, 1.0 if is_active else 0.5)

	# Key badge
	var key_rect := Rect2(cell.position + Vector2(3, 3), Vector2(12, 12))
	draw_rect(key_rect, INK, true)
	draw_string(get_theme_default_font(), key_rect.position + Vector2(3, 10), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PARCHMENT)

	if weapon == null:
		draw_string(get_theme_default_font(), cell.position + Vector2(18, cell.size.y * 0.62), "empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK_MUTED)
		return

	var name: String = str(weapon.weapon_name) if ("weapon_name" in weapon) else "Weapon"
	var w := name.to_lower()

	var cx: float = cell.position.x + cell.size.x * 0.5
	var cy: float = cell.position.y + cell.size.y * 0.45
	if "shotgun" in w or "hawk" in w:
		_draw_shotgun(cx, cy)
	elif "pistol" in w or "php" in w:
		_draw_pistol(cx, cy)
	elif "smg" in w or "škorpion" in w or "skorpion" in w:
		_draw_smg(cx, cy)
	elif "m48" in w or "mauser" in w or "sniper" in w:
		_draw_sniper(cx, cy)
	elif "rpg" in w or "rocket" in w:
		_draw_rpg(cx, cy)
	else:
		_draw_rifle(cx, cy)

	var short_name := _shorten(name)
	draw_string(get_theme_default_font(), cell.position + Vector2(18, cell.size.y - 6), short_name, HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 20, 10, INK)


func _shorten(name: String) -> String:
	var s := name
	s = s.replace("Zastava ", "")
	s = s.replace("Hawk ", "")
	s = s.replace("PHP ", "")
	s = s.replace(" vz.61", "")
	return s


func _draw_rifle(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 18, cy - 2, 32, 4), INK)
	draw_rect(Rect2(cx - 20, cy - 1, 4, 2), INK)
	var mag_pts: PackedVector2Array = [Vector2(cx + 2, cy + 2), Vector2(cx - 1, cy + 8), Vector2(cx - 4, cy + 7), Vector2(cx - 1, cy + 2)]
	draw_colored_polygon(mag_pts, INK)
	draw_line(Vector2(cx - 8, cy + 2), Vector2(cx - 11, cy + 7), INK, 2.2)


func _draw_shotgun(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 16, cy - 3, 30, 4), INK)
	draw_rect(Rect2(cx + 1, cy + 1, 9, 3), INK)
	var stock_pts: PackedVector2Array = [Vector2(cx - 7, cy - 3), Vector2(cx - 18, cy - 1), Vector2(cx - 18, cy + 5), Vector2(cx - 9, cy + 2)]
	draw_colored_polygon(stock_pts, INK)


func _draw_pistol(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 7, cy - 4, 16, 5), INK)
	draw_line(Vector2(cx - 3, cy + 1), Vector2(cx - 7, cy + 7), INK, 3.0)


func _draw_smg(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 11, cy - 2, 22, 4), INK)
	draw_rect(Rect2(cx + 2, cy + 2, 3, 7), INK)
	draw_line(Vector2(cx - 6, cy + 2), Vector2(cx - 8, cy + 7), INK, 2.2)


func _draw_sniper(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 20, cy - 1, 40, 3), INK)
	draw_rect(Rect2(cx - 6, cy - 5, 12, 3), INK)


func _draw_rpg(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 16, cy - 2, 30, 4), INK)
	var warhead_pts: PackedVector2Array = [Vector2(cx + 14, cy - 2), Vector2(cx + 20, cy), Vector2(cx + 14, cy + 2)]
	draw_colored_polygon(warhead_pts, INK)
