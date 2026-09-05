extends Area2D

## Interactable flag raise zone for Mission 5 victory.

signal flag_raised

@export var hold_time: float = 2.0

var _player_inside: bool = false
var _hold: float = 0.0
var _raised: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = false
			_hold = 0.0
	)


func _process(delta: float) -> void:
	if _raised:
		return
	if _player_inside:
		_hold += delta
		if _hold >= hold_time:
			_raised = true
			flag_raised.emit()
	else:
		_hold = 0.0
