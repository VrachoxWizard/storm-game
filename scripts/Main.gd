extends Node

## Root scene — coordinates game flow between menu, briefing, gameplay, and results.

@onready var main_menu: Control = $MainMenu
@onready var briefing_screen: Control = $BriefingScreen
@onready var results_screen: Control = $ResultsScreen
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
	results_screen.show_results()
