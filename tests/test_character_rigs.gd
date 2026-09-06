extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Dummy audio playback is not part of these rendering/structure checks.
	root.get_node("SoundManager")._sfx.clear()
	# 1. Initialize DecalManager for decal stamping assertions
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

	# 2. Test Player modular rig
	var player_scene = load("res://scenes/player/Player.tscn")
	if player_scene == null:
		print("FAIL: Player.tscn could not be loaded")
		quit(1)
		return
	var player = player_scene.instantiate()
	root.add_child(player)

	if not player.has_node("ShadowSprite") or not player.has_node("LegsSprite") or not player.has_node("TorsoContainer"):
		print("FAIL: Player missing modular rig components (ShadowSprite, LegsSprite, TorsoContainer)")
		quit(1)
		return

	if player.z_index != 1:
		print("FAIL: Player z_index expected 1, got %d" % player.z_index)
		quit(1)
		return

	var torso_container = player.get_node("TorsoContainer")
	if not torso_container.has_node("BodySprite") or not torso_container.has_node("WeaponSprite") or not torso_container.has_node("MuzzleMarker") or not torso_container.has_node("BrassMarker"):
		print("FAIL: Player TorsoContainer missing child components")
		quit(1)
		return

	# 3. Test Legs walk animation & aim tracking
	player.velocity = Vector2(100, 0)
	player._physics_process(0.1)
	var legs = player.get_node("LegsSprite")
	if absf(legs.rotation - 0.0) > 0.05:
		print("FAIL: LegsSprite did not align with velocity angle")
		quit(1)
		return

	player.velocity = Vector2.ZERO
	player._physics_process(0.1)
	if legs.frame != 0:
		print("FAIL: LegsSprite did not reset to frame 0 when stationary")
		quit(1)
		return

	# 4. Test Weapon recoil
	player._apply_recoil()
	if torso_container.position == Vector2.ZERO:
		print("FAIL: Player weapon recoil kickback not applied to TorsoContainer")
		quit(1)
		return

	# 5. Test Dodge roll tumble & shadow fade
	player._start_dodge()
	var shadow = player.get_node("ShadowSprite")
	if shadow.modulate.a > 0.5:
		print("FAIL: ShadowSprite alpha did not fade during dodge roll")
		quit(1)
		return
	player._on_dodge_duration_finished()
	if shadow.modulate.a < 0.9:
		print("FAIL: ShadowSprite alpha did not restore after dodge roll")
		quit(1)
		return

	# 6. Test all Enemy scenes for modular rig & z_index
	var enemy_scenes: Array[String] = [
		"res://scenes/enemies/Rifleman.tscn",
		"res://scenes/enemies/Shotgunner.tscn",
		"res://scenes/enemies/MachineGunner.tscn",
		"res://scenes/enemies/Sniper.tscn",
		"res://scenes/enemies/Officer.tscn",
		"res://scenes/enemies/Grenadier.tscn",
	]

	for path in enemy_scenes:
		var scene = load(path)
		if scene == null:
			print("FAIL: Could not load %s" % path)
			quit(1)
			return
		var enemy = scene.instantiate()
		root.add_child(enemy)

		if not enemy.has_node("ShadowSprite") or not enemy.has_node("LegsSprite") or not enemy.has_node("TorsoContainer"):
			print("FAIL: %s missing modular rig nodes" % path)
			quit(1)
			return

		if enemy.z_index != 1:
			print("FAIL: %s z_index expected 1, got %d" % [path, enemy.z_index])
			quit(1)
			return

		var e_torso = enemy.get_node("TorsoContainer")
		if not e_torso.has_node("BodySprite") or not e_torso.has_node("MuzzleMarker"):
			print("FAIL: %s TorsoContainer missing BodySprite or MuzzleMarker" % path)
			quit(1)
			return

		var b_sprite: Sprite2D = e_torso.get_node("BodySprite")
		if b_sprite.texture == null:
			print("FAIL: %s BodySprite missing texture" % path)
			quit(1)
			return

		enemy.queue_free()

	# 7. Test Enemy death collapse and casualty decal stamp
	var test_enemy_scene = load("res://scenes/enemies/Rifleman.tscn")
	var test_enemy = test_enemy_scene.instantiate()
	root.add_child(test_enemy)

	var decals_before = dm.get_decal_count()
	test_enemy._die()
	var decals_after = dm.get_decal_count()

	if decals_after <= decals_before:
		print("FAIL: Casualty and blood decals not stamped on enemy death")
		quit(1)
		return

	await create_timer(0.3).timeout
	print("PASS: Character rig hierarchy verified")
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
