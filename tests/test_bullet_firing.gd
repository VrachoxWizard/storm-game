# tests/test_bullet_firing.gd
extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Dummy audio playback is not part of these rendering/structure checks.
	root.get_node("SoundManager")._sfx.clear()
	print("=== Testing Player Bullet Firing & Damage Pipeline ===")

	var player_scene = load("res://scenes/player/Player.tscn")
	if player_scene == null:
		print("FAIL: Could not load Player.tscn")
		quit(1)
		return

	var main_node = Node.new()
	main_node.name = "Main"
	root.add_child(main_node)

	var proj_node = Node2D.new()
	proj_node.name = "Projectiles"
	main_node.add_child(proj_node)

	var player = player_scene.instantiate()
	main_node.add_child(player)

	# Verify projectile pool initialized
	if player._projectile_pool.size() == 0:
		print("FAIL: Player projectile pool is empty")
		quit(1)
		return
	print("Projectile pool initialized with %d bullets" % player._projectile_pool.size())

	# Ensure player has weapon manager and weapon
	var wm = player.weapon_manager
	if wm == null or wm.get_current_weapon() == null:
		print("FAIL: Player missing WeaponManager or default weapon")
		quit(1)
		return

	var weapon = wm.get_current_weapon()
	print("Default weapon: %s (dmg: %d, speed: %f)" % [weapon.weapon_name, weapon.damage, weapon.bullet_speed])

	# Fire the weapon
	player._on_weapon_fired()

	# Find the activated bullet
	var fired_bullet = null
	for b in player._projectile_pool:
		if b.visible and b._active:
			fired_bullet = b
			break

	if fired_bullet == null:
		print("FAIL: No bullet was activated in projectile pool upon weapon fire!")
		quit(1)
		return

	print("PASS: Bullet successfully activated at %s with rotation %f" % [fired_bullet.global_position, fired_bullet.global_rotation])

	# Verify bullet properties
	if fired_bullet.damage != weapon.damage:
		print("FAIL: Bullet damage mismatch (expected %d, got %d)" % [weapon.damage, fired_bullet.damage])
		quit(1)
		return

	if fired_bullet.speed != weapon.bullet_speed:
		print("FAIL: Bullet speed mismatch (expected %f, got %f)" % [weapon.bullet_speed, fired_bullet.speed])
		quit(1)
		return

	if fired_bullet.z_index != 2:
		print("FAIL: Bullet z_index expected 2, got %d" % fired_bullet.z_index)
		quit(1)
		return

	# Simulate 1 physics tick: verify movement
	var initial_pos = fired_bullet.global_position
	var dt: float = 0.05
	fired_bullet._physics_process(dt)
	var distance_moved = initial_pos.distance_to(fired_bullet.global_position)
	var expected_distance = fired_bullet.speed * dt
	if absf(distance_moved - expected_distance) > 1.0:
		print("FAIL: Bullet movement incorrect (moved %f, expected %f)" % [distance_moved, expected_distance])
		quit(1)
		return
	print("PASS: Bullet traveled %f pixels in %fs" % [distance_moved, dt])

	# Simulate hitting an enemy
	var dummy = DummyEnemy.new()
	root.add_child(dummy)
	fired_bullet._on_body_entered(dummy)

	if dummy.health != (100 - weapon.damage):
		print("FAIL: Enemy did not take damage from bullet (expected %d, got %d)" % [100 - weapon.damage, dummy.health])
		quit(1)
		return
	print("PASS: Enemy took %d damage, remaining health: %d" % [weapon.damage, dummy.health])

	if fired_bullet._active or fired_bullet.visible:
		print("FAIL: Bullet did not deactivate after hitting target")
		quit(1)
		return
	print("PASS: Bullet correctly deactivated on impact")

	# Clean up
	dummy.queue_free()
	player.queue_free()

	print("=== Bullet Firing & Damage Pipeline Fully Verified! ===")
	for audio in root.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	for child in root.get_children():
		if child.name not in ["GameManager", "ScoreManager", "SaveManager", "SoundManager"]:
			child.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	call_deferred("quit", 0)


class DummyEnemy extends CharacterBody2D:
	var health: int = 100
	func take_damage(dmg: int) -> void:
		health -= dmg
