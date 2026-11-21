extends Control
## Full-width sticker tape slapped across the middle of the screen for the big
## moments: "LEVEL 16", "FRENZY!", "CATALOG COMPLETE!". Slams in from big,
## holds, then is ripped off to the right. Runs in real time.

const HOLD := 1.0

var _queue: Array = []        # [title, sub, color]
var _cur: Array = []
var _s: float = 0.0           # slam scale, 2.2 -> 1
var _a: float = 0.0           # alpha
var _x: float = 0.0           # exit slide
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.title_card_requested.connect(_on_card)


func _on_card(title: String, sub: String, color: Color) -> void:
	_queue.append([title, sub, color])
	if _cur.is_empty():
		_next()


func _next() -> void:
	_cur = [] if _queue.is_empty() else _queue.pop_front()
	queue_redraw()
	if _cur.is_empty():
		return
	_s = 2.2
	_a = 0.0
	_x = 0.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.set_parallel(true)
	_tween.tween_property(self, "_s", 1.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_a", 1.0, 0.16)
	_tween.chain().tween_callback(_slammed)
	_tween.chain().tween_interval(HOLD)
	_tween.chain().tween_property(self, "_x", size.x * 1.3, 0.38) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_next)


func _slammed() -> void:
	EventBus.shake_requested.emit(0.45)
	JuiceManager.buzz(40, 0.8)


func _process(_delta: float) -> void:
	if not _cur.is_empty():
		queue_redraw()


func _draw() -> void:
	if _cur.is_empty() or _a <= 0.01:
		return
	var col: Color = _cur[2]
	var text_col := ThemePalette.INK if col == ThemePalette.BUTTER else ThemePalette.STICKER
	var c := Vector2(size.x * 0.5 + _x, size.y * 0.4)
	draw_set_transform(c, -0.05, Vector2(_s, _s))
	var w := size.x + 160.0
	var r := Rect2(-w * 0.5, -120.0, w, 240.0)
	var fade := func(k: Color) -> Color: return ThemePalette.with_alpha(k, k.a * _a)
	draw_rect(Rect2(r.position + Vector2(0, 14), r.size), fade.call(ThemePalette.SHADOW))
	draw_rect(r.grow(8.0), fade.call(ThemePalette.STICKER))
	draw_rect(r, fade.call(col))
	draw_rect(r, fade.call(ThemePalette.INK), false, 4.0)
	var big := ThemePalette.display_font
	var title: String = _cur[0]
	var ts := 150
	while ts > 60 and big.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x > size.x - 80.0:
		ts -= 10
	draw_string(big, Vector2(r.position.x, 40.0), title, HORIZONTAL_ALIGNMENT_CENTER, w, ts,
		fade.call(text_col))
	draw_string(ThemePalette.mono_font, Vector2(r.position.x, 96.0), _cur[1],
		HORIZONTAL_ALIGNMENT_CENTER, w, 34, fade.call(ThemePalette.with_alpha(text_col, 0.9)))
	draw_set_transform(Vector2.ZERO)
