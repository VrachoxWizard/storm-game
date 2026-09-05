extends SceneTree

func _init() -> void:
	var decal_script = load("res://scripts/effects/DecalManager.gd")
	if decal_script == null:
		print("FAIL: DecalManager.gd not found")
		quit(1)
		return
	var dm = Node2D.new()
	dm.set_script(decal_script)
	root.add_child(dm)

	var vfx_script = load("res://scripts/effects/CombatVfx.gd")
	if vfx_script == null:
		print("FAIL: CombatVfx.gd not found")
		quit(1)
		return
	var vfx = Node2D.new()
	vfx.set_script(vfx_script)
	root.add_child(vfx)

	if not vfx.has_method("spawn_multi_stage_explosion"):
		print("FAIL: spawn_multi_stage_explosion method missing")
		quit(1)
		return

	if not vfx.has_method("spawn_ricochet"):
		print("FAIL: spawn_ricochet method missing")
		quit(1)
		return

	if not vfx.has_method("spawn_burning_wreck_fire"):
		print("FAIL: spawn_burning_wreck_fire method missing")
		quit(1)
		return

	var initial_decals: int = dm.get_decal_count()

	# Test muzzle flash variations
	vfx.spawn_muzzle_flash(Vector2(50, 50), 0.0, "shotgun")
	vfx.spawn_muzzle_flash(Vector2(55, 50), 0.2, "rifle")
	vfx.spawn_muzzle_flash(Vector2(60, 50), 0.4, "pistol")
	vfx.spawn_muzzle_flash(Vector2(65, 50), 0.6, "heavy")
	vfx.spawn_muzzle_flash(Vector2(70, 50), 0.8) # Default weapon_type = 'rifle'

	# Each conventional muzzle flash should eject a spent casing via DecalManager
	if dm.get_decal_count() <= initial_decals:
		print("FAIL: Casing decals not spawned on muzzle flash")
		quit(1)
		return

	# Verify rocket/cannon does not eject brass casings
	var count_before_explosive_shots: int = dm.get_decal_count()
	vfx.spawn_muzzle_flash(Vector2(80, 50), 0.0, "rocket")
	vfx.spawn_muzzle_flash(Vector2(85, 50), 0.0, "cannon")
	if dm.get_decal_count() != count_before_explosive_shots:
		print("FAIL: Rocket/cannon should not spawn spent brass casing")
		quit(1)
		return

	var count_after_casings: int = dm.get_decal_count()

	# Test multi-stage explosions
	vfx.spawn_multi_stage_explosion(Vector2(100, 100), 60.0)
	vfx.spawn_multi_stage_explosion(Vector2(150, 150), 100.0)

	# Explosion should stamp scorch decals
	if dm.get_decal_count() <= count_after_casings:
		print("FAIL: Scorch decals not stamped on explosion")
		quit(1)
		return

	# Test ricochet
	vfx.spawn_ricochet(Vector2(150, 150), Vector2(-1, 0))
	vfx.spawn_ricochet(Vector2(160, 150), Vector2(0, 1))

	# Test burning wreck fire
	var fire_node: Node2D = vfx.spawn_burning_wreck_fire(Vector2(200, 200))
	if fire_node == null:
		print("FAIL: spawn_burning_wreck_fire returned null")
		quit(1)
		return
	if fire_node.get_child_count() < 3:
		print("FAIL: burning wreck fire missing required particles or light components")
		quit(1)
		return

	# Test blood and dust backwards compatibility
	var count_before_blood: int = dm.get_decal_count()
	vfx.spawn_blood(Vector2(250, 250))
	if dm.get_decal_count() <= count_before_blood:
		print("FAIL: Blood decal not stamped during spawn_blood")
		quit(1)
		return

	vfx.spawn_dust(Vector2(300, 300))

	# Test static API calls via vfx_script
	vfx_script.vfx_muzzle_flash(Vector2(320, 320), 0.0, "rifle")
	vfx_script.vfx_explosion(Vector2(340, 340), 80.0)
	vfx_script.vfx_ricochet(Vector2(360, 360), Vector2(1, 0))
	vfx_script.vfx_blood(Vector2(380, 380))
	vfx_script.vfx_dust(Vector2(400, 400))

	print("PASS: CombatVfx methods verified")
	quit(0)