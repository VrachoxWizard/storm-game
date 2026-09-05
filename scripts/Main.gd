extends Node

## Root scene — coordinates game flow between menu, briefing, gameplay, and results.

@onready var main_menu: Control = $MainMenu
@onready var briefing_screen: Control = $BriefingScreen
@onready var results_screen: Control = $ResultsScreen
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var world_container: Node2D = $WorldContainer

var _current_world: Node2D = null


func _ready() -> void:
	GameManager.mission_started.connect(_on_mission_started)
	GameManager.mission_completed.connect(_on_mission_completed)
	_show_main_menu()


func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.BRIEFING and briefing_screen and not briefing_screen.visible:
		main_menu.visible = false
		briefing_screen.show_briefing(GameManager.current_mission)


func _show_main_menu() -> void:
	main_menu.visible = true
	briefing_screen.visible = false
	results_screen.visible = false
	hud.visible = false

	if _current_world:
		_current_world.queue_free()
		_current_world = null

	if not GameManager.is_connected("mission_started", _on_mission_started):
		GameManager.mission_started.connect(_on_mission_started)


func _on_game_state_changed() -> void:
	match GameManager.current_state:
		GameManager.GameState.BRIEFING:
			main_menu.visible = false
			briefing_screen.show_briefing(GameManager.current_mission)


func _on_mission_started(_mission_index: int) -> void:
	briefing_screen.visible = false
	hud.visible = true

	# Load mission scene
	var scene_path: String = GameManager.MISSION_SCENES[GameManager.current_mission]
	var mission_scene: PackedScene = load(scene_path)
	_current_world = mission_scene.instantiate()
	world_container.add_child(_current_world)

	# Setup HUD with player
	var player: CharacterBody2D = _current_world.get_node("Player")
	hud.setup(player)
	ScoreManager.start_tracking()


func _on_mission_completed(_mission_index: int) -> void:
	ScoreManager.stop_tracking()
	hud.visible = false
	results_screen.show_results()
