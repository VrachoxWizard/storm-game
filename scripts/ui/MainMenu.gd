extends Control

## Title screen / main menu.

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)


func _on_start() -> void:
	GameManager.start_mission(0)


func _on_quit() -> void:
	get_tree().quit()
