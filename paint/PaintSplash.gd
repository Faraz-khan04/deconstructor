class_name PaintSplash
extends Node2D
## One animated paint splash, drawn inside the paint canvas (which never clears,
## so flying drops leave streaks and drips leave runs). SplashRecipes decides
## the shape via add_blob / add_drop / add_speck / add_drip. Pooled.

const MAX_BLOBS := 3
const MAX_DROPS := 24
const MAX_SPECKS := 48
const MAX_DRIPS := 6
const BLOB_POINTS := 22
const BLOB_TIME := 0.11

# --- Set per splash by SplashRecipes --------------------------------------
var dir: Vector2 = Vector2.RIGHT
var color: Color
var accent: Color
var life_total: float = 0.5
var gravity: float = 0.0
var drag: float = 5.0
var gloss: bool = true

# --- Storage ----------------------------------------------------------------
var _blobs: int = 0
var _blob_c := PackedVector2Array()
var _blob_r := PackedFloat32Array()
var _blob_acc := PackedByteArray()
var _blob_shape: Array[PackedVector2Array] = []
var _scaled := PackedVector2Array()

var _drops: int = 0
var _pos := PackedVector2Array()
var _prev := PackedVector2Array()
var _vel := PackedVector2Array()
var _rad := PackedFloat32Array()
var _life := PackedFloat32Array()
var _land := PackedByteArray()
var _landed := PackedByteArray()
var _drop_acc := PackedByteArray()

var _specks: int = 0
var _speck_pos := PackedVector2Array()
var _speck_rad := PackedFloat32Array()
var _speck_acc := PackedByteArray()

var _drips: int = 0
var _drip_start := PackedVector2Array()
var _drip_len := PackedFloat32Array()
var _drip_w := PackedFloat32Array()
var _drip_time := PackedFloat32Array()

var _t: float = 0.0


func _ready() -> void:
	_blob_c.resize(MAX_BLOBS); _blob_r.resize(MAX_BLOBS); _blob_acc.resize(MAX_BLOBS)
	for i in MAX_BLOBS:
		_blob_shape.append(PackedVector2Array())
	_scaled.resize(BLOB_POINTS)
	_pos.resize(MAX_DROPS); _prev.resize(MAX_DROPS); _vel.resize(MAX_DROPS)
	_rad.resize(MAX_DROPS); _life.resize(MAX_DROPS)
	_land.resize(MAX_DROPS); _landed.resize(MAX_DROPS); _drop_acc.resize(MAX_DROPS)
	_speck_pos.resize(MAX_SPECKS); _speck_rad.resize(MAX_SPECKS); _speck_acc.resize(MAX_SPECKS)
	_drip_start.resize(MAX_DRIPS); _drip_len.resize(MAX_DRIPS)
	_drip_w.resize(MAX_DRIPS); _drip_time.resize(MAX_DRIPS)
	visible = false
	set_process(false)


func play(at: Vector2, direction: Vector2, strength: float,
		main_col: Color, accent_col: Color, style: int) -> void:
	position = at
	color = main_col
	accent = accent_col
	dir = direction.normalized() if direction.length() > 1.0 else Vector2.from_angle(randf() * TAU)
	life_total = 0.5
	gravity = 0.0
	drag = 5.0
	gloss = true
	_blobs = 0; _drops = 0; _specks = 0; _drips = 0
	_t = 0.0

	SplashRecipes.build(self, style, clampf(strength, 0.2, 1.0))

	visible = true
	set_process(true)
	queue_redraw()


# --- Builder API (called by SplashRecipes) ---------------------------------

func add_blob(center: Vector2, r: float, stretch: float, use_accent: bool) -> void:
	if _blobs >= MAX_BLOBS:
		return
	var i := _blobs
	_blob_c[i] = center; _blob_r[i] = r; _blob_acc[i] = int(use_accent)
	_blob_shape[i] = _make_shape(stretch)
	_blobs += 1


