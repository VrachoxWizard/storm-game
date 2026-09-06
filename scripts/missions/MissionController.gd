extends Node

## Three authored assaults with flanking routes and breathing room between waves.
@export var rifleman_scene: PackedScene
@export var shotgunner_scene: PackedScene
var _wave: int = 0
var _enemies_alive: int = 0
var _mission_complete: bool = false
var _pending_spawns: int = 0
var _wave_transition: bool = false
const WAVES: Array[Dictionary] = [
	{"label": "East approach — SVK 15th Lika rifle patrol", "riflemen": 5, "shotgunners": 0, "routes": [0, 1, 2]},
	{"label": "South flank — SVK shotgun rush", "riflemen": 4, "shotgunners": 3, "routes": [2, 3, 4]},
	{"label": "Northern pincer — hold the Gospić depot", "riflemen": 6, "shotgunners": 4, "routes": [5, 6, 7, 0]},
]
@onready var enemies_container: Node2D = $"../Enemies"
@onready var spawn_markers: Node2D = $"../SpawnMarkers"
@onready var player: CharacterBody2D = $"../Player"

func _ready() -> void:
	MissionHelpers.connect_checkpoints(get_parent(), player)
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	_start_wave(0)

func _start_wave(index: int) -> void:
	if index >= WAVES.size():
		_complete_mission()
		return
	_wave = index
	_wave_transition = false
	var data: Dictionary = WAVES[index]
	_pending_spawns = int(data["riflemen"]) + int(data["shotgunners"])
	_update_objective()
	# Stagger arrivals so soldiers never stack on a reused marker.
	for i in range(_pending_spawns):
		var scene: PackedScene = rifleman_scene if i < int(data["riflemen"]) else shotgunner_scene
		get_tree().create_timer(1.0 + float(i) * 0.65).timeout.connect(_spawn_attacker.bind(scene, i))

func _spawn_attacker(scene: PackedScene, index: int) -> void:
	var routes: Array = WAVES[_wave]["routes"]
	var marker: Node2D = spawn_markers.get_child(routes[index % routes.size()])
	var enemy := MissionHelpers.spawn_enemy_at(scene, enemies_container, marker.global_position, _on_enemy_died)
	_pending_spawns -= 1
	if enemy is EnemyBase:
		_enemies_alive += 1
		enemy.order_assault(player)
	_update_objective()

func _update_objective() -> void:
	MissionHelpers.set_hud_objective(get_tree(), "Wave %d/3: %s (%d remaining)" % [_wave + 1, WAVES[_wave]["label"], _enemies_alive + _pending_spawns])

func _on_enemy_died(_enemy: CharacterBody2D) -> void:
	_enemies_alive = maxi(0, _enemies_alive - 1)
	_update_objective()
	if _enemies_alive == 0 and _pending_spawns == 0 and not _wave_transition:
		_wave_transition = true
		player.save_checkpoint(player.global_position)
		MissionHelpers.notify_checkpoint(player)
		MissionHelpers.set_hud_objective(get_tree(), "HV position secure — regroup and reload")
		get_tree().create_timer(4.0).timeout.connect(func() -> void: _start_wave(_wave + 1))

func _complete_mission() -> void:
	if _mission_complete: return
	_mission_complete = true
	MissionHelpers.complete_mission(get_tree())
