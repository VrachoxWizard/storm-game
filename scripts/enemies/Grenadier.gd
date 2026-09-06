extends EnemyBase

## Grenadier — lobs grenades at player position with warning circle and recoil.

@export var grenade_scene: PackedScene
@export var lead_factor: float = 0.35


func _ready() -> void:
	unit_key = "grenadier"
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
	var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")
	if container:
		container.add_child(grenade)
	else:
		get_tree().root.add_child(grenade)
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var aim_pos: Vector2 = target.global_position
	if "velocity" in target:
		aim_pos += target.velocity * lead_factor
	var dir := aim_pos - global_position
	grenade.explosion_damage = damage
	grenade.throw_at(spawn_pos, dir, false)
	apply_recoil(5.0)


func has_clear_shot() -> bool:
	return is_instance_valid(target) and target.get("_is_dead") != true
