extends SceneTree

## Verifies objective guidance: markers, tracker target API, zone banners, HUD arrow.

var failures: int = 0
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
		print("FAIL: " + label)
	else:
		print("PASS: " + label)


func _run() -> void:
	root.get_node("SoundManager")._sfx.clear()
	var main := Node2D.new()
	main.name = "Main"
	root.add_child(main)

	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	check(hud_scene != null, "HUD.tscn loads")
	var hud: CanvasLayer = hud_scene.instantiate()
	hud.name = "HUD"
	main.add_child(hud)
	check(hud.get_node_or_null("ObjectiveArrow") != null, "HUD has ObjectiveArrow")
	check(hud.get_node("ObjectiveArrow").has_method("set_targets"), "ObjectiveArrow exposes set_targets")

	var marker_scene: PackedScene = load("res://scenes/effects/ObjectiveMarker.tscn")
	check(marker_scene != null, "ObjectiveMarker.tscn loads")
	var marker: Node2D = marker_scene.instantiate()
	main.add_child(marker)
	check(marker.has_method("set_target"), "ObjectiveMarker exposes set_target")
	marker.queue_free()

	await _test_tracker_api(main)
	await _test_mission2(main)
	await _test_mission3(main)
	await _test_mission4(main)
	await _test_mission5(main)

	# Mission 1 is holdout — no positional guidance required.
	var m1 = load("res://scenes/missions/Mission1.tscn").instantiate()
	main.add_child(m1)
	await process_frame
	check(m1.get_node_or_null("MissionController") != null, "Mission 1 controller present")
	m1.queue_free()
	await process_frame

	main.queue_free()
	await create_timer(0.2).timeout
	print("Objective guidance checks: %d; failures: %d" % [checks, failures])
	call_deferred("quit", 1 if failures else 0)


func _test_tracker_api(main: Node) -> void:
	var tracker := ObjectiveTracker.new()
	main.add_child(tracker)
	tracker.sequential = true
	var a := Node2D.new()
	var b := Node2D.new()
	main.add_child(a)
	main.add_child(b)
	var area := Area2D.new()
	main.add_child(area)
	tracker.add_destroy_objective([a], "A")
	tracker.add_destroy_objective([b], "B")
	tracker.add_area_objective(area, "Exit")
	tracker.emit_initial_target()
	var targets: Array[Node2D] = tracker.get_current_targets()
	check(targets.size() == 1 and targets[0] == a, "Tracker current targets starts at first destroy")
	check(tracker.get_current_label() == "A", "Tracker current label is first objective")
	a.queue_free()
	await process_frame
	# Without destroy signal, free alone won't advance — use Dummy pattern.
	tracker.queue_free()
	a = null
	b.queue_free()
	area.queue_free()
	await process_frame

	# Signal-driven destroy progress + target change.
	tracker = ObjectiveTracker.new()
	main.add_child(tracker)
	tracker.sequential = true
	var d1 := _DestroyDummy.new()
	var d2 := _DestroyDummy.new()
	main.add_child(d1)
	main.add_child(d2)
	var changed: Array = []
	tracker.objective_target_changed.connect(func(t: Array, _l: String) -> void:
		changed.append(t.size())
	)
	tracker.add_destroy_objective([d1], "first")
	tracker.add_destroy_objective([d2], "second")
	tracker.emit_initial_target()
	check(tracker.get_current_targets().size() == 1, "Initial targets size 1")
	d1.destroyed.emit()
	await process_frame
	check(tracker.get_progress()["completed"] == 1, "First destroy completes objective")
	check(tracker.get_current_targets().size() == 1 and tracker.get_current_targets()[0] == d2, "Targets advance to second")
	check(not changed.is_empty(), "objective_target_changed emitted")
	tracker.queue_free()
	d1.queue_free()
	d2.queue_free()
	await process_frame


