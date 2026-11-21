class_name PinField
extends Node2D
## The board under the cutting area (pachinko style): slanted funnel walls
## steer everything that falls toward the middle, through a dense grid of
## rubber pegs, then the sliding gates and the shredder. The saw stays above
## BOARD_TOP, so the board is a stage you watch, not a second cutting zone.
## GOLD PEGS upgrade: gold pegs double a shard's value (once per shard).
## Only shards use the board; loose parts fall through it so nothing jams.

const BOARD_TOP := 1400.0
const PIN_R := 20.0
const ROWS := [[0.2, 0.4, 0.6, 0.8], [0.3, 0.5, 0.7], [0.2, 0.4, 0.6, 0.8], [0.3, 0.5, 0.7]]
const ROW_Y := [1480.0, 1560.0, 1640.0, 1720.0]
## Which pegs turn gold first (centre outwards), as indices into the grid.
const GOLD_ORDER := [8, 1, 2, 5, 9, 4, 6, 12, 0, 3, 10, 11, 7, 13]
## Funnel walls: [from, to] as (x fraction, y). Mirrored on the right.
const FUNNELS := [[Vector2(-0.02, 1385.0), Vector2(0.10, 1462.0)],
	[Vector2(-0.02, 1745.0), Vector2(0.11, 1805.0)]]
const WALL_T := 26.0

static var _instance: PinField = null

var _pins := PackedVector2Array()
var _flash := PackedFloat32Array()
var _gold_count: int = 0
var _walls: Array = []             # [a, b] world points, for drawing
var _dirty: bool = true


func _ready() -> void:
	_instance = self
	z_index = 4
	var w := get_viewport_rect().size.x
	var body := StaticBody2D.new()
	body.collision_layer = 16         # "pegs": only shards bounce here; big loose
	                                  # parts drop straight through (no clogging)
	body.collision_mask = 0
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.5
	mat.friction = 0.15
	body.physics_material_override = mat
	for r in ROWS.size():
		for fx in ROWS[r]:
			var p := Vector2(w * fx, ROW_Y[r])
			_pins.append(p)
			_flash.append(0.0)
			var shape := CircleShape2D.new()
			shape.radius = PIN_R
			_add_shape(body, shape, Transform2D(0.0, p))
	for f in FUNNELS:
		for side in [1.0, -1.0]:
			var a := Vector2(w * (0.5 - (0.5 - f[0].x) * side), f[0].y)
			var b := Vector2(w * (0.5 - (0.5 - f[1].x) * side), f[1].y)
			_walls.append([a, b])
			var rect := RectangleShape2D.new()
			rect.size = Vector2(a.distance_to(b), WALL_T)
			_add_shape(body, rect, Transform2D((b - a).angle(), (a + b) * 0.5))
	add_child(body)
	EventBus.upgrades_changed.connect(func(): _gold_count = Economy.gold_pegs(); _dirty = true)


func _add_shape(body: StaticBody2D, shape: Shape2D, xf: Transform2D) -> void:
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.transform = xf
	body.add_child(cs)


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


func _is_gold(i: int) -> bool:
	var rank := GOLD_ORDER.find(i)
	return rank >= 0 and rank < _gold_count


## Called by moving pieces: lights up pegs they touch. True if one was gold.
static func touch(at: Vector2, reach: float) -> bool:
	if _instance == null or at.y < ROW_Y[0] - 80.0 or at.y > ROW_Y[-1] + 80.0:
		return false
	var limit := (PIN_R + reach) * (PIN_R + reach)
	var gold := false
	for i in _instance._pins.size():
		if at.distance_squared_to(_instance._pins[i]) < limit:
			if _instance._flash[i] < 0.4:
				_instance._flash[i] = 1.0
				EventBus.peg_hit.emit(i)
			gold = gold or _instance._is_gold(i)
	return gold


func _process(delta: float) -> void:
	var lit := false                   # only redraw while a peg is still flashing
	for i in _flash.size():
		if _flash[i] > 0.0:
			_flash[i] = maxf(0.0, _flash[i] - delta * 4.0)
			lit = true
	if lit or _dirty:
		_dirty = lit
		queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	for wl in _walls:
		var a: Vector2 = wl[0]
		var b: Vector2 = wl[1]
		g.draw_line(a + Vector2(5, 9), b + Vector2(5, 9), ThemePalette.SHADOW, WALL_T + 10.0)
		g.draw_line(a, b, ThemePalette.STICKER, WALL_T + 10.0)
		g.draw_line(a, b, ThemePalette.TEAL, WALL_T)
		g.draw_circle(b, WALL_T * 0.5 + 5.0, ThemePalette.STICKER)
		g.draw_circle(b, WALL_T * 0.5, ThemePalette.TEAL)
	for i in _pins.size():
		var p := _pins[i]
		var f := _flash[i]
		var gold := _is_gold(i)
		var r := PIN_R * (1.0 + 0.3 * f)
		var col := ThemePalette.BUTTER if gold else ThemePalette.PINK
		g.draw_circle(p + Vector2(4, 7), r + 5.0, ThemePalette.SHADOW)
		g.draw_circle(p, r + 5.0, ThemePalette.TANGERINE if gold and f > 0.5 else ThemePalette.STICKER)
		g.draw_circle(p, r, col.lerp(ThemePalette.STICKER, f * 0.7))
		g.draw_arc(p, r, 0.0, TAU, 28, ThemePalette.INK, 3.0, true)
		if gold:
			g.draw_string(ThemePalette.display_font, p + Vector2(-r, 7.0), "x2",
				HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 17, ThemePalette.INK)
		else:
			g.draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.6))
	g.flush()
