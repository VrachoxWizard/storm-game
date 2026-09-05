extends Control

## Title screen with campaign start and unlocked mission select.

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var mission_list: VBoxContainer = $CenterContainer/VBoxContainer/MissionList
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)
	_rebuild_mission_buttons()


func _rebuild_mission_buttons() -> void:
	for child in mission_list.get_children():
		child.queue_free()
	for i in range(GameManager.MISSION_NAMES.size()):
		var btn := Button.new()
		var unlocked: bool = SaveManager.is_mission_unlocked(i)
		btn.text = "M%d: %s" % [i + 1, GameManager.MISSION_NAMES[i]]
		btn.custom_minimum_size = Vector2(280, 28)
		btn.disabled = not unlocked
		if unlocked:
			var idx := i
			btn.pressed.connect(func() -> void:
				SoundManager.play_sfx("ui_click")
				GameManager.start_mission(idx)
			)
		mission_list.add_child(btn)


func _on_start() -> void:
	SoundManager.play_sfx("ui_click")
	GameManager.start_mission(0)


func _on_quit() -> void:
	SoundManager.play_sfx("ui_click")
	get_tree().quit()
