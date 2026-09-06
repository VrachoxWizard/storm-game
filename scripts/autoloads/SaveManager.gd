extends Node

## Singleton — persists mission progress and high scores to user://save_data.json.

const SAVE_PATH: String = "user://save_data.json"

var data: Dictionary = {
	"missions_unlocked": 1,
	"high_scores": {},
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"screen_shake": true,
		"difficulty": "normal",
	},
}


func _ready() -> void:
	load_data()


func save_mission_score(mission_index: int, score: int, rank: String, time: float) -> void:
	var key := "mission_%d" % (mission_index + 1)
	var existing: Dictionary = data["high_scores"].get(key, {})

	if score > existing.get("score", 0):
		data["high_scores"][key] = {
			"score": score,
			"rank": rank,
			"time": time,
		}

	if mission_index + 2 > data["missions_unlocked"]:
		data["missions_unlocked"] = mission_index + 2

	save_data()


func is_mission_unlocked(mission_index: int) -> bool:
	return mission_index < data["missions_unlocked"]


func get_high_score(mission_index: int) -> Dictionary:
	var key := "mission_%d" % (mission_index + 1)
	return data["high_scores"].get(key, {})


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		file.close()
		if error == OK and json.data is Dictionary:
			_merge_defaults(json.data as Dictionary)


func _merge_defaults(loaded: Dictionary) -> void:
	## Merge saved data into defaults so older saves keep new settings keys.
	var defaults: Dictionary = data.duplicate(true)
	for key in loaded.keys():
		if key == "settings" and loaded[key] is Dictionary and defaults.has("settings"):
			var merged_settings: Dictionary = defaults["settings"].duplicate(true)
			for sk in (loaded["settings"] as Dictionary).keys():
				merged_settings[sk] = loaded["settings"][sk]
			defaults["settings"] = merged_settings
		else:
			defaults[key] = loaded[key]
	data = defaults
