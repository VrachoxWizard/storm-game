extends SceneTree

func _init() -> void:
	# Check all 5 missions
	var expected_modulate = {
		1: Color("E8DCB8"),
		2: Color("C4CCC4"),
		3: Color("F2EBE0"),
		4: Color("D0BDAA"),
		5: Color("DEC0B0")
	}

	var expected_terrain = {
		1: "res://assets/sprites/terrain/terrain_staging.png",
		2: "res://assets/sprites/terrain/terrain_trenches.png",
		3: "res://assets/sprites/terrain/terrain_highway.png",
		4: "res://assets/sprites/terrain/terrain_urban.png",
		5: "res://assets/sprites/terrain/terrain_fortress.png"
	}

	for m in range(1, 6):
		var path = "res://scenes/missions/Mission%d.tscn" % m
		var scn = load(path)
		if scn == null:
			print("FAIL: Mission%d failed to load" % m)
			quit(1)
			return
		var inst = scn.instantiate()
		root.add_child(inst)
		
		# Check CanvasModulate
		if not inst.has_node("CanvasModulate"):
			print("FAIL: Mission%d missing CanvasModulate atmospheric lighting" % m)
			quit(1)
			return
		
		var cm = inst.get_node("CanvasModulate") as CanvasModulate
		if cm == null:
			print("FAIL: Mission%d CanvasModulate is not a CanvasModulate node" % m)
			quit(1)
			return

		var expected_col: Color = expected_modulate[m]
		if not cm.color.is_equal_approx(expected_col):
			print("FAIL: Mission%d CanvasModulate color %s does not match expected %s" % [m, cm.color.to_html(false), expected_col.to_html(false)])
			quit(1)
			return
		
		# Check Ground TextureRect
		var ground = inst.get_node_or_null("Ground") as TextureRect
		if ground == null:
			print("FAIL: Mission%d missing Ground TextureRect" % m)
			quit(1)
			return
		if ground.texture == null or ground.texture.resource_path != expected_terrain[m]:
			var actual_path = ground.texture.resource_path if ground.texture else "null"
			print("FAIL: Mission%d ground texture '%s' does not match '%s'" % [m, actual_path, expected_terrain[m]])
			quit(1)
			return

		# For Mission 4, ensure no ColorRect nodes under Buildings
		if m == 4:
			var b_node = inst.get_node_or_null("Buildings")
			if b_node:
				for child in b_node.get_children():
					if child.has_node("ColorRect"):
						print("FAIL: Mission 4 still contains placeholder ColorRect buildings")
						quit(1)
						return
		inst.queue_free()

	# Verify architectural prefabs
	var prefabs = [
		"res://scenes/environment/BuildingTileRoof.tscn",
		"res://scenes/environment/BuildingTinRoof.tscn",
		"res://scenes/environment/BunkerEmplacement.tscn"
	]
	for p in prefabs:
		var p_scn = load(p)
		if p_scn == null:
			print("FAIL: Prefab failed to load: %s" % p)
			quit(1)
			return
		var p_inst = p_scn.instantiate()
		if not (p_inst is StaticBody2D):
			print("FAIL: Prefab %s root is not StaticBody2D" % p)
			quit(1)
			return
		if p_inst.collision_layer != 32:
			print("FAIL: Prefab %s collision_layer is %d, expected 32" % [p, p_inst.collision_layer])
			quit(1)
			return
		p_inst.queue_free()
		
	print("PASS: All 5 missions verified with visual upgrades")
	quit(0)
