extends Node
## All game sound. Builds the sounds in a background thread at startup
## (SynthA/SynthB), then plays them from a small pool of players with slight
## random pitch so repeats never sound robotic. Listens to EventBus; a few
## systems call play() directly (coins, gates, buttons).
## The saw: a whir loop while held, a grind loop that swells while cutting.

const VOICES := 16
## Minimum gap (ms) between two plays of the same sound, so floods stay musical.
const GAP := {"ping": 40, "coin": 28, "shred": 70, "crack": 25, "glass": 35, "metal": 40,
	"squish": 40, "zap": 40, "gate": 70, "slash": 110, "catch": 30, "squeak": 70, "ceramic": 35,
	"ring": 150, "coins": 120, "pop": 25}
const VOLUME := {"whir": -18.0, "grind": -11.0, "ping": -14.0, "coin": -15.0, "shred": -17.0,
	"gate": -18.0, "tick": -12.0, "crack": -11.0, "glass": -11.0, "metal": -13.0, "squish": -9.0,
	"zap": -14.0, "thud": -6.0, "whoosh": -10.0, "slash": -12.0, "boom": -3.0, "catch": -13.0,
	"buy": -9.0, "star": -6.0, "win": -8.0, "fail": -8.0, "gold": -8.0, "card": -8.0,
	"twang": -7.0, "squeak": -9.0, "ceramic": -9.0, "ring": -11.0, "coins": -8.0, "pop": -10.0}
const MAT_SOUND := ["crack", "metal", "glass", "squish", "zap", "squeak", "ceramic"]
## Breaks climb this arpeggio as a combo grows, so a chain plays a little tune.
const LADDER := [1.0, 1.122, 1.26, 1.498, 1.682, 2.0, 1.682, 1.498]
## Peg notes: a pentatonic scale over two octaves (pins play a tune as pieces fall).
const SCALE := [1.0, 1.125, 1.25, 1.5, 1.667, 2.0, 2.25, 2.5, 3.0, 3.333]

var _streams := {}
var _built := {}
var _task: int = -1
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last := {}
var _whir: AudioStreamPlayer
var _grind: AudioStreamPlayer
var _held: bool = false
var _cutting: bool = false
var _combo: int = 0
var _mat: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_whir = AudioStreamPlayer.new()
	_grind = AudioStreamPlayer.new()
	add_child(_whir)
	add_child(_grind)
	_task = WorkerThreadPool.add_task(_build)
	# A limiter on the master bus: many sounds at once get louder, never distort.
	if AudioServer.get_bus_effect_count(0) == 0:
		var room := AudioEffectReverb.new()     # a little room: everything sounds fuller
		room.room_size = 0.4
		room.damping = 0.55
		room.wet = 0.13
		room.predelay_msec = 18.0
		AudioServer.add_bus_effect(0, room)
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -1.5
		AudioServer.add_bus_effect(0, lim)
	EventBus.block_shattered.connect(_on_shattered)
	EventBus.combo_changed.connect(func(c: int): _combo = c)
	EventBus.peg_hit.connect(func(i: int): play("ping", SCALE[i % SCALE.size()], 0.0, 0.0))
	EventBus.fragment_collected.connect(func(_p: Vector2, _c: Color, _a: int): play("shred"))
	EventBus.golden_found.connect(func(_g: String, _s: int, _p: Vector2): play("gold"))
	EventBus.golden_missed.connect(func(_p: Vector2): play("zap", 0.5))
	EventBus.title_card_requested.connect(func(_a: String, _b: String, _c: Color): play("card"))
	EventBus.job_finished.connect(func(won: bool, _s: int): play("win" if won else "fail"))


func _build() -> void:
	var s := SynthA.all()
	s.merge(SynthB.all())
	s.merge(SynthC.all())
	_built = s


func _process(delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_streams = _built
		_whir.stream = _streams["whir"]
		_grind.stream = _streams["grind"]
		_whir.volume_db = -80.0
		_grind.volume_db = -80.0
		_whir.play()
		_grind.play()
	if _streams.is_empty():
		return
	# Slow motion bends the saw down in pitch; hit-stops don't (too short).
	var slow := clampf(Engine.time_scale, 0.5, 1.0) if Engine.time_scale > 0.1 else 1.0
	var paused := get_tree().paused
	var whir_db := -80.0 if paused or not _held else VOLUME["whir"]
	var grind_db := VOLUME["grind"] if _cutting and not paused else -80.0
	_whir.volume_db = move_toward(_whir.volume_db, whir_db, delta * 160.0)
	_grind.volume_db = move_toward(_grind.volume_db, grind_db, delta * (260.0 if _cutting else 90.0))
	_whir.pitch_scale = lerpf(_whir.pitch_scale, (1.25 if _held else 0.8) * slow, 1.0 - exp(-8.0 * delta))
	_grind.pitch_scale = lerpf(_grind.pitch_scale, (Materials.PITCH[_mat] + randf() * 0.08) * slow, 0.3)


## The blade reports every physics frame.
func saw(held: bool, cutting: bool, mat: int = 0) -> void:
	_held = held
	_cutting = cutting
	_mat = mat


## pitch: base pitch. jitter: random +- spread. vol: extra dB.
func play(sound: String, pitch: float = 1.0, vol: float = 0.0, jitter: float = 0.06) -> void:
	if not _streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sound, -100000)) < int(GAP.get(sound, 0)):
		return
	_last[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.pitch_scale = maxf(0.05, pitch * (1.0 + randf_range(-jitter, jitter)))
	p.volume_db = float(VOLUME.get(sound, -6.0)) + vol
	p.play()


func _on_shattered(pos: Vector2, _c: Color, _v: int, _vel: Vector2, mat: int) -> void:
	if pos.y < PinField.BOARD_TOP:          # combos climb in pitch
		play(MAT_SOUND[mat], LADDER[_combo % LADDER.size()], 0.0, 0.02)
