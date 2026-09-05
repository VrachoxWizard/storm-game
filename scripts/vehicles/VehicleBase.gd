class_name VehicleBase
extends CharacterBody2D

## Base class for armored vehicles (APC, Tank). Layer 7.

signal destroyed
signal died

@export var max_health: int = 300
@export var armor_threshold: int = 12  ## Damage below this is heavily reduced
@export var speed: float = 60.0
@export var detection_range: float = 400.0

var health: int = 300
var target: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer


func _ready() -> void:
	health = max_health
	add_to_group("vehicle")
	collision_layer = 64
	collision_mask = 33  # Player + Environment
	detection_area.body_entered.connect(_on_detect_entered)
	detection_area.body_exited.connect(_on_detect_exited)
	attack_timer.timeout.connect(_on_attack_timeout)
	attack_timer.one_shot = true


func _physics_process(delta: float) -> void:
	_vehicle_ai(delta)


func _vehicle_ai(_delta: float) -> void:
	pass


func take_damage(amount: int) -> void:
	var final_amount: int = amount
	if amount < armor_threshold:
		final_amount = maxi(1, int(float(amount) * 0.2))
	health -= final_amount
	_flash_hit()
	if health <= 0:
		_die()


func take_rear_damage(amount: int) -> void:
	## Weak-point damage (used by Tank).
	take_damage(amount * 3)


func _die() -> void:
	destroyed.emit()
	died.emit()
	ScoreManager.record_vehicle_destroyed()
	queue_free()


func _flash_hit() -> void:
	sprite.modulate = Color.ORANGE
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
	)


func _on_detect_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body


func _on_detect_exited(body: Node2D) -> void:
	if body == target:
		target = null


func _on_attack_timeout() -> void:
	_perform_attack()


func _perform_attack() -> void:
	pass


func _start_attack_cooldown(wait: float) -> void:
	attack_timer.wait_time = wait
	attack_timer.start()
