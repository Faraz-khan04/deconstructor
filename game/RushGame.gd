class_name RushGame
extends Node2D
## RUSH mode: 60 seconds. Objects are thrown up from the bottom; swipe to
## slice them apart, catch the pieces in the bucket (x3). Slicing 2+ objects
## in one swipe = DOUBLE / TRIPLE bonus. Bombs cost 5 seconds. The last 10
## seconds are the FINAL RUSH: more throws, double pay.
## Earnings go into your normal cash. Stars by score -> unlock more modes.

const DURATION := 60.0
const FINAL := 10.0
const BOMB_FROM := 8.0
const BOMB_PENALTY := 5.0
const COMBO_WINDOW := 1.4
## Star targets, in "objects' worth" of money (see target()).
const STAR_AT := [30.0, 70.0, 120.0]

static var cur: RushGame = null

var time_left: float = DURATION
var run: int = 0
var running: bool = false
var level: int = 1
var _elapsed: float = 0.0
var _next_throw: float = 0.0
var _combo: int = 0
var _combo_t: float = 0.0
var _final: bool = false
var _over: bool = false
var _wipes: int = 0

@onready var _things: Node2D = $Things


func _ready() -> void:
	cur = self
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(ThemePalette.PAPER)
	level = maxi(1, int(Save.data["level"]))
	EventBus.score_added.connect(_on_score)
	EventBus.block_shattered.connect(_on_shattered)
	EventBus.bomb_hit.connect(_on_bomb)
	$Slicer.swipe_finished.connect(_on_swipe)
	_add_walls()
	_intro.call_deferred()
	get_tree().create_timer(1.2).timeout.connect(func(): running = true)


func _intro() -> void:
	EventBus.title_card_requested.emit("RUSH!", "SLICE · CATCH · DODGE THE BOMBS", ThemePalette.RED)


func _on_score(amount: int) -> void:
	if not _over:
		run += amount


func _exit_tree() -> void:
	if cur == self:
		cur = null


## One "object's worth" of money at your level and MONEY upgrade.
static func target(lvl_mult: float, value_mult: float) -> float:
	return 160.0 * lvl_mult * value_mult


func _process(delta: float) -> void:
	_combo_t -= delta
	if _combo > 0 and _combo_t <= 0.0:
		_combo = 0
		EventBus.combo_changed.emit(0)
	if not running:
		return
	time_left -= delta
	_elapsed += delta
	var wipe_at := int(_elapsed / 12.0)          # a fresh page every 12 seconds
	if wipe_at > _wipes:
		_wipes = wipe_at
		EventBus.wipe_requested.emit()
	if not _final and time_left <= FINAL:
		_final = true
		EventBus.title_card_requested.emit("FINAL RUSH!", "EVERYTHING PAYS DOUBLE", ThemePalette.TANGERINE)
	_next_throw -= delta
	if _next_throw <= 0.0:
		_throw_wave()
		_next_throw = 0.6 if _final else lerpf(1.15, 0.7, _elapsed / DURATION)
	if time_left <= 0.0:
		_finish()


func _throw_wave() -> void:
	var count := 1 + randi() % (2 + int(_elapsed / 20.0)) + (1 if _final else 0)
	for i in count:
		get_tree().create_timer(i * 0.16).timeout.connect(_throw_one)


func _throw_one() -> void:
	if not running:
		return
	var bomb := _elapsed > BOMB_FROM and randf() < 0.14 and not _final
	var t := Thrown.new()
	t.fly_in = false
	t.is_bomb = bomb
	_things.add_child(t)
	var def := RushBomb.def() if bomb else ObjectLibrary.build(ObjectLibrary.NAMES.pick_random())
	t.build(def, Vector2.ZERO, 0.62 if bomb else randf_range(0.48, 0.6), level, false, 0.0)
	var x := randf_range(180.0, 900.0)
	var v := Vector2((540.0 - x) * randf_range(0.3, 0.8), -randf_range(2350.0, 2750.0))
	t.launch(Vector2(x, 2450.0), v, randf_range(-3.0, 3.0))
	t.sliced.connect(_on_sliced)
	t.missed.connect(_on_missed)
	Sfx.play("whoosh", 1.4, -6.0)


func _on_sliced(t: Thrown) -> void:
	if t.is_bomb:
		return
	_combo += 1
	_combo_t = COMBO_WINDOW
	EventBus.combo_changed.emit(_combo)
	EventBus.shake_requested.emit(0.25)
	EventBus.splash.emit(t.global_position, t.vel, 0.28, Color(0, 0, 0, 0))


func _on_missed(t: Thrown) -> void:
	if t.is_bomb or not running:
		return
	_combo = 0
	EventBus.combo_changed.emit(0)
	EventBus.popup_requested.emit("MISSED", Vector2(clampf(t.global_position.x, 200.0, 880.0), 1700.0),
		ThemePalette.INK_SOFT, 0.6)


func _on_shattered(_p: Vector2, _c: Color, value: int, _v: Vector2, _m: int) -> void:
	EventBus.score_added.emit(int(round(value * Economy.value_mult() * (2.0 if _final else 1.0))))


func _on_swipe(objects: int, at: Vector2) -> void:
	if objects < 2 or not running:
		return
	var bonus := int(round(objects * objects * 40.0 * Economy.level_mult() * Economy.value_mult()))
	var word: String = ["", "", "DOUBLE!", "TRIPLE!", "QUAD!"][mini(objects, 4)] if objects <= 4 \
		else "x%d SLICE!" % objects
	EventBus.popup_requested.emit(word, at, ThemePalette.RED, 1.2 + objects * 0.1)
	EventBus.popup_requested.emit("+" + NumFmt.money(bonus), at + Vector2(0, 110), ThemePalette.TEAL, 0.7)
	EventBus.score_added.emit(bonus)
	EventBus.impact.emit(at, 1.0)
	Sfx.play("gold", 0.8 + objects * 0.1)


func _on_bomb(at: Vector2) -> void:
	time_left = maxf(0.0, time_left - BOMB_PENALTY)
	_combo = 0
	EventBus.combo_changed.emit(0)
	EventBus.impact.emit(at, 1.0)
	EventBus.shake_requested.emit(1.0)
	EventBus.popup_requested.emit("BOOM! -%ds" % int(BOMB_PENALTY), at, ThemePalette.RED, 1.5)
	Sfx.play("boom")
	JuiceManager.buzz(250, 1.0)


func _finish() -> void:
	running = false
	time_left = 0.0
	EventBus.title_card_requested.emit("TIME!", "COUNTING YOUR CASH...", ThemePalette.COBALT)
	get_tree().create_timer(2.6).timeout.connect(_results)


func _results() -> void:
	_over = true
	var unit := target(Economy.level_mult(), Economy.value_mult())
	var stars := 0
	for s in STAR_AT:
		if run >= s * unit:
			stars += 1
	Save.set_stars(-1, stars)                  # -1 = Rush's slot in the stars table
	if run > int(Save.data.get("rush_best", 0)):
		Save.data["rush_best"] = run
		Save.mark_dirty()
	$RushResult.show_result(run, stars, unit)


## Side walls so flung pieces bounce back toward the bins.
func _add_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 8
	for x in [-30.0, 1110.0]:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(60.0, 4000.0)
		cs.shape = r
		cs.position = Vector2(x, 1000.0)
		walls.add_child(cs)
	add_child(walls)