func add_drop(at: Vector2, vel: Vector2, r: float, life: float,
		lands: bool, use_accent: bool) -> void:
	if _drops >= MAX_DROPS:
		return
	var i := _drops
	_pos[i] = at; _prev[i] = at; _vel[i] = vel; _rad[i] = r; _life[i] = life
	_land[i] = int(lands); _landed[i] = 0; _drop_acc[i] = int(use_accent)
	_drops += 1


func add_speck(at: Vector2, r: float, use_accent: bool) -> void:
	if _specks >= MAX_SPECKS:
		return
	_speck_pos[_specks] = at; _speck_rad[_specks] = r; _speck_acc[_specks] = int(use_accent)
	_specks += 1


func add_drip(start: Vector2, length: float, width: float, time: float) -> void:
	if _drips >= MAX_DRIPS:
		return
	var i := _drips
	_drip_start[i] = start; _drip_len[i] = length; _drip_w[i] = width; _drip_time[i] = time
	life_total = maxf(life_total, time + 0.05)
	_drips += 1


# --- Simulation & drawing ----------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	var damp := exp(-drag * delta)
	for i in _drops:
		_prev[i] = _pos[i]
		if _t < _life[i]:
			_vel[i] = (_vel[i] + Vector2(0.0, gravity * delta)) * damp
			_pos[i] = _pos[i] + _vel[i] * delta
	if _t > life_total:
		visible = false      # stop drawing; the pixels stay on the canvas
		set_process(false)
		return
	queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)     # v14: whole splash = one draw call
	var k := clampf(_t / BLOB_TIME, 0.0, 1.0)
	k = 1.0 - pow(1.0 - k, 3.0)
	if k > 0.05:
		for i in _blobs:
			var c := accent if _blob_acc[i] else color
			_draw_blob(g, i, _blob_r[i] * k, c, Vector2.ZERO)
			if gloss and i == 0 and k > 0.6:  # glossy juice highlight
				_draw_blob(g, i, _blob_r[i] * k * 0.45, c.lightened(0.25), -dir * _blob_r[i] * 0.2)
	for i in _drops:
		var c := accent if _drop_acc[i] else color
		var lk := _t / _life[i]
		if lk < 1.0:
			var r := _rad[i] * (1.0 - lk * 0.6)
			g.draw_line(_prev[i], _pos[i], c, r * 1.9, true)
			g.draw_circle(_pos[i], r, c)
		elif _land[i] == 1 and _landed[i] == 0:
			_landed[i] = 1
			g.draw_circle(_pos[i], _rad[i] * 0.85, c)

	for i in _drips:
		var p := clampf(_t / _drip_time[i], 0.0, 1.0)
		p = 1.0 - pow(1.0 - p, 2.0)
		var end := _drip_start[i] + Vector2(0.0, _drip_len[i] * p)
		g.draw_line(_drip_start[i], end, color, _drip_w[i], true)
		g.draw_circle(end, _drip_w[i] * 0.75, color)   # bulb at the tip

	if _t < 0.05:
		for i in _specks:
			g.draw_circle(_speck_pos[i], _speck_rad[i], accent if _speck_acc[i] else color)
	g.flush()


func _draw_blob(g: Batch, i: int, r: float, c: Color, offset: Vector2) -> void:
	var shape := _blob_shape[i]
	for j in BLOB_POINTS:
		_scaled[j] = _blob_c[i] + offset + shape[j] * r
	g.draw_colored_polygon(_scaled, c)


## Irregular unit blob, optionally stretched along the splash direction.
func _make_shape(stretch: float) -> PackedVector2Array:
	var shape := PackedVector2Array()
	shape.resize(BLOB_POINTS)
	var p1 := randf() * TAU
	var p2 := randf() * TAU
	var k1 := randi_range(2, 5)
	var k2 := randi_range(6, 9)
	var ang := dir.angle()
	for i in BLOB_POINTS:
		var a := TAU * i / BLOB_POINTS
		var r := 1.0 + 0.22 * sin(k1 * a + p1) + 0.1 * sin(k2 * a + p2) + randf_range(-0.06, 0.06)
		var v := Vector2.from_angle(a) * r
		shape[i] = Vector2(v.x * stretch, v.y).rotated(ang)
	return shape
