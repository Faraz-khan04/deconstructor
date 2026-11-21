extends CanvasLayer
## Tiny frame-rate readout in the bottom-left corner (test builds only).
## F3 hides/shows it. Green = smooth (55+), orange = okay, red = choppy.

var _label: Label
var _worst: float = 0.0
var _t: float = 0.0
var _last_us: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = OS.is_debug_build()
	_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 26
	ls.outline_size = 6
	ls.outline_color = Color.BLACK
	_label.label_settings = ls
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = 12.0
	_label.offset_top = -44.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible


func _process(delta: float) -> void:
	# v14: real clock time. (Dividing delta by the slow-motion scale turned a
	# 100 ms hiccup during a hit-stop into a fake "5000 ms" reading.)
	var now := Time.get_ticks_usec()
	var real := (now - _last_us) / 1000000.0 if _last_us > 0 else delta
	_last_us = now
	_worst = maxf(_worst, real)
	_t += real
	if _t < 0.5:
		return
	var fps := Engine.get_frames_per_second()
	_label.text = "%d FPS  (worst frame %d ms)  %d draw calls" % [fps, int(_worst * 1000.0),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
	_label.label_settings.font_color = Color.GREEN if fps >= 55 else (Color.ORANGE if fps >= 35 else Color.RED)
	_t = 0.0
	_worst = 0.0
