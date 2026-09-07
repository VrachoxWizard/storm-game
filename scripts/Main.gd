extends Node

## Root scene — coordinates game flow between menu, briefing, gameplay, and results.

@onready var main_menu: Control = $MainMenu
@onready var briefing_screen: CanvasLayer = $BriefingScreen
@onready var results_screen: CanvasLayer = $ResultsScreen
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var world_container: Node2D = $WorldContainer
@onready var projectiles: Node2D = $Projectiles

var _current_world: Node2D = null


func _ready() -> void:
	GameManager.mission_briefing_requested.connect(_on_mission_briefing_requested)
	GameManager.mission_started.connect(_on_mission_started)
	GameManager.mission_completed.connect(_on_mission_completed)
	_show_main_menu()


func _show_main_menu() -> void:
	main_menu.visible = true
	briefing_screen.visible = false
	results_screen.visible = false
	hud.visible = false

	_teardown_world()
	SoundManager.play_music("title")


func _cleanup_projectiles() -> void:
	if projectiles == null:
		return
	var enemy_pool: Array = []
	if projectiles is ProjectilePool:
		enemy_pool = (projectiles as ProjectilePool)._enemy_pool
	for child in projectiles.get_children():
		if child in enemy_pool:
			if child.has_method("deactivate"):
				child.deactivate()
		else:
			child.queue_free()


func _cleanup_combat_fx() -> void:
	DecalManager.clear_decals()
	var vfx := get_node_or_null("CombatVfx")
	if vfx:
		for child in vfx.get_children():
			child.queue_free()


func _teardown_world() -> void:
	if _current_world:
		_current_world.queue_free()
		_current_world = null
	_cleanup_projectiles()
	_cleanup_combat_fx()


func _on_mission_briefing_requested(mission_index: int) -> void:
	main_menu.visible = false
	if _current_world:
		_current_world.process_mode = Node.PROCESS_MODE_DISABLED
		_current_world.visible = false
	if briefing_screen.has_method("show_briefing"):
		briefing_screen.call("show_briefing", mission_index)
	else:
		push_error("BriefingScreen missing show_briefing(); starting gameplay directly.")
		GameManager.begin_gameplay()


func _on_mission_started(_mission_index: int) -> void:
	briefing_screen.visible = false
	results_screen.visible = false
	projectiles.process_mode = Node.PROCESS_MODE_INHERIT
	hud.visible = true

	_teardown_world()

	# Load mission scene
	var scene_path: String = GameManager.MISSION_SCENES[GameManager.current_mission]
	var mission_scene: PackedScene = load(scene_path)
	_current_world = mission_scene.instantiate()
	world_container.add_child(_current_world)

	# Setup HUD with player
	var player: CharacterBody2D = _current_world.get_node("Player")
	hud.setup(player)
	ScoreManager.start_tracking()
	SoundManager.play_music("tension", 0.8)
	# Swell into combat shortly after start
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		SoundManager.play_music("combat", 1.5)
	)


func _on_mission_completed(_mission_index: int) -> void:
	ScoreManager.stop_tracking()
	projectiles.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	if _current_world:
		_current_world.process_mode = Node.PROCESS_MODE_DISABLED
		_current_world.visible = false
	# region agent log
	_agent_dbg_main_results()
	# endregion
	results_screen.show_results()


# region agent log
const _AGENT_LOG_PATH := "C:/Users/user1/OneDrive/Desktop/Moji Osobni projekti/2d-arcade-shooter-desktop/debug-951e11.log"


func _agent_dbg_main_results() -> void:
	var world_visible := _current_world != null and is_instance_valid(_current_world)
	var world_shown := false
	var cam_active := false
	if world_visible:
		world_shown = _current_world.visible
		var cam := _current_world.get_node_or_null("Player/Camera2D")
		if cam == null:
			cam = _current_world.find_child("Camera2D", true, false)
		cam_active = cam != null and cam is Camera2D and (cam as Camera2D).is_current()
	var payload := {
		"sessionId": "951e11",
		"runId": "post-fix",
		"hypothesisId": "C",
		"location": "Main.gd:_on_mission_completed",
		"message": "world_state_at_results",
		"data": {
			"world_present": world_visible,
			"world_process_mode": _current_world.process_mode if world_visible else -1,
			"world_visible_flag": world_shown,
			"camera_current": cam_active,
			"results_is_canvas_layer": results_screen is CanvasLayer,
			"results_layer": results_screen.layer if results_screen is CanvasLayer else -1,
			"results_visible_before": results_screen.visible,
			"hud_visible": hud.visible,
		},
		"timestamp": Time.get_ticks_msec(),
	}
	var f: FileAccess
	if FileAccess.file_exists(_AGENT_LOG_PATH):
		f = FileAccess.open(_AGENT_LOG_PATH, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(_AGENT_LOG_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("agent dbg log open failed: %s" % FileAccess.get_open_error())
		return
	f.store_line(JSON.stringify(payload))
	f.close()
	print("[agent-dbg] C world_state_at_results")
# endregion
