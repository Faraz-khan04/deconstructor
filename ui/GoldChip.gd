extends Control
## HUD chip (top right, under the level): "GOLD" + three coin slots that fill
## with every golden part you free. Three = FRENZY. During a frenzy the chip
## turns red and shows the time left.

const W := 250.0
const H := 58.0

var _count: int = 0
var _pop: float = 0.0
var _frenzy: bool = false
var _frenzy_left: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count = int(Save.data.get("gold_meter", 0))
	EventBus.gold_meter_changed.connect(_on_meter)
	EventBus.frenzy_changed.connect(_on_frenzy)


func _on_meter(count: int) -> void:
	_count = count
	_pop = 1.0


func _on_frenzy(active: bool) -> void:
	_frenzy = active
	_frenzy_left = Frenzy.DURATION if active else 0.0
	_pop = 1.0


func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(0.0, _pop - delta * 3.0)
	if _frenzy:
		_frenzy_left = maxf(0.0, _frenzy_left - delta)
	queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var sc := 1.0 + 0.25 * sin(_pop * PI)
	g.draw_set_transform(Vector2(size.x - W * 0.5, H * 0.5), sin(_pop * 10.0) * 0.08 * _pop,
		Vector2(sc, sc))
	var r := Rect2(-W * 0.5, -H * 0.5, W, H)
	var fill := ThemePalette.RED if _frenzy else ThemePalette.STICKER
	g.draw_rect(Rect2(r.position + Vector2(4, 7), r.size), ThemePalette.SHADOW)
	g.draw_rect(r.grow(5.0), ThemePalette.STICKER)
	g.draw_rect(r, fill)
	g.draw_rect(r, ThemePalette.INK, false, 3.0)
	if _frenzy:
		var k := _frenzy_left / Frenzy.DURATION
		g.draw_rect(Rect2(r.position + Vector2(8, H - 14), Vector2((W - 16.0) * k, 8)), ThemePalette.BUTTER)
		g.draw_string(ThemePalette.display_font, Vector2(r.position.x, 12.0), "FRENZY!",
			HORIZONTAL_ALIGNMENT_CENTER, W, 34, ThemePalette.STICKER)
	else:
		g.draw_string(ThemePalette.display_font, Vector2(r.position.x + 18.0, 12.0), "GOLD",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, ThemePalette.INK)
		for i in 3:
			var c := Vector2(r.position.x + 140.0 + i * 38.0, 0.0)
			var lit := i < _count
			g.draw_circle(c, 15.0, ThemePalette.BUTTER if lit else ThemePalette.CREAM)
			g.draw_arc(c, 15.0, 0.0, TAU, 20, ThemePalette.INK, 3.0, true)
			if lit:
				g.draw_circle(c + Vector2(-5, -5), 4.0, Color(1, 1, 1, 0.7))
	g.draw_set_transform(Vector2.ZERO)
	if not _frenzy:
		g.draw_string(ThemePalette.mono_font, Vector2(0.0, H + 30.0), "3 GOLD = FRENZY",
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4.0, 20, ThemePalette.INK)
	g.flush()
