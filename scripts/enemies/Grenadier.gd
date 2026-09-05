extends EnemyBase

## Grenadier — lobs grenades at player position with warning circle.

@export var grenade_scene: PackedScene


func _ready() -> void:
	super._ready()
	max_health = 55
	health = max_health
	speed = 85.0
	attack_range = 260.0
	detection_range = 300.0
	damage = 45
	attack_cooldown = 2.5


func _perform_attack() -> void:
	if grenade_scene == null or target == null:
		return
	var grenade: Area2D = grenade_scene.instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(grenade)
	var dir := (target.global_position - global_position)
	grenade.explosion_damage = damage
	grenade.throw_at(global_position, dir, false)
