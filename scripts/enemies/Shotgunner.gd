extends "res://scripts/enemies/EnemyBase.gd"

## Shotgunner enemy — rushes player, fires spread shot at close range.

@export var bullet_scene: PackedScene

const SHOTGUN_PELLETS: int = 5
const SHOTGUN_SPREAD: float = 0.4  ## radians


func _ready() -> void:
	super._ready()
	speed = 150.0  # faster than rifleman
	max_health = 35  # less health
	health = max_health
	attack_range = 80.0  # must be close
	attack_cooldown = 1.5
	damage = 8  # per pellet


func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return
	if bullet_scene == null:
		return

	var dir := (target.global_position - global_position).normalized()
	var base_angle := dir.angle()

	for i in range(SHOTGUN_PELLETS):
		var bullet: Area2D = bullet_scene.instantiate()
		get_tree().root.get_node("Main/Projectiles").add_child(bullet)

		var spread := randf_range(-SHOTGUN_SPREAD, SHOTGUN_SPREAD)
		bullet.activate(
			global_position,
			base_angle + spread,
			350.0,
			damage
		)
