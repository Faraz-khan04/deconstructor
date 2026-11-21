extends Control
## The reserved news strip under the progress squares and combo badge.
## One sticker banner at a time, queued, so big moments never pile up or get
## cut off ("BIG ONE COMING!", "GOLDEN PART!", "POWER LV 6"). Sending the
## same title again updates the banner on screen instead of queueing a copy
## (holding an upgrade button just keeps bumping one banner).
## Animates in real time, so slow-motion and hit-stop never stall it.

const CENTER_Y := 400.0
const HOLD := 1.35
const EDGE := 24.0
const STALE_MS := 3000        # news older than this is dropped, never shown late

var _queue: Array = []        # [title, sub, color, queued at ms]
var _cur: Array = []
var _s: float = 0.0           # 0 hidden .. 1 shown (tweened)
var _pop: float = 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.banner_requested.connect(_on_banner)


func _on_banner(title: String, sub: String, color: Color) -> void:
	var item := [title, sub, color, Time.get_ticks_msec()]
	if not _cur.is_empty() and _cur[0] == title:
		_cur = item
		_pop = 1.0
		_play(false)
		return
	for i in _queue.size():
		if _queue[i][0] == title:
			_queue[i] = item
			return
	_queue.append(item)
	if _cur.is_empty():
		_next()


func _next() -> void:
	var now := Time.get_ticks_msec()
	while not _queue.is_empty() and now - int(_queue[0][3]) > STALE_MS:
		_queue.pop_front()
	_cur = [] if _queue.is_empty() else _queue.pop_front()
	_s = 0.0
	if not _cur.is_empty():
		_pop = 0.0
		_play(true)
	queue_redraw()


func _play(from_zero: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(self, "_s", 1.0, 0.3 if from_zero else 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(HOLD * (0.6 if _queue.size() > 1 else 1.0))
	_tween.tween_property(self, "_s", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_next)


func _process(delta: float) -> void:
	if _cur.is_empty():
		return
	_pop = maxf(0.0, _pop - delta / maxf(Engine.time_scale, 0.01) * 4.0)
	queue_redraw()


func _draw() -> void:
	if _cur.is_empty() or _s <= 0.01:
		return
	var title: String = _cur[0]
	var sub: String = _cur[1]
	var col: Color = _cur[2]
	var big := ThemePalette.display_font
	var small := ThemePalette.mono_font
	var max_w := size.x - EDGE * 2.0 - 30.0
	var ts := 54
	while ts > 30 and big.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x > max_w - 60.0:
		ts -= 4
	var ss := 26
	while ss > 18 and small.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x > max_w - 60.0:
		ss -= 2
	var w := maxf(big.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x,
		small.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x) + 70.0
	w = minf(maxf(w, 300.0), max_w)
	var h := 76.0 + (36.0 if sub != "" else 0.0)
	var sc := _s * (1.0 + 0.12 * sin(_pop * PI))
	draw_set_transform(Vector2(size.x * 0.5, CENTER_Y), -0.02 + 0.04 * _pop * sin(_pop * 12.0),
		Vector2(sc, sc))
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	draw_rect(Rect2(r.position + Vector2(6, 9), r.size), ThemePalette.SHADOW)
	draw_rect(r.grow(6.0), ThemePalette.STICKER)
	draw_rect(r, col)
	draw_rect(r, ThemePalette.INK, false, 3.0)
	var text_col := ThemePalette.INK if col == ThemePalette.BUTTER else ThemePalette.STICKER
	draw_string(big, Vector2(r.position.x, r.position.y + 58.0), title,
		HORIZONTAL_ALIGNMENT_CENTER, w, ts, text_col)
	if sub != "":
		draw_string(small, Vector2(r.position.x, r.position.y + 96.0), sub,
			HORIZONTAL_ALIGNMENT_CENTER, w, ss, ThemePalette.with_alpha(text_col, 0.9))
	draw_set_transform(Vector2.ZERO)
