extends Node2D
## Giant sticker squeegee that sweeps the page top -> bottom between waves.
## Every frame it reports its edge via EventBus.wipe_progress, and PaintLayer
## erases everything above it. Plays on EventBus.wipe_requested.

const DURATION := 1.1

var _y: float = -400.0
var _active: bool = false
var _tilt: float = 0.0


func _ready() -> void:
	z_index = 40
	visible = false
	EventBus.wipe_requested.connect(play)


func play() -> void:
	if _active:
		return
	_active = true
	visible = true
	var h := get_viewport_rect().size.y
	_y = -200.0
	var t := create_tween()
	t.tween_method(_set_y, -200.0, h + 260.0, DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_finish)


func _set_y(v: float) -> void:
	_tilt = sin(v * 0.006) * 0.02
	_y = v
	EventBus.wipe_progress.emit(_y)
	queue_redraw()


func _finish() -> void:
	_active = false
	visible = false
	EventBus.wipe_finished.emit()


func _draw() -> void:
	var w := get_viewport_rect().size.x
	draw_set_transform(Vector2(w * 0.5, _y), _tilt)
	var blade := Rect2(-w * 0.5 - 20.0, -16.0, w + 40.0, 32.0)
	var handle := Rect2(-34.0, -190.0, 68.0, 176.0)
	var grip := Rect2(-46.0, -230.0, 92.0, 56.0)

	# Shadows
	for r in [blade, handle, grip]:
		draw_rect(Rect2(r.position + Vector2(8, 12), r.size), ThemePalette.SHADOW)
	# Sticker borders
	for r in [handle, grip, blade]:
		draw_rect(r.grow(6.0), ThemePalette.STICKER)
	# Handle + grip
	draw_rect(handle, ThemePalette.BUTTER)
	draw_rect(handle, ThemePalette.INK, false, 3.0)
	draw_rect(grip, ThemePalette.RED)
	draw_rect(grip, ThemePalette.INK, false, 3.0)
	# Rubber blade with a wet sheen line
	draw_rect(blade, ThemePalette.CHARCOAL)
	draw_line(Vector2(blade.position.x, -6.0), Vector2(blade.end.x, -6.0),
		Color(1, 1, 1, 0.25), 3.0)
	draw_rect(blade, ThemePalette.INK, false, 3.0)
	draw_set_transform(Vector2.ZERO)
