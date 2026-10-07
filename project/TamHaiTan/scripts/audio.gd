extends Node
## Autoload "Audio": เล่นเสียงประกอบ (SFX) และเพลง แยกบัสเสียงเพื่อปรับความดังได้
## Audio.sfx("pound") / Audio.music("game")

const SFX_DIR := "res://assets/audio/sfx/%s.wav"
const MUSIC_DIR := "res://assets/audio/music/%s.ogg"
const VOICES := 10

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music := ""
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = "Music"
		add_child(m)
	set_volume("Music", GameState.music_volume)
	set_volume("SFX", GameState.sfx_volume)


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = s
	return s


## เล่นเสียงสั้น pitch_jitter สุ่มระดับเสียงเล็กน้อยไม่ให้ซ้ำซาก
func sfx(name: String, volume_db := 0.0, pitch_jitter := 0.06) -> void:
	var s := _load(SFX_DIR % name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## เปลี่ยนเพลงแบบเฟด ("" = หยุดเพลง)
func music(name: String, fade := 0.8) -> void:
	if name == _current_music:
		return
	_current_music = name
	var old := _music_a if _music_a.playing else _music_b
	var new := _music_b if old == _music_a else _music_a
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, fade)
		tw.tween_callback(old.stop)
	if name == "":
		return
	var s := _load(MUSIC_DIR % name)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	new.stream = s
	new.volume_db = -40.0
	new.play()
	create_tween().tween_property(new, "volume_db", -6.0, fade)


func set_volume(bus: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(i, linear <= 0.001)
