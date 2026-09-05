# tests/run_all_visual_tests.gd
extends SceneTree

func _init() -> void:
	print("=== Running Operation Storm Visual Overhaul Master Test Suite ===")
	
	var tests: Array[String] = [
		"res://tests/test_decal_manager.gd",
		"res://tests/test_combat_vfx.gd",
		"res://tests/test_character_rigs.gd",
		"res://tests/test_vehicles_visual.gd",
		"res://tests/test_missions_visual.gd",
		"res://tests/test_ui_visual.gd",
	]
	
	for t in tests:
		print("Testing: %s ..." % t)
		var scn_test = load(t)
		if scn_test == null:
			print("FAILED to load test: %s" % t)
			quit(1)
			return
			
	print("=== All visual test scenes load and compile cleanly! ===")
	quit(0)
