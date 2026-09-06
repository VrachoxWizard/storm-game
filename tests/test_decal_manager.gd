extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Dummy audio playback is not part of these rendering/structure checks.
	root.get_node("SoundManager")._sfx.clear()
	var decal_script = load("res://scripts/effects/DecalManager.gd")
	if decal_script == null:
		print("FAIL: DecalManager.gd not found")
		quit(1)
		return
	var dm = Node2D.new()
	dm.set_script(decal_script)
	root.add_child(dm)
	
	# Test stamping up to 300 decals and assert cap at 250
	for i in range(300):
		dm.stamp_blood(Vector2(i * 2, i * 2))
	
	if dm.get_decal_count() > 250:
		print("FAIL: Decal count exceeded cap: %d" % dm.get_decal_count())
		quit(1)
		return
	
	# Test scorch, casing, treads
	dm.stamp_scorch(Vector2(100, 100), 1.5)
	dm.spawn_casing(Vector2(200, 200), Vector2(1, 0), false)
	dm.spawn_casing(Vector2(205, 200), Vector2(1, 0), true)
	dm.stamp_tread(Vector2(300, 300), 0.0, false)
	dm.stamp_tread(Vector2(320, 300), 0.5, true)
	
	# Test static API calls via decal_script
	decal_script.stamp_blood(Vector2(50, 50), Vector2(0, 1))
	decal_script.stamp_scorch(Vector2(60, 60), 2.0)
	
	if dm.get_decal_count() > 250:
		print("FAIL: Decal count exceeded cap after static calls: %d" % dm.get_decal_count())
		quit(1)
		return
	
	# Test clear_decals
	dm.clear_decals()
	if dm.get_decal_count() != 0:
		print("FAIL: Decal count should be 0 after clear: %d" % dm.get_decal_count())
		quit(1)
		return
	
	print("PASS: DecalManager test passed successfully")
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
