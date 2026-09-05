extends Area2D

## Saves player state when entered. Used for respawn on death.

signal checkpoint_reached(checkpoint: Area2D)

var _activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if body.is_in_group("player"):
		_activated = true
		checkpoint_reached.emit(self)
