extends CanvasLayer
## End of a RUSH run: cash counts up, stars slam in at their targets,
## best run, then PLAY AGAIN or MENU.

const PANEL := Vector2(900.0, 900.0)

var _view: Control
var _again: Button
var _menu: Button
var _run: int = 0
var _stars: int = 0
var _unit: float = 1.0
var _shown: float = 0.0
var _lit: int = 0
var _slide: float = 1.0


func _ready() -> void:
	layer = 14
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_draw_panel)
	_view.visible = false
	add_child(_view)
	_again = MenuScreen.big_button("PLAY AGAIN", ThemePalette.COBALT)
	_again.pressed.connect(func(): MenuScreen.go("res://rush.tscn"))
	_menu = MenuScreen.big_button("MENU", ThemePalette.STONE)
	_menu.pressed.connect(func(): MenuScreen.go("res://menu.tscn"))
	for b in [_again, _menu]:
		b.visible = false
		add_child(b)


func show_result(run: int, stars: int, unit: float) -> void:
	_run = run
	_stars = stars
	_unit = unit
	_view.visible = true
	var t := _view.create_tween()
	t.tween_property(self, "_slide", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_method(_count, 0.0, float(run), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(_buttons)


## Count the cash up; each star lands as its target is passed.
func _count(v: float) -> void:
	_shown = v
	while _lit < _stars and v >= RushGame.STAR_AT[_lit] * _unit:
		_lit += 1
		Sfx.play("star", 1.0 + _lit * 0.15, 0.0, 0.0)
		EventBus.shake_requested.emit(0.3 + _lit * 0.1)
	if int(v) % 7 == 0:
		Sfx.play("coin", 1.0 + v / maxf(float(_run), 1.0) * 0.8, -4.0, 0.0)


func _buttons() -> void:
	var r := _rect()
	_again.position = Vector2(r.position.x + 60.0, r.end.y - 170.0)
	_again.size = Vector2(470.0, 120.0)
	_menu.position = Vector2(r.position.x + 560.0, r.end.y - 170.0)
	_menu.size = Vector2(280.0, 120.0)
	_again.visible = true
	_menu.visible = true


func _process(_delta: float) -> void:
	if _view.visible:
		_view.queue_redraw()


func _rect() -> Rect2:
	var s := _view.size
	return Rect2((s.x - PANEL.x) * 0.5, s.y * 0.22 + _slide * s.y, PANEL.x, PANEL.y)


func _draw_panel() -> void:
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), ThemePalette.with_alpha(ThemePalette.INK, 0.5))
	var r := _rect()
	var big := ThemePalette.display_font
	_view.draw_rect(Rect2(r.position + Vector2(10, 16), r.size), ThemePalette.SHADOW)
	_view.draw_rect(r.grow(8.0), ThemePalette.STICKER)
	_view.draw_rect(r, ThemePalette.PAPER)
	_view.draw_rect(r, ThemePalette.INK, false, 4.0)
	_view.draw_string(big, r.position + Vector2(0, 120), "RUSH OVER!", HORIZONTAL_ALIGNMENT_CENTER,
		r.size.x, 88, ThemePalette.RED)
	for i in 3:
		var c := r.position + Vector2(r.size.x * (0.25 + 0.25 * i), 280.0 - (24.0 if i == 1 else 0.0))
		MenuScreen.draw_star(_view, c, 86.0 if i == 1 else 72.0, i < _lit)
		_view.draw_string(ThemePalette.mono_font, c + Vector2(-120, 120), NumFmt.money(RushGame.STAR_AT[i] * _unit),
			HORIZONTAL_ALIGNMENT_CENTER, 240.0, 24, ThemePalette.INK_SOFT)
	_view.draw_string(big, r.position + Vector2(0, 560), "+" + NumFmt.money(round(_shown)),
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 110, ThemePalette.TEAL)
	var best := int(Save.data.get("rush_best", 0))
	var note := "NEW BEST!" if _run >= best and _run > 0 else "BEST " + NumFmt.money(best)
	_view.draw_string(big, r.position + Vector2(0, 640), note, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40,
		ThemePalette.TANGERINE if note == "NEW BEST!" else ThemePalette.INK_SOFT)
