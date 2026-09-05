extends SceneTree

func _init() -> void:
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

	# Test rear weak point 3x damage multiplier
	var initial_tank_hp: int = tank.health
	tank.take_rear_damage(20) # 20 * 3 = 60 damage
	var hp_loss: int = initial_tank_hp - tank.health
	if hp_loss != 60:
		print("FAIL: Tank take_rear_damage expected 60 damage, got %d" % hp_loss)
		quit(1)
		return

	# Test rear weak point damage via take_damage() with attacker behind the tank (no infinite recursion)
	var dummy_player := CharacterBody2D.new()
	root.add_child(dummy_player)
	tank.rotation = 0.0
	dummy_player.global_position = tank.global_position + Vector2(-100.0, 0.0)
	tank.target = dummy_player

	var hp_before_rear_attack: int = tank.health
	tank.take_damage(20) # Attacker is directly behind tank (rear dot product > 0.4) -> 20 * 3 = 60 damage
	var rear_attack_loss: int = hp_before_rear_attack - tank.health
	if rear_attack_loss != 60:
		print("FAIL: Tank rear attack expected 60 damage (3x), got %d" % rear_attack_loss)
		quit(1)
		return

	# Test standard frontal damage with attacker in front of the tank
	dummy_player.global_position = tank.global_position + Vector2(100.0, 0.0)
	var hp_before_front_attack: int = tank.health
	tank.take_damage(20) # 20 >= armor_threshold (18), standard damage = 20
	var front_attack_loss: int = hp_before_front_attack - tank.health
	if front_attack_loss != 20:
		print("FAIL: Tank front attack expected 20 damage, got %d" % front_attack_loss)
		quit(1)
		return

	dummy_player.queue_free()
	tank.target = null

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
	quit(0)
