extends CanvasLayer

## Pause menu overlay.

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)
	visible = false
	GameManager.game_paused.connect(_on_game_paused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused


func _on_resume() -> void:
	GameManager.toggle_pause()


func _on_quit() -> void:
	GameManager.return_to_menu()
