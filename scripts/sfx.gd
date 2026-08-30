extends Node

const RATE := 22050
const VOICES := 8

var _players: Array[AudioStreamPlayer] = []
var _next := 0

var s_buzz: AudioStreamWAV
var s_blip: AudioStreamWAV
var s_tick: AudioStreamWAV
var s_tap: AudioStreamWAV
var s_type: AudioStreamWAV
var s_shear: AudioStreamWAV

const PREFS := "user://forreals.cfg"

var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_prefs()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	s_buzz = _render(0.24, _buzz_voice)
	s_blip = _render(0.10, _blip_voice)
	s_tick = _render(0.035, _tick_voice)
	s_tap = _render(0.05, _tap_voice)
	s_type = _render(0.018, _type_voice)
	s_shear = _render(0.30, _shear_voice)


func set_muted(v: bool) -> void:
	muted = v
	var f := FileAccess.open(PREFS, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"muted": muted}))
	f.close()
	if not muted:
		tick()


func _load_prefs() -> void:
	if not FileAccess.file_exists(PREFS):
		return
	var f := FileAccess.open(PREFS, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(text)
	if typeof(d) == TYPE_DICTIONARY:
		muted = bool(d.get("muted", false))


func _buzz_voice(t: float, u: float) -> float:
	var env: float = pow(1.0 - u, 3.0)
	var saw := fposmod(t * 52.0, 1.0) * 2.0 - 1.0
	var sqr := 1.0 if fposmod(t * 49.0, 1.0) < 0.5 else -1.0
	var sub := sin(TAU * 26.0 * t)
	return (saw * 0.45 + sqr * 0.35 + sub * 0.4) * env


func _blip_voice(t: float, u: float) -> float:
	var env: float = pow(1.0 - u, 2.4)
	var f: float = lerp(1180.0, 760.0, u)
	return (sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.18) * env


func _tick_voice(t: float, u: float) -> float:
	var env: float = pow(1.0 - u, 6.0)
	return (randf() * 2.0 - 1.0) * env * 0.5 + sin(TAU * 2200.0 * t) * env * 0.3


func _tap_voice(t: float, u: float) -> float:
	var env: float = pow(1.0 - u, 5.0)
	var f: float = lerp(520.0, 300.0, u)
	return sin(TAU * f * t) * env


func _type_voice(t: float, u: float) -> float:
	var env: float = pow(1.0 - u, 4.0)
	return ((randf() * 2.0 - 1.0) * 0.35 + sin(TAU * 3100.0 * t) * 0.25) * env


func _shear_voice(t: float, u: float) -> float:
	var env: float = pow(1.0 - u, 1.6)
	var gate: float = 1.0 if fposmod(t * lerp(90.0, 22.0, u), 1.0) < 0.55 else 0.15
	var n := randf() * 2.0 - 1.0
	var tone := sin(TAU * lerp(300.0, 70.0, u) * t)
	return (n * 0.55 + tone * 0.45) * gate * env


func _render(seconds: float, voice: Callable) -> AudioStreamWAV:
	var count := int(seconds * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var u := float(i) / maxf(1.0, float(count))
		var v: float = clampf(voice.call(t, u), -1.0, 1.0)
		var s := int(v * 32000.0)
		bytes.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


func _play(stream: AudioStreamWAV, gain: float, pitch: float = 1.0) -> void:
	if muted or stream == null or gain <= 0.0:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(clampf(gain, 0.0001, 1.0))
	p.play()


func buzz(gain: float = 0.06) -> void:
	_play(s_buzz, clampf(gain * 5.0, 0.05, 0.9), randf_range(0.94, 1.06))


func blip() -> void:
	_play(s_blip, 0.28, randf_range(0.97, 1.05))


func tick() -> void:
	_play(s_tick, 0.16, randf_range(0.9, 1.15))


func tap() -> void:
	_play(s_tap, 0.20, randf_range(0.95, 1.08))


func keypress() -> void:
	_play(s_type, 0.10, randf_range(0.85, 1.2))


func shear(gain: float = 0.5) -> void:
	_play(s_shear, clampf(gain, 0.05, 0.9), randf_range(0.8, 1.1))
