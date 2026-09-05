extends Node

## Singleton — manages game state, scene transitions, and mission flow.

signal mission_started(mission_index: int)
signal mission_completed(mission_index: int)
signal game_paused(is_paused: bool)

enum GameState { MENU, BRIEFING, PLAYING, PAUSED, RESULTS }

var current_state: GameState = GameState.MENU
var current_mission: int = 0
var _previous_state: GameState = GameState.MENU

const MISSION_SCENES: Array[String] = [
	"res://scenes/missions/Mission1.tscn",
]


func start_mission(mission_index: int) -> void:
	current_mission = mission_index
	current_state = GameState.BRIEFING
	ScoreManager.reset()


func begin_gameplay() -> void:
	current_state = GameState.PLAYING
	mission_started.emit(current_mission)


func complete_mission() -> void:
	current_state = GameState.RESULTS
	mission_completed.emit(current_mission)
	SaveManager.save_mission_score(
		current_mission,
		ScoreManager.get_total_score(),
		ScoreManager.get_rank(),
		ScoreManager.elapsed_time
	)


func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		_previous_state = current_state
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit(true)
	elif current_state == GameState.PAUSED:
		current_state = _previous_state
		get_tree().paused = false
		game_paused.emit(false)


func return_to_menu() -> void:
	get_tree().paused = false
	current_state = GameState.MENU
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
