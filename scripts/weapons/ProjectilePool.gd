class_name ProjectilePool
extends Node2D

## Shared enemy/vehicle bullet pool under Main/Projectiles.

const ENEMY_POOL_SIZE: int = 80
const ENEMY_POOL_HARD_CAP: int = 120

var _enemy_pool: Array[Area2D] = []
var _enemy_scene: PackedScene = preload("res://scenes/weapons/EnemyProjectile.tscn")


func _ready() -> void:
	for i in range(ENEMY_POOL_SIZE):
		var bullet: Area2D = _enemy_scene.instantiate()
		add_child(bullet)
		if bullet.has_method("deactivate"):
			bullet.deactivate()
		_enemy_pool.append(bullet)


func acquire_enemy_bullet() -> Area2D:
	for b in _enemy_pool:
		if is_instance_valid(b) and b.has_method("is_pool_active") and not b.is_pool_active():
			return b
	if _enemy_pool.size() >= ENEMY_POOL_HARD_CAP:
		return null
	var extra: Area2D = _enemy_scene.instantiate()
	add_child(extra)
	_enemy_pool.append(extra)
	if extra.has_method("deactivate"):
		extra.deactivate()
	return extra


func spawn_enemy_bullet(pos: Vector2, rot: float, spd: float, dmg: int) -> Area2D:
	var bullet := acquire_enemy_bullet()
	if bullet and bullet.has_method("activate"):
		bullet.activate(pos, rot, spd, dmg)
	return bullet


static func get_pool(tree: SceneTree) -> ProjectilePool:
	if tree == null or tree.root == null:
		return null
	var node := tree.root.get_node_or_null("Main/Projectiles")
	if node is ProjectilePool:
		return node as ProjectilePool
	return null
