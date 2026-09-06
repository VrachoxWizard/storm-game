extends Node

## Autoload — Easy / Normal / Hard multipliers and player starting kit.
## Persists the choice in SaveManager.data.settings["difficulty"].

enum Difficulty { EASY, NORMAL, HARD }

const SETTINGS_KEY: String = "difficulty"
const DEFAULT_KEY: String = "normal"

const _STRING_TO_DIFF: Dictionary = {
	"easy": Difficulty.EASY,
	"normal": Difficulty.NORMAL,
	"hard": Difficulty.HARD,
}

const _DIFF_TO_STRING: Dictionary = {
	Difficulty.EASY: "easy",
	Difficulty.NORMAL: "normal",
	Difficulty.HARD: "hard",
}

const _DIFF_TO_LABEL: Dictionary = {
	Difficulty.EASY: "Easy",
	Difficulty.NORMAL: "Normal",
	Difficulty.HARD: "Hard",
}

## Per-difficulty multipliers for enemy/vehicle stats and player kit values.
const PROFILES: Dictionary = {
	Difficulty.EASY: {
		"enemy_dmg": 0.55,
		"enemy_hp": 0.65,
		"enemy_speed": 0.80,
		"enemy_cooldown": 1.50,
		"enemy_detect": 0.75,
		"player_hp": 150,
		"player_armor": 50,
		"player_grenades": 2,
	},
	Difficulty.NORMAL: {
		"enemy_dmg": 0.80,
		"enemy_hp": 0.85,
		"enemy_speed": 0.95,
		"enemy_cooldown": 1.20,
		"enemy_detect": 0.90,
		"player_hp": 120,
		"player_armor": 25,
		"player_grenades": 1,
	},
	Difficulty.HARD: {
		"enemy_dmg": 1.00,
		"enemy_hp": 1.00,
		"enemy_speed": 1.00,
		"enemy_cooldown": 1.00,
		"enemy_detect": 1.00,
		"player_hp": 100,
		"player_armor": 0,
		"player_grenades": 0,
	},
}


func get_difficulty() -> Difficulty:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return Difficulty.NORMAL
	var key: String = str(sm.data.get("settings", {}).get(SETTINGS_KEY, DEFAULT_KEY)).to_lower()
	return int(_STRING_TO_DIFF.get(key, Difficulty.NORMAL)) as Difficulty


func set_difficulty(d: Difficulty) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return
	if not sm.data.has("settings") or not (sm.data["settings"] is Dictionary):
		sm.data["settings"] = {}
	sm.data["settings"][SETTINGS_KEY] = str(_DIFF_TO_STRING.get(d, DEFAULT_KEY))
	if sm.has_method("save_data"):
		sm.save_data()


func get_multiplier(key: String) -> float:
	var profile: Dictionary = PROFILES.get(get_difficulty(), PROFILES[Difficulty.NORMAL])
	return float(profile.get(key, 1.0))


func get_player_kit(key: String) -> int:
	var profile: Dictionary = PROFILES.get(get_difficulty(), PROFILES[Difficulty.NORMAL])
	return int(profile.get(key, 0))


func label(d: Difficulty = Difficulty.NORMAL) -> String:
	return str(_DIFF_TO_LABEL.get(d, "Normal"))


func current_label() -> String:
	return label(get_difficulty())
