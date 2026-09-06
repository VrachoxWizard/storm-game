extends Control

## Title screen with campaign start, difficulty selector, and unlocked mission select.

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var mission_list: VBoxContainer = $CenterContainer/VBoxContainer/MissionList
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

var _difficulty_option: OptionButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)
	_ensure_difficulty_selector()
	_rebuild_mission_buttons()


func _ensure_difficulty_selector() -> void:
	var vbox: VBoxContainer = $CenterContainer/VBoxContainer
	_difficulty_option = vbox.get_node_or_null("DifficultyOption") as OptionButton
	if _difficulty_option == null:
		var label := Label.new()
		label.name = "DifficultyLabel"
		label.text = "Difficulty"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		vbox.move_child(label, start_button.get_index())
		_difficulty_option = OptionButton.new()
		_difficulty_option.name = "DifficultyOption"
		_difficulty_option.custom_minimum_size = Vector2(280, 28)
		_difficulty_option.add_item("Easy", DifficultyManager.Difficulty.EASY)
		_difficulty_option.add_item("Normal", DifficultyManager.Difficulty.NORMAL)
		_difficulty_option.add_item("Hard", DifficultyManager.Difficulty.HARD)
		vbox.add_child(_difficulty_option)
		vbox.move_child(_difficulty_option, start_button.get_index())
	_select_current_difficulty()
	if not _difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		_difficulty_option.item_selected.connect(_on_difficulty_selected)


func _select_current_difficulty() -> void:
	var current: int = DifficultyManager.get_difficulty()
	for i in range(_difficulty_option.item_count):
		if _difficulty_option.get_item_id(i) == current:
			_difficulty_option.select(i)
			return
	_difficulty_option.select(1)


func _on_difficulty_selected(index: int) -> void:
	var d: int = _difficulty_option.get_item_id(index)
	DifficultyManager.set_difficulty(d as DifficultyManager.Difficulty)
	SoundManager.play_sfx("ui_click")


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
