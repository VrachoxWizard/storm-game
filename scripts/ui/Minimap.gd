extends Control

## Top-right radar showing player, enemies, vehicles, objectives.

@export var radar_range: float = 600.0
@export var radar_size: float = 120.0

var _player: Node2D = null


func _ready() -> void:
	custom_minimum_size = Vector2(radar_size, radar_size)
	size = Vector2(radar_size, radar_size)


func setup(player: Node2D) -> void:
	_player = player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radar_size * 0.5, Color(0.1, 0.12, 0.1, 0.55))
	draw_arc(center, radar_size * 0.5, 0, TAU, 32, Color(0.7, 0.7, 0.5, 0.8), 1.5)
	draw_circle(center, 3.0, Color.WHITE)
	if _player == null or not is_instance_valid(_player):
		return
	_draw_group("enemies", Color(0.9, 0.15, 0.15), center)
	_draw_group("vehicle", Color(0.95, 0.5, 0.1), center)
	_draw_group("emplacement", Color(0.8, 0.2, 0.8), center)
	_draw_group("bunker", Color(0.8, 0.2, 0.8), center)


func _draw_group(group: String, color: Color, center: Vector2) -> void:
	for node in get_tree().get_nodes_in_group(group):
		if node == _player or not (node is Node2D):
			continue
		var offset: Vector2 = (node as Node2D).global_position - _player.global_position
		if offset.length() > radar_range:
			continue
		var mapped: Vector2 = center + offset / radar_range * (radar_size * 0.45)
		draw_circle(mapped, 2.5, color)
