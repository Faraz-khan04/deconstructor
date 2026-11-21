class_name Catcher
extends Node2D
## A bucket at the bottom. Pieces that land in it pay xMULT (+1 per BUCKET
## upgrade). Two kinds:
##   steer = true  (JOBS): your second thumb slides it under the falling
##       pieces; misses still reach the shredder at normal pay. Keep the
##       lithium batteries OUT of it.
##   steer = false (RUSH): fixed bins in the corners; aim your swipes at them.
##       Misses are lost.
## Untouched, a steerable bucket drifts slowly toward the next falling piece.

@export var steer: bool = true
@export var line_y: float = 1930.0
@export var width: float = 300.0
@export var miss_lost: bool = false

const BASE_MULT := 3
const DRIFT := 420.0
const ZONE := 0.72                     # bottom part of the screen steers it
const BOTTOM_KEEP := 270.0             # ...but not the upgrade buttons below

static var all: Array[Catcher] = []

var _touch: int = -1
var _target_x: float = 540.0
var _pop: float = 0.0
var _streak: int = 0
var _streak_t: float = 0.0


func _enter_tree() -> void:
	all.append(self)


func _exit_tree() -> void:
	all.erase(self)


func _ready() -> void:
	z_index = 6
	position.y = line_y
	_target_x = position.x


static func mult() -> int:
	return BASE_MULT + Economy.gate_bonus()


static func owns_screen_point(from: Node, p: Vector2) -> bool:
	var h := from.get_viewport().get_visible_rect().size.y
	for c in all:
		if c.steer and p.y > h * ZONE and p.y < h - (BOTTOM_KEEP if not c.miss_lost else 0.0):
			return true
	return false


## For a shard moving a -> b: -1 = carry on, 0 = missed (lost), else multiplier.
static func check(a: Vector2, b: Vector2) -> int:
	var missed := false
	for c in all:
		if a.y < c.line_y and b.y >= c.line_y:
			if c._inside(a, b):
				c._caught()
				return mult()
			missed = missed or c.miss_lost
	return 0 if missed else -1


## A whole loose part falling in: paid straight away (a battery explodes).
static func catch_block(b: Block, a: Vector2, p: Vector2) -> bool:
	for c in all:
		if a.y < c.line_y and p.y >= c.line_y and c._inside(a, p):
			c._caught()
			b.set_meta("caught", true)
			if not b.hazard:
				EventBus.score_added.emit(int(round(b.value * mult() * Economy.value_mult())))
				EventBus.fragment_collected.emit(p, b.color, 0)
			b.state = Block.State.DEAD
			b.destroyed.emit(b, false)
			b.queue_free()
			return true
	return false


func _inside(a: Vector2, b: Vector2) -> bool:
	var t := (line_y - a.y) / maxf(b.y - a.y, 0.001)
	return absf(lerpf(a.x, b.x, t) - global_position.x) <= width * 0.5


func _caught() -> void:
	_pop = 1.0
	_streak += 1
	_streak_t = 0.6
	Sfx.play("catch", 1.0 + minf(_streak * 0.03, 0.6), 0.0, 0.02)


func _input(event: InputEvent) -> void:
	if not steer:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and owns_screen_point(self, event.position):
			_touch = event.index
			_target_x = ScreenSpace.to_world(self, event.position).x
		elif not event.pressed and event.index == _touch:
			_touch = -1
	elif event is InputEventScreenDrag and event.index == _touch:
		_target_x = ScreenSpace.to_world(self, event.position).x


func _process(delta: float) -> void:
	_pop = maxf(0.0, _pop - delta * 4.0)
	_streak_t -= delta
	if _streak_t <= 0.0:
		_streak = 0
	if steer:
		var x := position.x
		if _touch != -1:
			x = lerpf(x, _target_x, 1.0 - exp(-25.0 * delta))
		else:
			x = move_toward(x, _drift_goal(), DRIFT * delta)
		position.x = clampf(x, width * 0.5, 1080.0 - width * 0.5)
	queue_redraw()


## The lowest falling shard above the line (the next one to land).
func _drift_goal() -> float:
	var best := position.x
	var best_y := -INF
	var pool := get_parent().get_node_or_null("FragmentPool")
	if pool == null:
		return best
	for f in pool.get_children():
		if f.active and f.global_position.y < line_y and f.global_position.y > best_y:
			best_y = f.global_position.y
			best = f.global_position.x
	return best


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var s := 1.0 + 0.12 * sin(_pop * PI)
	g.draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, 2.0 - s))
	var hw := width * 0.5
	var body := PackedVector2Array([Vector2(-hw, -10), Vector2(hw, -10),
		Vector2(hw - 36, 110), Vector2(-hw + 36, 110)])
	var shadow := PackedVector2Array()
	for p in body:
		shadow.append(p + Vector2(7, 11))
	g.draw_colored_polygon(shadow, ThemePalette.SHADOW)
	g.draw_colored_polygon(ShapeUtil.grow(body, 7.0), ThemePalette.STICKER)
	g.draw_colored_polygon(body, ThemePalette.COBALT.lerp(ThemePalette.BUTTER, _pop * 0.6))
	body.append(body[0])
	g.draw_polyline(body, ThemePalette.INK, 4.0, true)
	g.draw_line(Vector2(-hw - 10, -10), Vector2(hw + 10, -10), ThemePalette.INK, 10.0, true)
	g.draw_string(ThemePalette.display_font, Vector2(-hw, 72), "x%d" % mult(), HORIZONTAL_ALIGNMENT_CENTER,
		width, 56, ThemePalette.STICKER)
	g.draw_set_transform(Vector2.ZERO)
	if steer and _touch == -1:
		g.draw_string(ThemePalette.mono_font, Vector2(-hw, 150), "SLIDE WITH YOUR OTHER THUMB",
			HORIZONTAL_ALIGNMENT_CENTER, width, 16, ThemePalette.INK_SOFT)
	g.flush()
