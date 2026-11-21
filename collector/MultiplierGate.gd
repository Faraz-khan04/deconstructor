class_name MultiplierGate
extends Node2D
## A dotted line that slides side to side above the shredder. Anything
## falling through it has its value multiplied (once per gate). When hit it
## twangs like a guitar string, flashes, and pops a "2X!".

static var all: Array[MultiplierGate] = []

@export var multiplier: int = 2
@export var width: float = 320.0
@export var travel: float = 240.0      # horizontal sway distance (px)
@export var speed: float = 0.6         # sway speed
@export var gate_bit: int = 1          # unique per gate (1, 2, 4...)

var _home_x: float = 0.0
var _t: float = 0.0
var _pulse: float = 0.0
var _wobble: float = 0.0


func _enter_tree() -> void:
	all.append(self)


func _exit_tree() -> void:
	all.erase(self)


func _ready() -> void:
	z_index = 5
	_home_x = position.x
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	position.x = _home_x + sin(_t * speed) * travel
	_pulse = maxf(0.0, _pulse - delta * 4.0)
	_wobble = maxf(0.0, _wobble - delta * 2.5)
	queue_redraw()


## Did the segment a -> b (one physics step of a shard) fall through me?
func crossed(a: Vector2, b: Vector2) -> bool:
	var y := global_position.y
	if not (a.y < y and b.y >= y):
		return false
	var t := (y - a.y) / maxf(b.y - a.y, 0.001)
	return absf(lerpf(a.x, b.x, t) - global_position.x) <= width * 0.5


## Shared check for shards and loose parts moving a -> b this physics step.
## Returns Vector2i(updated gate mask, value factor).
static func check(a: Vector2, b: Vector2, mask: int) -> Vector2i:
	var factor := 1
	for g in all:
		if (mask & g.gate_bit) == 0 and g.crossed(a, b):
			mask |= g.gate_bit
			factor *= g.mult()
			g.on_pass(b)
	return Vector2i(mask, factor)


func on_pass(_at: Vector2) -> void:
	_pulse = 1.0
	_wobble = 1.0
	Sfx.play("gate", 0.8 + 0.12 * mult())     # the gate itself pulses: no popup


## Printed multiplier plus the GATES upgrade.
func mult() -> int:
	return multiplier + Economy.gate_bonus()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var hw := width * 0.5
	var col := _color().lerp(ThemePalette.STICKER, _pulse * 0.6)

	# Soft scan band that flares when shards pass through
	g.draw_rect(Rect2(-hw, -8.0 - _pulse * 10.0, width, 16.0 + _pulse * 20.0),
		ThemePalette.with_alpha(col, 0.08 + 0.2 * _pulse))
	# Dashed line that vibrates like a plucked string (ends stay pinned)
	var x := -hw
	while x < hw:
		var x2 := minf(x + 14.0, hw)
		g.draw_line(Vector2(x, _string_y(x, hw)), Vector2(x2, _string_y(x2, hw)), col,
			6.0 + _pulse * 3.0, true)
		x += 24.0
	for px in [-hw, hw]:
		g.draw_circle(Vector2(px, 0.0), 11.0, ThemePalette.STICKER)
		g.draw_circle(Vector2(px, 0.0), 8.0, col)

	# Bold sticker label: solid colour, white text, swells when hit
	var sw := 1.0 + 0.25 * _pulse
	var label := Rect2(Vector2(-54.0, -62.0) * sw, Vector2(108.0, 48.0) * sw)
	g.draw_rect(Rect2(label.position + Vector2(5, 8), label.size), ThemePalette.SHADOW)
	g.draw_rect(label.grow(5.0), ThemePalette.STICKER)
	g.draw_rect(label, _color().lerp(ThemePalette.STICKER, _pulse * 0.4))
	g.draw_rect(label, ThemePalette.INK, false, 3.0)
	g.draw_string(ThemePalette.display_font, Vector2(label.position.x, label.position.y + 37.0 * sw),
		"x%d" % mult(), HORIZONTAL_ALIGNMENT_CENTER, label.size.x, int(36 * sw), ThemePalette.STICKER)
	g.flush()


func _color() -> Color:
	return ThemePalette.COBALT if multiplier <= 2 else ThemePalette.RED   # by printed size


func _string_y(x: float, hw: float) -> float:
	var pin := sin((x + hw) / (hw * 2.0) * PI)
	return sin(_t * 45.0) * 16.0 * _wobble * pin
