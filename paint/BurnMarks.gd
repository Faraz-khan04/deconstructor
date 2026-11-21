extends Node2D
## Laser scorch lines, drawn into the paint canvas (which never clears), so
## they stay on the paper until the squeegee wipes it. Each frame draws only
## the new segments, then forgets them.

var _segments := PackedVector2Array()   # pairs: a, b, a, b...


func _ready() -> void:
	EventBus.burn.connect(_on_burn)
	EventBus.wipe_finished.connect(queue_redraw)   # drop the last batch after a wipe


func _on_burn(a: Vector2, b: Vector2) -> void:
	_segments.append(a)
	_segments.append(b)
	queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var i := 0
	while i + 1 < _segments.size():
		var a := _segments[i]
		var b := _segments[i + 1]
		g.draw_line(a, b, ThemePalette.with_alpha(ThemePalette.INK, 0.4), 12.0, true)
		g.draw_line(a, b, ThemePalette.TANGERINE, 4.0, true)
		g.draw_line(a, b, ThemePalette.BUTTER, 1.5, true)
		i += 2
	_segments.clear()
	g.flush()
