class_name WaveSpawner
extends Node2D

## Spawns a wave of enemies at child Marker2D positions when triggered.

signal wave_spawned
signal wave_cleared

@export var enemy_scenes: Array[PackedScene] = []
@export var counts: Array[int] = []
@export var auto_trigger: bool = false
@export var trigger_once: bool = true

var _spawned: int = 0
var _alive: int = 0
var _triggered: bool = false
var _container: Node2D


func _ready() -> void:
	_container = get_parent() as Node2D
	if auto_trigger:
		call_deferred("trigger")


func trigger() -> void:
	if trigger_once and _triggered:
		return
	_triggered = true
	var markers: Array = []
	for child in get_children():
		if child is Marker2D or child is Node2D:
			markers.append(child)
	if markers.is_empty():
		markers.append(self)

	var spawn_index: int = 0
	for i in range(enemy_scenes.size()):
		var scene: PackedScene = enemy_scenes[i]
		var count: int = counts[i] if i < counts.size() else 1
		if scene == null:
			continue
		for j in range(count):
			var marker: Node2D = markers[spawn_index % markers.size()]
			var enemy := MissionHelpers.spawn_enemy_at(scene, _container, marker.global_position, _on_enemy_died)
			if enemy:
				_alive += 1
				_spawned += 1
			spawn_index += 1
	wave_spawned.emit()
	if _alive <= 0:
		wave_cleared.emit()


func _on_enemy_died(_e = null) -> void:
	_alive = maxi(_alive - 1, 0)
	if _alive <= 0:
		wave_cleared.emit()
