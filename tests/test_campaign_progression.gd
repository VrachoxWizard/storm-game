extends SceneTree

var failures: int = 0
var checks: int = 0
var main: Node2D
var mission: Node2D
var player: CharacterBody2D

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else: print("PASS: " + label)

func _run() -> void:
	root.get_node("SoundManager")._sfx.clear()
	main = Node2D.new()
	main.name = "Main"
	root.add_child(main)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	main.add_child(projectiles)
	for index in range(1, 6):
		var selected := OS.get_cmdline_user_args()
		if not selected.is_empty() and str(index) not in selected: continue
		mission = load("res://scenes/missions/Mission%d.tscn" % index).instantiate()
		main.add_child(mission)
		player = mission.get_node("Player")
		player.set_physics_process(false)
		player._respawn_protection = 10000.0
		await physics_frame
		await process_frame
		check(mission.get_node("Fieldworks").get_child_count() >= 4, "Mission %d has authored cover and landmarks" % index)
		check(player.camera.limit_right == int(mission.get_node("Ground").size.x), "Mission %d camera bounds match map" % index)
		_check_routes(index)
		match index:
			1: await _holdout()
			2: await _bunkers()
			3: await _convoy()
			4: await _streets()
			5: await _fortress()
		mission.queue_free()
		for bullet in projectiles.get_children(): bullet.queue_free()
		await process_frame
		await process_frame
	main.queue_free()
	await create_timer(0.4).timeout
	print("Campaign checks: %d; failures: %d" % [checks, failures])
	call_deferred("quit", 1 if failures else 0)

func _check_routes(index: int) -> void:
	var size: Vector2 = mission.get_node("Ground").size
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, int(size.x / 24), int(size.y / 24))
	grid.cell_size = Vector2(24, 24)
	grid.offset = Vector2(12, 12)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 32
	var space := player.get_world_2d().direct_space_state
	for y in range(grid.region.size.y):
		for x in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			query.transform = Transform2D(0.0, grid.get_point_position(cell))
			grid.set_point_solid(cell, not space.intersect_shape(query, 1).is_empty())
	var start := Vector2i(player.position / 24.0)
	var unreachable: Array[String] = []
	for pickup in mission.get_node("Pickups").get_children():
		var goal := Vector2i(pickup.position / 24.0)
		var reachable: bool = false
		for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var candidate: Vector2i = goal + offset
			if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
				if not grid.get_id_path(start, candidate).is_empty(): reachable = true
		if not reachable: unreachable.append(pickup.name)
	check(unreachable.is_empty(), "Mission %d supplies reachable with player-sized clearance: %s" % [index, str(unreachable)])

func _holdout() -> void:
	var ctrl: Node = mission.get_node("MissionController")
	for wave in range(3):
		# Let the real staggered spawner finish, then test wave bookkeeping.
		while ctrl._pending_spawns > 0:
			await create_timer(0.2).timeout
		var all_pursue: bool = true
		for enemy in mission.get_node("Enemies").get_children():
			all_pursue = all_pursue and enemy._assault_target
			enemy.take_damage(10000)
		check(all_pursue, "Holdout wave %d attackers pursue the position" % (wave + 1))
		await create_timer(4.2).timeout
	check(ctrl._mission_complete, "All three holdout waves complete")

func _bunkers() -> void:
	var ctrl: Node = mission.get_node("MissionController")
	for bunker in mission.get_node("Bunkers").get_children(): bunker.take_explosive_damage(10000)
	await process_frame
	player.position = mission.get_node("ExitZone").position
	await physics_frame
	await physics_frame
	await process_frame
	await create_timer(0.15).timeout
	check(ctrl._mission_complete, "Bunker assault completes at breach exit")

func _convoy() -> void:
	var ctrl: Node = mission.get_node("MissionController")
	var tank: Node = mission.get_node("Vehicles/Tank")
	check(tank.collision_layer == 0, "Later tank has no invisible collision")
	check(not ctrl._convoy_started, "Convoy waits while player collects starting equipment")
	player.position.x = 400
	await physics_frame
	await process_frame
	check(ctrl._convoy_started, "Convoy starts at ambush approach")
	mission.get_node("Vehicles/Apc").take_damage(10000)
	await process_frame
	check(tank.can_process() and tank.collision_layer == 64, "APC destruction activates tank")
	tank.take_damage(10000)
	player.position = mission.get_node("VillageZone").position
	await physics_frame
	await physics_frame
	await process_frame
	await create_timer(0.15).timeout
	check(ctrl._mission_complete, "Armor encounter completes at village")

func _streets() -> void:
	var ctrl: Node = mission.get_node("MissionController")
	var tracker: ObjectiveTracker = ctrl.objective_tracker
	check(tracker.get_progress()["total"] == 5, "Urban mission requires three streets, mortars, and exit")
	for mortar in mission.get_node("Mortars").get_children():
		if mortar.has_method("take_damage"): mortar.take_damage(10000)
	player.position = mission.get_node("ApproachZone").position
	await physics_frame
	await physics_frame
	check(not ctrl._mission_complete, "Killing mortars and rushing exit cannot skip streets")
	for segment in ctrl._segment_groups:
		for enemy in segment:
			if is_instance_valid(enemy): enemy.take_damage(10000)
		await create_timer(0.9).timeout
	await process_frame
	check(ctrl._mission_complete, "Urban mission completes while already standing in exit after street clears")

func _fortress() -> void:
	var ctrl: Node = mission.get_node("MissionController")
	var flag: Area2D = mission.get_node("FlagObjective")
	flag._player_inside = true
	Input.action_press("interact")
	flag._process(3.0)
	Input.action_release("interact")
	check(not flag._raised, "Early flag interaction cannot consume victory trigger")
	for enemy in mission.get_node("ApproachEnemies").get_children(): enemy.take_damage(10000)
	await process_frame
	check(ctrl._stage == ctrl.Stage.TANK, "Fortress approach unlocks tank stage")
	mission.get_node("Vehicles/Tank").take_damage(10000)
	await process_frame
	for enemy in mission.get_node("CourtyardEnemies").get_children(): enemy.take_damage(10000)
	check(flag.enabled and ctrl._stage == ctrl.Stage.FLAG, "Courtyard clear unlocks flag")
	flag._player_inside = true
	flag._process(3.0)
	check(not flag._raised, "Flag requires holding interact")
	Input.action_press("interact")
	flag._process(2.1)
	Input.action_release("interact")
	check(ctrl._mission_complete, "Fortress victory remains completable after early flag visit")
