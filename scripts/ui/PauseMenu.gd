extends CanvasLayer

## Pause menu overlay with volume sliders and screen-shake toggle.

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var music_slider: HSlider = $CenterContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $CenterContainer/VBoxContainer/SfxSlider
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var shake_check: CheckButton = $CenterContainer/VBoxContainer/ShakeCheck


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused


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