func _test_mission2(main: Node) -> void:
	var mission = load("res://scenes/missions/Mission2.tscn").instantiate()
	main.add_child(mission)
	await process_frame
	await process_frame
	await process_frame
	var ctrl: Node = mission.get_node("MissionController")
	var tracker: ObjectiveTracker = ctrl.objective_tracker
	check(tracker.get_progress()["total"] == 3, "Mission 2 has 3 sequential objectives (2 bunkers + exit)")
	var exit_zone: Area2D = mission.get_node("ExitZone")
	check(exit_zone.has_meta("zone_banner") or exit_zone.get_node_or_null("ZoneBanner") != null, "Mission 2 ExitZone has visible banner")
	var targets: Array[Node2D] = tracker.get_current_targets()
	check(targets.size() == 1, "Mission 2 starts with one active bunker target")
	if targets.size() == 1:
		var bunkers: Array = mission.get_node("Bunkers").get_children()
		var north: Node2D = bunkers[0] as Node2D
		for b in bunkers:
			if (b as Node2D).position.y < north.position.y:
				north = b as Node2D
		check(targets[0] == north, "Mission 2 first target is northern bunker")
	# Guidance binder should spawn a marker.
	var markers := _find_markers(mission)
	check(markers.size() >= 1, "Mission 2 spawns ObjectiveMarker on first bunker")
	# Destroy north bunker → marker should move to south.
	if targets.size() == 1 and targets[0].has_method("take_explosive_damage"):
		targets[0].take_explosive_damage(10000)
	elif targets.size() == 1 and targets[0].has_method("take_damage"):
		targets[0].take_damage(10000)
	await process_frame
	await process_frame
	check(tracker.get_progress()["completed"] == 1, "Mission 2 advances after first bunker")
	var next_targets: Array[Node2D] = tracker.get_current_targets()
	check(next_targets.size() == 1, "Mission 2 points at second bunker after first dies")
	mission.queue_free()
	await process_frame


func _test_mission3(main: Node) -> void:
	var mission = load("res://scenes/missions/Mission3.tscn").instantiate()
	main.add_child(mission)
	await process_frame
	await process_frame
	await process_frame
	var ctrl: Node = mission.get_node("MissionController")
	var tracker: ObjectiveTracker = ctrl.objective_tracker
	var village: Area2D = mission.get_node("VillageZone")
	check(village.has_meta("zone_banner") or village.get_node_or_null("ZoneBanner") != null, "Mission 3 VillageZone has banner")
	var targets: Array[Node2D] = tracker.get_current_targets()
	check(targets.size() == 1, "Mission 3 starts targeting APC")
	check(_find_markers(mission).size() >= 1, "Mission 3 has ObjectiveMarker on APC")
	mission.queue_free()
	await process_frame


func _test_mission4(main: Node) -> void:
	var mission = load("res://scenes/missions/Mission4.tscn").instantiate()
	main.add_child(mission)
	await process_frame
	await process_frame
	var approach: Area2D = mission.get_node("ApproachZone")
	check(approach.has_meta("zone_banner") or approach.get_node_or_null("ZoneBanner") != null, "Mission 4 ApproachZone has banner")
	# Street phase should not spam markers.
	check(_find_markers(mission).is_empty(), "Mission 4 omits markers during street clears")
	mission.queue_free()
	await process_frame


func _test_mission5(main: Node) -> void:
	var mission = load("res://scenes/missions/Mission5.tscn").instantiate()
	main.add_child(mission)
	await process_frame
	await process_frame
	var flag: Area2D = mission.get_node("FlagObjective")
	check(flag.is_in_group("flag"), "Mission 5 FlagObjective is in flag group")
	var ctrl: Node = mission.get_node("MissionController")
	# Stage 1: no tank marker yet.
	check(_find_markers(mission).is_empty(), "Mission 5 omits markers during approach clear")
	for e in mission.get_node("ApproachEnemies").get_children():
		if e.has_method("take_damage"):
			e.take_damage(10000)
	await process_frame
	await process_frame
	check(ctrl._stage == ctrl.Stage.TANK, "Mission 5 enters tank stage")
	check(_find_markers(mission).size() >= 1, "Mission 5 marks T-55 in tank stage")
	mission.queue_free()
	await process_frame


func _find_markers(root: Node) -> Array:
	var found: Array = []
	_collect_markers(root, found)
	return found


func _collect_markers(node: Node, found: Array) -> void:
	if node.get_script() != null and str(node.get_script().resource_path).ends_with("ObjectiveMarker.gd"):
		found.append(node)
	for child in node.get_children():
		_collect_markers(child, found)


class _DestroyDummy extends Node2D:
	signal destroyed
