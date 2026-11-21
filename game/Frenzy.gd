class_name Frenzy
extends CanvasLayer
## FRENZY: three golden parts in a row unlock 8 seconds of chaos.
## No overheating, double cash, a bigger saw, a pulsing hazard-tape border
## and paint going off by itself. Economy and HeatGauge read `active`.
## Started by EventBus.frenzy_changed(true); ends itself with (false).

const DURATION := 8.0

static var active: bool = false

var _left: float = 0.0
var _t: float = 0.0
var _paint_t: float = 0.0
var _view: Control


func _ready() -> void:
	layer = 9
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_border)
	add_child(_view)
	EventBus.frenzy_changed.connect(_on_changed)


func _exit_tree() -> void:
	active = false


func _on_changed(on: bool) -> void:
	if not on:
		return
	if not active:
		EventBus.title_card_requested.emit("FRENZY!", "NO OVERHEAT · CASH x2 · BIG SAW",
			ThemePalette.RED)
	active = true
	_left = DURATION


func _process(delta: float) -> void:
	_t += delta
	if not active:
		return
	_left -= delta
	_paint_t -= delta
	if _paint_t <= 0.0:               # the page celebrates by itself
		_paint_t = 0.35
		var vp := _view.size
		var at := ScreenSpace.to_world(_view, Vector2(randf_range(80.0, vp.x - 80.0),
			randf_range(400.0, vp.y * 0.55)))
		EventBus.splash.emit(at, Vector2.from_angle(randf() * TAU) * 600.0, 0.35, Color(0, 0, 0, 0))
	if _left <= 0.0:
		active = false
		EventBus.frenzy_changed.emit(false)
		EventBus.banner_requested.emit("FRENZY OVER", "FIND 3 MORE GOLD FOR ANOTHER",
			ThemePalette.INK_SOFT)
	_view.queue_redraw()


func _draw_border() -> void:
	if not active:
		return
	var s := _view.size
	var th := 16.0 + 6.0 * sin(_t * 12.0)
	var warn := _left < 2.0 and int(_t * 8.0) % 2 == 0
	var col := ThemePalette.BUTTER if warn else ThemePalette.RED
	for r in [Rect2(0, 0, s.x, th), Rect2(0, s.y - th, s.x, th),
			Rect2(0, 0, th, s.y), Rect2(s.x - th, 0, th, s.y)]:
		_view.draw_rect(r, ThemePalette.with_alpha(col, 0.85))
	_view.draw_rect(Rect2(Vector2.ONE * th, s - Vector2.ONE * th * 2.0), ThemePalette.INK, false, 3.0)
