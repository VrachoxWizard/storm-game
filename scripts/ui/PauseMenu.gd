extends CanvasLayer

## Pause menu overlay with volume sliders, screen-shake toggle, and difficulty.

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var music_slider: HSlider = $CenterContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $CenterContainer/VBoxContainer/SfxSlider
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var shake_check: CheckButton = $CenterContainer/VBoxContainer/ShakeCheck

var _difficulty_option: OptionButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	shake_check.toggled.connect(_on_shake_toggled)
	visible = false
	GameManager.game_paused.connect(_on_game_paused)
	var settings: Dictionary = SaveManager.data.get("settings", {})
	music_slider.value = float(settings.get("music_volume", 0.8))
	sfx_slider.value = float(settings.get("sfx_volume", 1.0))
	shake_check.button_pressed = bool(settings.get("screen_shake", true))
	_ensure_difficulty_selector()


func _ensure_difficulty_selector() -> void:
	var vbox: VBoxContainer = $CenterContainer/VBoxContainer
	_difficulty_option = vbox.get_node_or_null("DifficultyOption") as OptionButton
	if _difficulty_option == null:
		var note := Label.new()
		note.name = "DifficultyNote"
		note.text = "Difficulty (applies on next mission / respawn)"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size", 12)
		vbox.add_child(note)
		vbox.move_child(note, shake_check.get_index() + 1)
		_difficulty_option = OptionButton.new()
		_difficulty_option.name = "DifficultyOption"
		_difficulty_option.custom_minimum_size = Vector2(200, 28)
		_difficulty_option.add_item("Easy", DifficultyManager.Difficulty.EASY)
		_difficulty_option.add_item("Normal", DifficultyManager.Difficulty.NORMAL)
		_difficulty_option.add_item("Hard", DifficultyManager.Difficulty.HARD)
		vbox.add_child(_difficulty_option)
		vbox.move_child(_difficulty_option, note.get_index() + 1)
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		_select_current_difficulty()


func _on_resume() -> void:
	SoundManager.play_sfx("ui_click")
	SaveManager.save_data()
	GameManager.toggle_pause()


func _on_quit() -> void:
	SoundManager.play_sfx("ui_click")
	SaveManager.save_data()
	GameManager.return_to_menu()


func _on_music_changed(value: float) -> void:
	SoundManager.set_music_volume(value)
	SaveManager.save_data()


func _on_sfx_changed(value: float) -> void:
	SoundManager.set_sfx_volume(value)
	SaveManager.save_data()


func _on_shake_toggled(pressed: bool) -> void:
	SaveManager.data["settings"]["screen_shake"] = pressed
	SaveManager.save_data()
