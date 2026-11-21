extends CanvasLayer
## End of a job: the three goals, stars slamming in one by one (each with a
## thump and a chime), the pay counting up, then NEXT JOB or RETRY.
## Time's up: TRY AGAIN, with a tip. Blocks touches to the game underneath.

const PANEL_W := 900.0
const PANEL_H := 980.0

var _view: Control
var _next_btn: Button
var _retry_btn: Button
var _won: bool = false
var _stars: int = 0
var _lit: int = 0                 # stars landed so far
var _slide: float = 1.0           # 1 = below the screen, 0 = in place
var _dim: float = 0.0
var _shown_pay: float = 0.0
var _pops := [0.0, 0.0, 0.0]


func _ready() -> void:
	layer = 14
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP      # swallow touches while shown
	_view.draw.connect(_draw_panel)
	add_child(_view)
	_next_btn = _button("NEXT JOB", ThemePalette.COBALT, func(): _choose(false))
	_retry_btn = _button("RETRY", ThemePalette.STONE, func(): _choose(true))
	_hide()
	EventBus.job_finished.connect(_on_finished)
	EventBus.job_next.connect(func(_r: bool): _hide())


func _hide() -> void:
	_view.visible = false
	_next_btn.visible = false
	_retry_btn.visible = false


func _on_finished(won: bool, stars: int) -> void:
	_won = won
	_stars = stars
	_lit = 0
	_pops = [0.0, 0.0, 0.0]
	_shown_pay = 0.0
	_view.visible = true
	_slide = 1.0
	_dim = 0.0
	var t := _view.create_tween()
	t.set_parallel(true)
	t.tween_property(self, "_dim", 1.0, 0.3)
	t.tween_property(self, "_slide", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_interval(0.25)
	for i in stars:
		t.chain().tween_callback(_land_star.bind(i))
		t.chain().tween_interval(0.42)
	if won:
		t.chain().tween_method(func(v: float): _shown_pay = v, 0.0, float(Job.cur.pay), 0.6)
		t.chain().tween_callback(func(): EventBus.score_added.emit(Job.cur.pay))
	t.chain().tween_callback(_show_buttons)


func _land_star(i: int) -> void:
	_lit = i + 1
	_pops[i] = 1.0
	Sfx.play("star", 1.0 + i * 0.15, 0.0, 0.0)
	EventBus.shake_requested.emit(0.35 + i * 0.1)
	JuiceManager.buzz(40, 0.8)


func _show_buttons() -> void:
	_retry_btn.text = "RETRY" if _won else "TRY AGAIN"
	_next_btn.visible = _won
	_retry_btn.visible = true
	var w := _view.size.x
	var y := _panel_rect().end.y - 170.0
	if _won:
		_retry_btn.position = Vector2(w * 0.5 - 400.0, y)
		_retry_btn.size = Vector2(300.0, 120.0)
		_next_btn.position = Vector2(w * 0.5 - 80.0, y)
		_next_btn.size = Vector2(480.0, 120.0)
	else:
		_retry_btn.position = Vector2(w * 0.5 - 260.0, y)
		_retry_btn.size = Vector2(520.0, 120.0)


func _choose(retry: bool) -> void:
	Sfx.play("tick")
	_hide()
	EventBus.job_next.emit(retry)


func _process(delta: float) -> void:
	if not _view.visible:
		return
	for i in 3:
		_pops[i] = maxf(0.0, _pops[i] - delta * 3.0)
	_view.queue_redraw()


func _panel_rect() -> Rect2:
	var s := _view.size
	return Rect2((s.x - PANEL_W) * 0.5, s.y * 0.2 + _slide * s.y, PANEL_W, PANEL_H)


func _draw_panel() -> void:
	var job := Job.cur
	if job == null:
		return
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), ThemePalette.with_alpha(ThemePalette.INK, 0.5 * _dim))
	var r := _panel_rect()
	var big := ThemePalette.display_font
	var mono := ThemePalette.mono_font
	_view.draw_rect(Rect2(r.position + Vector2(10, 16), r.size), ThemePalette.SHADOW)
	_view.draw_rect(r.grow(8.0), ThemePalette.STICKER)
	_view.draw_rect(r, ThemePalette.PAPER)
	_view.draw_rect(r, ThemePalette.INK, false, 4.0)
	_view.draw_string(big, r.position + Vector2(0, 120), "JOB DONE!" if _won else "OUT OF POWER",
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 92, ThemePalette.COBALT if _won else ThemePalette.RED)
	_view.draw_string(mono, r.position + Vector2(0, 170), "LEVEL %d   ·   BEST %d/3" % [job.level,
		Save.best_stars(job.level)], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, ThemePalette.INK_SOFT)
	for i in 3:
		var c := r.position + Vector2(r.size.x * (0.25 + 0.25 * i), 300.0 - (24.0 if i == 1 else 0.0))
		var k := 1.0 + 0.5 * sin(_pops[i] * PI) if i < _lit else 1.0
		_star(c, (86.0 if i == 1 else 72.0) * k, i < _lit)
	var left := int(round(job.fraction() * 100.0))
	var goals := ["SMASH ALL %d" % job.total, "FREE THE GOLD PART",
		"FINISH WITH %d%%+ POWER  (YOU: %d%%)" % [int(Job.STAR_POWER * 100.0), left]]
	var ok := [_won, _won and job.gold == 1, _won and job.fraction() >= Job.STAR_POWER]
	for i in 3:
		var y := r.position.y + 470.0 + i * 74.0
		var dot := Vector2(r.position.x + 90.0, y - 10.0)
		_view.draw_circle(dot, 20.0, ThemePalette.MINT if ok[i] else ThemePalette.STONE)
		_view.draw_arc(dot, 20.0, 0.0, TAU, 24, ThemePalette.INK, 3.0, true)
		_view.draw_string(big, Vector2(r.position.x + 130.0, y), goals[i], HORIZONTAL_ALIGNMENT_LEFT,
			r.size.x - 170.0, 34, ThemePalette.INK if ok[i] else ThemePalette.INK_SOFT)
	if _won:
		_view.draw_string(big, r.position + Vector2(0, 760), "+" + NumFmt.money(_shown_pay),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 64, ThemePalette.TEAL)
	else:
		_view.draw_string(mono, r.position + Vector2(0, 740), "TIP: CUT THE RED DASHED PARTS, NOT EVERYTHING",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, ThemePalette.INK)
		_view.draw_string(mono, r.position + Vector2(0, 778), "ONE GOOD CUT DROPS A WHOLE SECTION FOR CHEAP",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, ThemePalette.INK)


func _star(c: Vector2, rad: float, lit: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := rad if i % 2 == 0 else rad * 0.45
		pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * rr)
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(5, 8))
	_view.draw_colored_polygon(shadow, ThemePalette.SHADOW)
	_view.draw_colored_polygon(pts, ThemePalette.BUTTER if lit else ThemePalette.STONE)
	pts.append(pts[0])
	_view.draw_polyline(pts, ThemePalette.INK, 4.0, true)


func _button(text: String, fill: Color, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", ThemePalette.display_font)
	b.add_theme_font_size_override("font_size", 44)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, ThemePalette.STICKER if fill != ThemePalette.STONE else ThemePalette.INK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = ThemePalette.INK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(28)
	sb.shadow_color = ThemePalette.SHADOW
	sb.shadow_offset = Vector2(5, 8)
	sb.shadow_size = 2
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(action)
	add_child(b)
	return b
