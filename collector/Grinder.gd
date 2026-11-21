class_name Grinder
extends Node2D
## "SHREDDER": the sticker shredder along the bottom of the page.
## Shards that fall past INTAKE_Y are eaten (Fragment does the check) and
## turned into cash. Interlocking roller teeth spin faster with every bite,
## the LED flashes the shard's colour, and a running "+$" tally cascades up
## while shards keep pouring in, then banks after a short pause.
## Also builds the invisible side walls that keep shards on screen.

const INTAKE_Y := 2020.0
const PANEL_H := 150.0
const TALLY_HOLD := 0.6

var _spin: float = 0.0
var _kick: float = 0.0
var _led: float = 0.0
var _led_color: Color = ThemePalette.STONE
var _tally: int = 0
var _tally_timer: float = 0.0
var _tally_pop: float = 0.0


func _ready() -> void:
	z_index = 20
	position = Vector2(0.0, INTAKE_Y)
	_build_walls()
	EventBus.fragment_collected.connect(_on_collected)
	EventBus.grind_tick.connect(_on_grind_tick)


func _process(delta: float) -> void:
	_spin += delta * (2.5 + _kick * 12.0)
	_kick = maxf(0.0, _kick - delta * 2.5)
	_led = maxf(0.0, _led - delta * 4.0)
	_tally_pop = maxf(0.0, _tally_pop - delta * 5.0)
	if _tally > 0:
		_tally_timer -= delta
		if _tally_timer <= 0.0:
			_tally = 0
	queue_redraw()


func _on_grind_tick(at: Vector2, _mat: int) -> void:
	if at.y > INTAKE_Y - 60.0:
		_kick = minf(1.0, _kick + 0.35)


func _on_collected(_pos: Vector2, color: Color, amount: int) -> void:
	_kick = minf(1.0, _kick + 0.2)
	_led = 1.0
	_led_color = color
	_tally += amount
	_tally_timer = TALLY_HOLD
	_tally_pop = 1.0
	JuiceManager.buzz(5, 0.15)


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var w := get_viewport_rect().size.x
	var jig := Vector2(0.0, sin(_spin * 9.0) * _kick * 3.0)
	g.draw_set_transform(jig)

	var panel := Rect2(24.0, 0.0, w - 48.0, PANEL_H)
	g.draw_rect(Rect2(panel.position + Vector2(6, 9), panel.size), ThemePalette.SHADOW)
	g.draw_rect(panel.grow(6.0), ThemePalette.STICKER)
	g.draw_rect(panel, ThemePalette.CREAM)
	g.draw_rect(panel, ThemePalette.INK, false, 3.0)

	# Intake slot with two rows of counter-rotating cutter wheels
	var slot := Rect2(60.0, 16.0, w - 120.0, 54.0)
	g.draw_rect(slot, ThemePalette.CHARCOAL)
	var x := slot.position.x + 22.0
	var i := 0
	var teeth := PackedVector2Array()
	while x < slot.end.x - 10.0:          # all cutter teeth in ONE line batch (cheap)
		_cutter(teeth, Vector2(x, 32.0), _spin * (1.0 if i % 2 == 0 else -1.0))
		_cutter(teeth, Vector2(x + 23.0, 54.0), -_spin * (1.0 if i % 2 == 0 else -1.0))
		x += 46.0
		i += 1
	g.draw_multiline(teeth, ThemePalette.STONE, 4.0)
	g.draw_rect(slot, ThemePalette.INK, false, 3.0)

	# Label, LED, running tally
	g.draw_string(ThemePalette.mono_font, Vector2(60.0, 112.0), "SHREDDER",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ThemePalette.INK)
	g.draw_string(ThemePalette.mono_font, Vector2(60.0, 136.0), "Pieces in = coins",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ThemePalette.INK_SOFT)
	var led_pos := Vector2(w - 92.0, 108.0)
	g.draw_circle(led_pos, 15.0, ThemePalette.INK)
	g.draw_circle(led_pos, 11.0, ThemePalette.STONE.lerp(_led_color, _led))
	if _tally > 0:
		var size := int(52.0 + _tally_pop * 18.0)
		g.draw_string(ThemePalette.display_font, Vector2(w - 470.0, 130.0), "+" + NumFmt.money(_tally),
			HORIZONTAL_ALIGNMENT_RIGHT, 340.0, size, ThemePalette.COBALT)
	g.draw_set_transform(Vector2.ZERO)


## A cutter wheel = 3 straight blades through the hub (the slot behind is dark).
	g.flush()
func _cutter(out: PackedVector2Array, c: Vector2, angle: float) -> void:
	for k in 3:
		var d := Vector2.from_angle(angle + PI * k / 3.0) * 16.0
		out.append_array([c - d, c + d])


## Invisible side walls so shards and loose parts can't leave the screen.
func _build_walls() -> void:
	var w := get_viewport_rect().size.x
	var body := StaticBody2D.new()
	body.collision_layer = 8   # "walls"
	body.collision_mask = 0
	for x in [-40.0, w + 40.0]:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(80.0, 6000.0)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(x, -INTAKE_Y)
		body.add_child(cs)
	add_child(body)
