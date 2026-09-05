extends Node

## Autoload — plays SFX/music and manages bus volumes / low-pass filter.

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _low_pass_active: bool = false
const POOL_SIZE: int = 8

const _SFX_PATHS: Dictionary = {
	"shoot": "res://assets/audio/shoot.wav",
	"reload": "res://assets/audio/reload.wav",
	"dry_fire": "res://assets/audio/dry_fire.wav",
	"hit": "res://assets/audio/hit.wav",
	"explosion": "res://assets/audio/explosion.wav",
	"dodge": "res://assets/audio/dodge.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"death": "res://assets/audio/death.wav",
}

const _MUSIC_PATHS: Dictionary = {
	"title": "res://assets/audio/music_title.wav",
	"combat": "res://assets/audio/music_combat.wav",
}


func _ready() -> void:
	for id in _SFX_PATHS:
		_sfx[id] = _safe_load_stream(_SFX_PATHS[id])
	for id in _MUSIC_PATHS:
		_music[id] = _safe_load_stream(_MUSIC_PATHS[id])
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


func _safe_load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("SoundManager: missing audio %s" % path)
		return null
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res is AudioStream:
		return res as AudioStream
	push_warning("SoundManager: failed to load audio %s" % path)
	return null


func apply_saved_volumes() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	set_music_volume(float(settings.get("music_volume", 0.8)))
	set_sfx_volume(float(settings.get("sfx_volume", 1.0)))


func set_music_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
	SaveManager.data["settings"]["music_volume"] = linear


func set_sfx_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
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
	if _music_player == null:
		return
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
