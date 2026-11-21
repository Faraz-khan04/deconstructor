extends CanvasLayer
## RUSH screen-space HUD: MENU button, a big shrinking time bar (red and
## shaking in the last 10 s), this run's cash top-right (coins fly there),
## best run under it, and the combo badge.

const TOP := 90.0
const MARGIN := 40.0

var _view: Control
var _pop: float = 0.0
var _shown: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	layer = 10
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_hud)
	add_child(_view)
	var combo := preload("res://ui/ComboBadge.gd").new() as Control
	combo.anchor_left = 0.5
	combo.anchor_right = 0.5
	combo.offset_left = -170.0
	combo.offset_right = 170.0
	combo.offset_top = TOP + 150.0
	combo.offset_bottom = TOP + 220.0
	add_child(combo)
	add_child(MenuScreen.menu_button(Vector2(MARGIN, TOP - 40.0)))
	EventBus.score_added.connect(func(_a: int): _pop = 1.0)


func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(0.0, _pop - delta * 4.0)
	var g := RushGame.cur
	if g:
		_shown = lerpf(_shown, float(g.run), 1.0 - exp(-10.0 * delta))
	_view.queue_redraw()


func _draw_hud() -> void:
	var g := RushGame.cur
	if g == null:
		return
	var w := _view.size.x
	var big := ThemePalette.display_font
	# Run cash, top right (the coins land here)
	var sc := 1.0 + 0.15 * sin(_pop * PI)
	_view.draw_set_transform(Vector2(w - MARGIN, TOP + 74.0), 0.0, Vector2(sc, sc))
	_view.draw_string(big, Vector2(-600.0, 28.0), NumFmt.money(round(_shown)), HORIZONTAL_ALIGNMENT_RIGHT,
		600.0, 80, ThemePalette.INK)
	_view.draw_set_transform(Vector2.ZERO)
	_view.draw_string(ThemePalette.mono_font, Vector2(w - MARGIN - 400.0, TOP + 140.0),
		"BEST " + NumFmt.money(int(Save.data.get("rush_best", 0))), HORIZONTAL_ALIGNMENT_RIGHT, 400.0,
		24, ThemePalette.INK_SOFT)
	# Time bar under the top row
	var k := clampf(g.time_left / RushGame.DURATION, 0.0, 1.0)
	var hurry := g.time_left <= RushGame.FINAL
	var shake := Vector2(randf_range(-3, 3), randf_range(-2, 2)) if hurry and g.running else Vector2.ZERO
	var bar := Rect2(Vector2(MARGIN + 220.0, TOP + 10.0) + shake, Vector2(w - MARGIN * 2.0 - 220.0 - 360.0, 44.0))
	_view.draw_rect(Rect2(bar.position + Vector2(4, 7), bar.size), ThemePalette.SHADOW)
	_view.draw_rect(bar.grow(5.0), ThemePalette.STICKER)
	_view.draw_rect(bar, ThemePalette.STONE)
	var fill := ThemePalette.RED if hurry else ThemePalette.COBALT
	_view.draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), fill)
	_view.draw_rect(bar, ThemePalette.INK, false, 3.0)
	_view.draw_string(big, Vector2(bar.position.x, bar.position.y + 36.0), "%d" % int(ceil(g.time_left)),
		HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 34, ThemePalette.STICKER if k > 0.5 else ThemePalette.INK)
