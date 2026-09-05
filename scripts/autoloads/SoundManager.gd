extends Node

## Autoload — plays SFX/music and manages bus volumes / low-pass filter.

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _low_pass_active: bool = false
const POOL_SIZE: int = 8


func _ready() -> void:
	_sfx = {
		"shoot": load("res://assets/audio/shoot.wav"),
		"reload": load("res://assets/audio/reload.wav"),
		"dry_fire": load("res://assets/audio/dry_fire.wav"),
		"hit": load("res://assets/audio/hit.wav"),
		"explosion": load("res://assets/audio/explosion.wav"),
		"dodge": load("res://assets/audio/dodge.wav"),
		"pickup": load("res://assets/audio/pickup.wav"),
		"death": load("res://assets/audio/death.wav"),
	}
	_music = {
		"title": load("res://assets/audio/music_title.wav"),
		"combat": load("res://assets/audio/music_combat.wav"),
	}
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	apply_saved_volumes()
	play_music("title")


func apply_saved_volumes() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	set_music_volume(float(settings.get("music_volume", 0.8)))
	set_sfx_volume(float(settings.get("sfx_volume", 1.0)))


func set_music_volume(linear: float) -> void:
	var db := linear_to_db(clampf(linear, 0.0001, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	SaveManager.data["settings"]["music_volume"] = linear


func set_sfx_volume(linear: float) -> void:
	var db := linear_to_db(clampf(linear, 0.0001, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
	SaveManager.data["settings"]["sfx_volume"] = linear


func play_sfx(id: String) -> void:
	if not _sfx.has(id) or _sfx[id] == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx[id]
			p.play()
			return
	_sfx_players[0].stream = _sfx[id]
	_sfx_players[0].play()


func play_music(id: String) -> void:
	if not _music.has(id) or _music[id] == null:
		return
	var stream: AudioStream = _music[id]
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	_music_player.play()


func set_low_pass(enabled: bool) -> void:
	if _low_pass_active == enabled:
		return
	_low_pass_active = enabled
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx >= 0 and AudioServer.get_bus_effect_count(bus_idx) > 0:
		AudioServer.set_bus_effect_enabled(bus_idx, 0, enabled)
