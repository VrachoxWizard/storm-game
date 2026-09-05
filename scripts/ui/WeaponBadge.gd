class_name WeaponBadge
extends Control

## Inked weapon silhouette badge for HUD display.

@export var badge_width: float = 64.0
@export var badge_height: float = 28.0

var _weapon_name: String = "Zastava M70"

const INK_COLOR: Color = Color(0.12, 0.1, 0.08, 0.95)
const INK_MUTED: Color = Color(0.25, 0.22, 0.18, 0.6)
const PAPER_BG: Color = Color(0.92, 0.88, 0.79, 0.9)


func _ready() -> void:
	custom_minimum_size = Vector2(badge_width, badge_height)


func set_weapon(w_name: String) -> void:
	_weapon_name = w_name
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	# 1. Parchment badge background & double ink border
	draw_rect(rect, PAPER_BG)
	draw_rect(rect, INK_COLOR, false, 1.5)
	draw_rect(rect.grow(-2.0), INK_MUTED, false, 1.0)

	# 2. Draw Weapon Silhouette
	var w := _weapon_name.to_lower()
	var cy: float = size.y * 0.5
	var cx: float = size.x * 0.5

	if "shotgun" in w or "hawk" in w:
		_draw_shotgun(cx, cy)
	elif "pistol" in w or "php" in w:
		_draw_pistol(cx, cy)
	elif "smg" in w or "skorpion" in w:
		_draw_smg(cx, cy)
	elif "sniper" in w or "m48" in w or "mauser" in w:
		_draw_sniper(cx, cy)
	elif "rpg" in w or "rocket" in w:
		_draw_rpg(cx, cy)
	else:
		_draw_rifle(cx, cy)


func _draw_rifle(cx: float, cy: float) -> void:
	# M70 Assault Rifle silhouette
	draw_rect(Rect2(cx - 20, cy - 2, 38, 4), INK_COLOR) # Barrel & receiver
	draw_rect(Rect2(cx - 22, cy - 1, 4, 2), INK_COLOR)  # Muzzle
	draw_line(Vector2(cx + 14, cy - 3), Vector2(cx + 14, cy - 1), INK_COLOR, 1.5) # Front sight
	# Curved magazine
	var mag_pts: PackedVector2Array = [
		Vector2(cx + 2, cy + 2),
		Vector2(cx - 1, cy + 9),
		Vector2(cx - 4, cy + 8),
		Vector2(cx - 1, cy + 2)
	]
	draw_colored_polygon(mag_pts, INK_COLOR)
	# Pistol grip
	draw_line(Vector2(cx - 8, cy + 2), Vector2(cx - 12, cy + 8), INK_COLOR, 2.5)
	# Stock
	var stock_pts: PackedVector2Array = [
		Vector2(cx - 10, cy - 2),
		Vector2(cx - 22, cy - 1),
		Vector2(cx - 22, cy + 4),
		Vector2(cx - 12, cy + 2)
	]
	draw_colored_polygon(stock_pts, INK_COLOR)


func _draw_shotgun(cx: float, cy: float) -> void:
	# Hawk Shotgun silhouette
	draw_rect(Rect2(cx - 18, cy - 3, 36, 4), INK_COLOR) # Barrel & receiver
	draw_rect(Rect2(cx + 2, cy + 1, 10, 3), INK_COLOR)  # Pump forend
	# Stock & Grip
	var stock_pts: PackedVector2Array = [
		Vector2(cx - 8, cy - 3),
		Vector2(cx - 20, cy - 1),
		Vector2(cx - 20, cy + 5),
		Vector2(cx - 10, cy + 2)
	]
	draw_colored_polygon(stock_pts, INK_COLOR)


func _draw_pistol(cx: float, cy: float) -> void:
	# PHP Pistol silhouette
	draw_rect(Rect2(cx - 8, cy - 4, 18, 5), INK_COLOR) # Slide
	draw_line(Vector2(cx - 4, cy + 1), Vector2(cx - 8, cy + 8), INK_COLOR, 3.5) # Grip
	draw_line(Vector2(cx + 2, cy + 1), Vector2(cx - 1, cy + 4), INK_COLOR, 1.5) # Trigger guard


func _draw_smg(cx: float, cy: float) -> void:
	# Skorpion SMG silhouette
	draw_rect(Rect2(cx - 12, cy - 2, 24, 4), INK_COLOR) # Receiver & barrel
	draw_rect(Rect2(cx + 2, cy + 2, 3, 7), INK_COLOR)   # Vertical magazine
	draw_line(Vector2(cx - 6, cy + 2), Vector2(cx - 9, cy + 7), INK_COLOR, 2.5) # Grip
	draw_line(Vector2(cx - 12, cy - 2), Vector2(cx - 18, cy - 4), INK_COLOR, 1.5) # Wire stock


func _draw_sniper(cx: float, cy: float) -> void:
	# M48 Mauser / Scoped Rifle
	draw_rect(Rect2(cx - 22, cy - 1, 44, 3), INK_COLOR) # Long barrel & receiver
	# Telescopic scope on top
	draw_rect(Rect2(cx - 6, cy - 5, 14, 3), INK_COLOR)
	draw_line(Vector2(cx - 3, cy - 2), Vector2(cx - 3, cy - 1), INK_COLOR, 1.5)
	draw_line(Vector2(cx + 5, cy - 2), Vector2(cx + 5, cy - 1), INK_COLOR, 1.5)
	# Wooden stock
	var stock_pts: PackedVector2Array = [
		Vector2(cx - 10, cy - 1),
		Vector2(cx - 24, cy),
		Vector2(cx - 24, cy + 4),
		Vector2(cx - 12, cy + 2)
	]
	draw_colored_polygon(stock_pts, INK_COLOR)


func _draw_rpg(cx: float, cy: float) -> void:
	# RPG-7 Launcher
	draw_rect(Rect2(cx - 18, cy - 2, 36, 4), INK_COLOR) # Launch tube
	# Conical rocket warhead
	var warhead_pts: PackedVector2Array = [
		Vector2(cx + 18, cy - 2),
		Vector2(cx + 25, cy),
		Vector2(cx + 18, cy + 2)
	]
	draw_colored_polygon(warhead_pts, INK_COLOR)
	draw_line(Vector2(cx - 4, cy + 2), Vector2(cx - 6, cy + 7), INK_COLOR, 2.5) # Grip
