class_name GearIndicator
extends Control

## Icon-style grenade/mine counter with key hints.

const INK: Color = Color(0.12, 0.1, 0.08, 0.95)
const INK_MUTED: Color = Color(0.32, 0.28, 0.24, 0.55)
const PARCHMENT: Color = Color(0.92, 0.88, 0.79, 0.9)

var _grenades: int = 0
var _mines: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(220, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_counts(grenades: int, mines: int) -> void:
	_grenades = grenades
	_mines = mines
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, PARCHMENT)
	draw_rect(rect, INK, false, 2.0)
	draw_rect(rect.grow(-2.0), INK_MUTED, false, 1.0)

	var y: float = size.y * 0.5
	var x: float = 8.0

	# Grenade icon + count + hint
	var g_col: Color = INK if _grenades > 0 else INK_MUTED
	_draw_grenade(Vector2(x + 10, y), g_col)
	draw_string(get_theme_default_font(), Vector2(x + 24, y + 4), "%d  [G]" % _grenades, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, g_col)

	# Mine icon + count + hint
	var mx: float = size.x * 0.55
	var m_col: Color = INK if _mines > 0 else INK_MUTED
	_draw_mine(Vector2(mx + 10, y), m_col)
	draw_string(get_theme_default_font(), Vector2(mx + 24, y + 4), "%d  [F]" % _mines, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, m_col)


func _draw_grenade(center: Vector2, col: Color) -> void:
	# Simple oval body + pin.
	draw_circle(center, 6.0, col)
	draw_rect(Rect2(center + Vector2(-3, -10), Vector2(6, 4)), col)
	draw_line(center + Vector2(2, -10), center + Vector2(8, -12), col, 1.4)


func _draw_mine(center: Vector2, col: Color) -> void:
	# Disc with small spikes.
	draw_circle(center, 6.0, col)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2.RIGHT.rotated(a)
		draw_line(center + dir * 6.0, center + dir * 9.0, col, 1.6)
