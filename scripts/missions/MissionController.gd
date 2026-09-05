extends Node

## Controls Mission 1 wave spawning, checkpoints, and objective tracking.

@export var rifleman_scene: PackedScene
@export var shotgunner_scene: PackedScene

var _wave: int = 0
var _enemies_alive: int = 0
var _mission_complete: bool = false

const WAVES: Array[Dictionary] = [
	{"riflemen": 5, "shotgunners": 0},
	{"riflemen": 6, "shotgunners": 2},
	{"riflemen": 8, "shotgunners": 4},
]

@onready var enemies_container: Node2D = $"../Enemies"
@onready var spawn_markers: Node2D = $"../SpawnMarkers"


func _ready() -> void:
	_start_wave(0)


func _start_wave(wave_index: int) -> void:
	if wave_index >= WAVES.size():
		_complete_mission()
		return

	_wave = wave_index
	var wave_data: Dictionary = WAVES[wave_index]
	_enemies_alive = wave_data["riflemen"] + wave_data["shotgunners"]

	var spawn_points := spawn_markers.get_children()
	var spawn_index: int = 0

	for i in range(wave_data["riflemen"]):
		var enemy := rifleman_scene.instantiate()
		enemy.global_position = spawn_points[spawn_index % spawn_points.size()].global_position
		enemy.enemy_died.connect(_on_enemy_died)
		enemies_container.add_child(enemy)
		spawn_index += 1

	for i in range(wave_data["shotgunners"]):
		var enemy := shotgunner_scene.instantiate()
		enemy.global_position = spawn_points[spawn_index % spawn_points.size()].global_position
		enemy.enemy_died.connect(_on_enemy_died)
		enemies_container.add_child(enemy)
		spawn_index += 1


func _on_enemy_died(_enemy: CharacterBody2D) -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		# Brief pause then next wave
		get_tree().create_timer(2.0).timeout.connect(
			func() -> void: _start_wave(_wave + 1)
		)


func _complete_mission() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	GameManager.complete_mission()
