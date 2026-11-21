extends Node2D
## Die-cut sticker buzzsaw in retro-hardware colours: cream body, ink outline,
## cobalt dial ring with ticks, red pad slots, butter hub, white sticker border.
## The blade rotates the node. v14: drawn ONCE; the thickness is a child
## layer behind it that only slides each frame (so it stays underneath). A second instance with
## shadow_only = true sits underneath as the soft drop shadow.

const BORDER := 11.0  # sticker border thickness in px

@export var radius: float = 70.0:
	set(value):
		radius = value
		queue_redraw()

@export_range(6, 32) var teeth: int = 14:
	set(value):
		teeth = value
		queue_redraw()

@export var shadow_only: bool = false:
	set(value):
		shadow_only = value
		queue_redraw()

@export_range(0.05, 0.5) var tooth_depth: float = 0.2
const THICK := Vector2(2.0, 6.0)
var _thick: Node2D
var _cache_r: float = -1.0
var _body := PackedVector2Array()
var _stick := PackedVector2Array()
@export_range(0.1, 0.8) var hook: float = 0.3


func _draw() -> void:
	if _cache_r != radius:              # outline maths only when the size changes
		_cache_r = radius
		_body = _saw_points()
		_stick = _grow(_body, BORDER)
	var body := _body
	var sticker := _stick
	var g := Batch.new(self)          # v14: whole saw = one draw call

	if shadow_only:
		g.draw_colored_polygon(sticker, ThemePalette.SHADOW)
		g.flush()
		return

	_build_thick(sticker)               # the darker copy just below
	# White die-cut border with a faint edge
	g.draw_colored_polygon(sticker, ThemePalette.STICKER)
	_outline(g, sticker, ThemePalette.with_alpha(ThemePalette.INK, 0.10), 2.0)

	# Cream body, ink outline
	g.draw_colored_polygon(body, ThemePalette.CREAM)
	_outline(g, body, ThemePalette.INK, 4.0)

	# Dial ticks + cobalt ring
	for i in 24:
		var d := Vector2.from_angle(TAU * i / 24.0)
		g.draw_line(d * radius * 0.67, d * radius * 0.74, ThemePalette.INK_SOFT, 2.0, true)
	g.draw_arc(Vector2.ZERO, radius * 0.58, 0.0, TAU, 48, ThemePalette.COBALT, 9.0, true)

	# Three red slots with rounded ends (reads the spin at high RPM)
	for i in 3:
		var d := Vector2.from_angle(TAU * i / 3.0 + 0.5)
		var a := d * radius * 0.26
		var b := d * radius * 0.45
		g.draw_line(a, b, ThemePalette.RED, 9.0, true)
		g.draw_circle(a, 4.5, ThemePalette.RED)
		g.draw_circle(b, 4.5, ThemePalette.RED)

	# Hub
	g.draw_circle(Vector2.ZERO, radius * 0.2, ThemePalette.INK)
	g.draw_circle(Vector2.ZERO, radius * 0.12, ThemePalette.BUTTER)
	g.draw_circle(Vector2.ZERO, radius * 0.04, ThemePalette.INK)
	g.flush()


func _saw_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var step := TAU / teeth
	var inner := radius * (1.0 - tooth_depth)
	for i in teeth:
		var a := i * step
		pts.append(Vector2.from_angle(a) * inner)                                # gullet
		pts.append(Vector2.from_angle(a + step * hook) * radius)                 # tip
		pts.append(Vector2.from_angle(a + step * (hook + 0.12)) * radius * 0.94) # back
	return pts


## Inflate a polygon outward with round joins. Works regardless of winding.
func _grow(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var out: PackedVector2Array = Geometry2D.offset_polygon(pts, amount, Geometry2D.JOIN_ROUND)[0]
	if _max_len(out) < radius:  # winding was reversed -> it shrank instead
		out = Geometry2D.offset_polygon(pts, -amount, Geometry2D.JOIN_ROUND)[0]
	return out


func _max_len(pts: PackedVector2Array) -> float:
	var m := 0.0
	for p in pts:
		m = maxf(m, p.length())
	return m


func _outline(g: Batch, pts: PackedVector2Array, col: Color, w: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	g.draw_polyline(closed, col, w, true)


func _process(_delta: float) -> void:
	if _thick:
		_thick.position = THICK.rotated(-rotation)   # always points down on screen


## The saw's thickness: a darker copy on its own layer behind the saw.
func _build_thick(sticker: PackedVector2Array) -> void:
	if _thick == null:
		_thick = Node2D.new()
		_thick.show_behind_parent = true
		add_child(_thick)
	RenderingServer.canvas_item_clear(_thick.get_canvas_item())
	var t := Batch.new(_thick)
	t.draw_colored_polygon(sticker, Color(0.62, 0.6, 0.56))
	_outline(t, sticker, ThemePalette.with_alpha(ThemePalette.INK, 0.5), 2.0)
	t.flush()
