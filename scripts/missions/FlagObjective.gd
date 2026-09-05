extends Area2D

## Interactable flag raise zone for Mission 5 victory.

signal flag_raised

@export var hold_time: float = 2.0

var _player_inside: bool = false
var _hold: float = 0.0
var _raised: bool = false
var _progress_bar: ProgressBar


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(64, 8)
	_progress_bar.max_value = hold_time
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	_progress_bar.position = Vector2(-32, -40)
	add_child(_progress_bar)
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = true
			_progress_bar.visible = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = false
			_hold = 0.0
			_progress_bar.value = 0.0
			_progress_bar.visible = false
	)


func _process(delta: float) -> void:
	if _raised:
		return
	if _player_inside:
		_hold += delta
		_progress_bar.value = _hold
		if _hold >= hold_time:
			_raised = true
			_progress_bar.visible = false
			flag_raised.emit()
	else:
		_hold = 0.0
