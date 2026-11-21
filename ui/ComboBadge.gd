extends Control
## One combo counter under the progress squares ("COMBO x12") instead of a
## new popup every few breaks. Pops on each break, grows a little with the
## combo, and shrinks away when the chain ends.

var _count: int = 0
var _pop: float = 0.0
var _show: float = 0.0            # 0 hidden .. 1 fully shown


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.combo_changed.connect(_on_combo)


func _on_combo(count: int) -> void:
	if count > _count:
		_pop = 1.0
	_count = count


func _process(delta: float) -> void:
	var target := 1.0 if _count >= 2 else 0.0
	_show = move_toward(_show, target, delta * 6.0)
	_pop = maxf(0.0, _pop - delta * 5.0)
	queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	if _show <= 0.01:
		g.flush()
		return
	var grow := 1.0 + minf(_count * 0.012, 0.35) + 0.18 * sin(_pop * PI)
	var s := _show * grow
	var c := size * 0.5
	g.draw_set_transform(c, sin(_pop * 9.0) * 0.06 * _pop, Vector2(s, s))
	var r := Rect2(-120.0, -30.0, 240.0, 60.0)
	g.draw_rect(Rect2(r.position + Vector2(4, 7), r.size), ThemePalette.SHADOW)
	g.draw_rect(r.grow(5.0), ThemePalette.STICKER)
	g.draw_rect(r, ThemePalette.RED if _count >= 10 else ThemePalette.TANGERINE)
	g.draw_rect(r, ThemePalette.INK, false, 3.0)
	g.draw_string(ThemePalette.display_font, Vector2(r.position.x, 14.0), "COMBO x%d" % _count,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 34, ThemePalette.STICKER)
	g.draw_set_transform(Vector2.ZERO)
	g.flush()
