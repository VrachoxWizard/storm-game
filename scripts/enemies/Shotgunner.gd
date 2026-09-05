extends EnemyBase

## Shotgunner enemy — rushes player, fires spread shot with recoil and muzzle flash.

@export var bullet_scene: PackedScene

const SHOTGUN_PELLETS: int = 5
const SHOTGUN_SPREAD: float = 0.4


func _ready() -> void:
	super._ready()
	speed = 150.0
	max_health = 35
	health = max_health
	attack_range = 80.0
	attack_cooldown = 1.5
	damage = 8


func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return
	if bullet_scene == null:
		return

	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var dir := (target.global_position - spawn_pos).normalized()
	var base_angle := dir.angle()

	var container: Node = get_tree().root.get_node_or_null("Main/Projectiles")

	for i in range(SHOTGUN_PELLETS):
		var bullet: Area2D = bullet_scene.instantiate()
		if container:
			container.add_child(bullet)
		else:
			get_tree().root.add_child(bullet)

		var spread := randf_range(-SHOTGUN_SPREAD, SHOTGUN_SPREAD)
		bullet.activate(spawn_pos, base_angle + spread, 350.0, damage)

	apply_recoil(6.0)
	var flash_rot := torso_container.rotation if torso_container else base_angle
	CombatVfxScript.vfx_muzzle_flash(spawn_pos, flash_rot, "shotgun")
