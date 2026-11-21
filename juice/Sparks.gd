class_name Sparks
extends Node2D
## Pooled sparks + paper confetti thrown off where the saw teeth bite.
## Listens to EventBus.grind_tick. Pure CPU drawing, fixed arrays, no nodes.

const MAX := 96
const LIFE := 0.32

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _kind := PackedByteArray()      # 0 spark streak, 1 confetti chip
var _col: Array[Color] = []
var _next: int = 0
var _active: int = 0
static var _me: Sparks = null


func _ready() -> void:
	z_index = 15
	_pos.resize(MAX)
	_vel.resize(MAX)
	_age.resize(MAX)
	_kind.resize(MAX)
	_col.resize(MAX)
	for i in MAX:
		_age[i] = LIFE
	EventBus.grind_tick.connect(_on_grind_tick)
	_me = self


func _exit_tree() -> void:
	if _me == self:
		_me = null


## Cheap flying chips (no physics, no extra draw call): the saw's crumbs.
static func chips(at: Vector2, col: Color, n: int, push: Vector2) -> void:
	if _me == null:
		return
	for k in n:
		var i: int = _me._next
		_me._next = (_me._next + 1) % MAX
		_me._pos[i] = at
		_me._vel[i] = push * 0.3 + Vector2.from_angle(randf_range(-PI, 0.0)) * randf_range(300.0, 700.0)
		_me._age[i] = 0.0
		_me._kind[i] = 1
		_me._col[i] = col
	_me._active = MAX


## Each material throws different bits: metal a shower of hot sparks, glass
## glints, fruit juice drops, electronics blue zaps, plastic chips.
const COUNT := [4, 8, 4, 4, 6, 3, 5]
const CHIPS := [1, 0, 2, 4, 0, 3, 3]    # how many of them are chips/drops, not streaks
var HOT := [ThemePalette.BUTTER, ThemePalette.TANGERINE, ThemePalette.STICKER]
var GLINT := [ThemePalette.STICKER, ThemePalette.MINT, ThemePalette.CREAM]
var JUICE := [ThemePalette.RED, ThemePalette.PINK, ThemePalette.TANGERINE]
var ZAP := [ThemePalette.COBALT, ThemePalette.MINT, ThemePalette.STICKER]
var RUB := [ThemePalette.BUTTER, ThemePalette.TANGERINE, ThemePalette.CREAM]
var CER := [ThemePalette.PINK, ThemePalette.STICKER, ThemePalette.CREAM]


func _on_grind_tick(at: Vector2, mat: int) -> void:
	var cols: Array = [HOT, HOT, GLINT, JUICE, ZAP, RUB, CER][mat]
	for n in int(COUNT[mat]):
		var i := _next
		_next = (_next + 1) % MAX
		var chip: bool = n < CHIPS[mat]
		_pos[i] = at
		var speed := randf_range(500.0, 1100.0) if mat == Materials.METAL else randf_range(350.0, 800.0)
		_vel[i] = Vector2.from_angle(randf_range(-PI, 0.0)) * speed
		_age[i] = 0.0
		_kind[i] = 1 if chip else 0
		_col[i] = ThemePalette.PAINT.pick_random() if chip and mat == Materials.PLASTIC else cols.pick_random()
	_active = MAX


func _process(delta: float) -> void:
	if _active <= 0:
		return
	var alive := 0
	for i in MAX:
		if _age[i] < LIFE:
			_age[i] += delta
			_vel[i] = _vel[i] * exp(-4.0 * delta) + Vector2(0.0, 1400.0 * delta)
			_pos[i] = _pos[i] + _vel[i] * delta
			alive += 1
	_active = alive
	queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	for i in MAX:
		if _age[i] >= LIFE:
			continue
		var k := 1.0 - _age[i] / LIFE
		if _kind[i] == 0:
			g.draw_line(_pos[i] - _vel[i] * 0.025, _pos[i], _col[i], 3.5 * k + 1.0, true)
		else:
			var s := 6.0 * k + 2.0
			g.draw_rect(Rect2(_pos[i] - Vector2(s, s) * 0.5, Vector2(s, s)), _col[i])
	g.flush()
