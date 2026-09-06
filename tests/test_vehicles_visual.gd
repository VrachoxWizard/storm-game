extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Dummy audio playback is not part of these rendering/structure checks.
	root.get_node("SoundManager")._sfx.clear()
	# 1. Initialize DecalManager and CombatVfx in tree
	var decal_script = load("res://scripts/effects/DecalManager.gd")
	if decal_script == null:
		print("FAIL: DecalManager.gd not found")
		quit(1)
		return
	var dm = Node2D.new()
	dm.set_script(decal_script)
	root.add_child(dm)

	var vfx_script = load("res://scripts/effects/CombatVfx.gd")
	if vfx_script:
		var vfx = Node2D.new()
		vfx.set_script(vfx_script)
		root.add_child(vfx)

	# 2. Instantiate APC and Tank
	var apc_scene = load("res://scenes/vehicles/Apc.tscn")
	if apc_scene == null:
		print("FAIL: Apc.tscn not found")
		quit(1)
		return
	var apc = apc_scene.instantiate()
	root.add_child(apc)

	var tank_scene = load("res://scenes/vehicles/Tank.tscn")
	if tank_scene == null:
		print("FAIL: Tank.tscn not found")
		quit(1)
		return
	var tank = tank_scene.instantiate()
	root.add_child(tank)

	# 3. Verify independent Turret nodes and MuzzleMarkers
	if not apc.has_node("Turret") or not tank.has_node("Turret"):
		print("FAIL: Vehicles missing independent Turret node")
		quit(1)
		return

	if not apc.get_node("Turret").has_node("MuzzleMarker") or not tank.get_node("Turret").has_node("MuzzleMarker"):
		print("FAIL: Vehicles missing MuzzleMarker on Turret")
		quit(1)
		return

	# 4. Verify dust particles
	if not apc.has_node("DustParticles") or not tank.has_node("DustParticles"):
		print("FAIL: Vehicles missing DustParticles node")
		quit(1)
		return

	# 5. Verify Tank engine louvers rear weak point
	if not tank.has_node("EngineWeakPoint"):
		print("FAIL: Tank missing EngineWeakPoint node at rear")
		quit(1)
		return

	# Test direct rear weak point 3x damage multiplier
	var initial_tank_hp: int = tank.health
	tank.take_rear_damage(20) # 20 * 3 = 60 damage
	var hp_loss: int = initial_tank_hp - tank.health
	if hp_loss != 60:
		print("FAIL: Tank take_rear_damage expected 60 damage, got %d" % hp_loss)
		quit(1)
		return

	# Test standard body hit (1x damage)
	var hp_before_body: int = tank.health
	tank.take_damage(20) # 20 >= armor_threshold (18), standard damage = 20
	var body_loss: int = hp_before_body - tank.health
	if body_loss != 20:
		print("FAIL: Tank body hit expected 1x (20 damage), got %d" % body_loss)
		quit(1)
		return

	# Test weak point Area2D trigger: 3x damage (60) and deactivates bullet (prevents duplicate body hit 6x damage)
	var bullet_scene := load("res://scenes/weapons/Projectile.tscn")
	var dummy_bullet: Area2D = bullet_scene.instantiate()
	root.add_child(dummy_bullet)
	dummy_bullet.activate(tank.global_position + Vector2(-54, 0), 0.0, 400.0, 20)

	var hp_before_weak_point: int = tank.health
	tank._on_weak_point_area_entered(dummy_bullet)
	var weak_point_loss: int = hp_before_weak_point - tank.health
	if weak_point_loss != 60:
		print("FAIL: Weak point Area2D expected 3x (60 damage), got %d" % weak_point_loss)
		quit(1)
		return

	if dummy_bullet.get("_active") == true:
		print("FAIL: Bullet not deactivated when hitting weak point Area2D")
		quit(1)
		return

	dummy_bullet.queue_free()

	# 6. Verify destroy_vehicle method presence
	if not apc.has_method("destroy_vehicle") or not tank.has_method("destroy_vehicle"):
		print("FAIL: VehicleBase destroy_vehicle missing")
		quit(1)
		return

	# 7. Test continuous tread decal stamping during traversal (>20px)
	var decals_before: int = dm.get_decal_count()
	apc.global_position += Vector2(25.0, 0.0)
	apc._physics_process(0.1)
	var decals_after_apc: int = dm.get_decal_count()
	if decals_after_apc <= decals_before:
		print("FAIL: APC did not stamp tread decal when moving >20px")
		quit(1)
		return

	tank.global_position += Vector2(25.0, 0.0)
	tank._physics_process(0.1)
	var decals_after_tank: int = dm.get_decal_count()
	if decals_after_tank <= decals_after_apc:
		print("FAIL: Tank did not stamp tread decal when moving >20px")
		quit(1)
		return

	# 8. Test destruction states: hull texture swap, turret offset, collision disabled
	var apc_wreck_tex = load("res://assets/sprites/vehicles/apc_wreck.png")
	apc.destroy_vehicle()
	await process_frame
	if not apc.is_destroyed:
		print("FAIL: APC is_destroyed flag not set")
		quit(1)
		return
	if apc.sprite.texture != apc_wreck_tex:
		print("FAIL: APC hull texture not swapped to apc_wreck.png")
		quit(1)
		return
	var apc_col: CollisionShape2D = apc.get_node("CollisionShape2D")
	if not apc_col.disabled:
		print("FAIL: APC collision shape not disabled after destruction")
		quit(1)
		return

	var tank_wreck_tex = load("res://assets/sprites/vehicles/tank_wreck.png")
	tank.destroy_vehicle()
	await process_frame
	if not tank.is_destroyed:
		print("FAIL: Tank is_destroyed flag not set")
		quit(1)
		return
	if tank.sprite.texture != tank_wreck_tex:
		print("FAIL: Tank hull texture not swapped to tank_wreck.png")
		quit(1)
		return
	var tank_col: CollisionShape2D = tank.get_node("CollisionShape2D")
	if not tank_col.disabled:
		print("FAIL: Tank collision shape not disabled after destruction")
		quit(1)
		return

	print("PASS: Vehicle visual architecture verified")
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
