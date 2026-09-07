extends Node

## Singleton — manages game state, scene transitions, and mission flow.

signal mission_briefing_requested(mission_index: int)
signal mission_started(mission_index: int)
signal mission_completed(mission_index: int)
signal game_paused(is_paused: bool)

enum GameState { MENU, BRIEFING, PLAYING, PAUSED, RESULTS }

var current_state: GameState = GameState.MENU
var current_mission: int = 0
var _previous_state: GameState = GameState.MENU

const MISSION_SCENES: Array[String] = [
	"res://scenes/missions/Mission1.tscn",
	"res://scenes/missions/Mission2.tscn",
	"res://scenes/missions/Mission3.tscn",
	"res://scenes/missions/Mission4.tscn",
	"res://scenes/missions/Mission5.tscn",
]

const MISSION_NAMES: Array[String] = [
	"First Thunder",
	"Breaking the Line",
	"Open Road",
	"The Heart",
	"Victory",
]

## Authentic Oluja metadata aligned with MissionBriefings.
const MISSION_META: Array[Dictionary] = [
	{
		"date": "4. kolovoza 1995. — zora",
		"sector": "Lika / Gospić",
		"hv_unit": "9. gardijska brigada \"Vukovi\" / 4. gardijska brigada",
		"svk_unit": "15. lički korpus SVK",
	},
	{
		"date": "4.–5. kolovoza 1995.",
		"sector": "Lika fortified line — Medak axis",
		"hv_unit": "9. gardijska brigada \"Vukovi\"",
		"svk_unit": "15. lički korpus SVK",
	},
	{
		"date": "5. kolovoza 1995.",
		"sector": "Dalmatian approach — Sinj / Vrlika",
		"hv_unit": "HV armored spearhead",
		"svk_unit": "7. dalmatinski korpus SVK",
	},
	{
		"date": "5. kolovoza 1995. — poslijepodne",
		"sector": "Knin — streets",
		"hv_unit": "118. brigada HV / 9. gardijska brigada",
		"svk_unit": "Knindže special detachment",
	},
	{
		"date": "5. kolovoza 1995. — večer",
		"sector": "Knin Fortress",
		"hv_unit": "HV assault detachment",
		"svk_unit": "Final SVK fortress garrison",
	},
]


func get_mission_meta(mission_index: int) -> Dictionary:
	if mission_index >= 0 and mission_index < MISSION_META.size():
		return MISSION_META[mission_index]
	return {}


func _ready() -> void:
	_apply_mouse_mode()


## The OS cursor hides during gameplay (custom crosshair owns the screen),
## and returns for all menu/briefing/results states.
func _apply_mouse_mode() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if current_state == GameState.PLAYING else Input.MOUSE_MODE_VISIBLE


func start_mission(mission_index: int) -> void:
	current_mission = mission_index
	current_state = GameState.BRIEFING
	_apply_mouse_mode()
	ScoreManager.reset()
	mission_briefing_requested.emit(mission_index)


func begin_gameplay() -> void:
	current_state = GameState.PLAYING
	_apply_mouse_mode()
	mission_started.emit(current_mission)


func complete_mission() -> void:
	if current_state != GameState.PLAYING: return
	current_state = GameState.RESULTS
	_apply_mouse_mode()
	SaveManager.save_mission_score(
		current_mission,
		ScoreManager.get_total_score(),
		ScoreManager.get_rank(),
		ScoreManager.elapsed_time
	)
	mission_completed.emit(current_mission)


func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		_previous_state = current_state
		current_state = GameState.PAUSED
		get_tree().paused = true
		_apply_mouse_mode()
		game_paused.emit(true)
	elif current_state == GameState.PAUSED:
		current_state = _previous_state
		get_tree().paused = false
		_apply_mouse_mode()
		game_paused.emit(false)


func return_to_menu() -> void:
	get_tree().paused = false
	current_state = GameState.MENU
	_apply_mouse_mode()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
