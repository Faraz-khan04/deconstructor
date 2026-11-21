extends Control
## Top-centre level progress: one sticker square per object in the level.
## Filled squares pop in with a springy bounce as each object is smashed.

const PIP := 34.0
const GAP := 14.0

var done: int = 0
var total: int = 3
var _pop: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.level_progress.connect(_on_progress)


func _on_progress(d: int, t: int) -> void:
	if d > done:
		_pop = 1.0
	done = d
	total = t
	queue_redraw()


func _process(delta: float) -> void:
	if _pop > 0.0:
		_pop = maxf(0.0, _pop - delta * 3.0)
		queue_redraw()


func _draw() -> void:
	var w := total * PIP + (total - 1) * GAP
	var x := (size.x - w) * 0.5
	for i in total:
		var filled := i < done
		var s := PIP
		if filled and i == done - 1:
			s *= 1.0 + 0.35 * sin(_pop * PI)          # newest pip bounces
		var r := Rect2(x + (PIP - s) * 0.5, (PIP - s) * 0.5, s, s)
		draw_rect(Rect2(r.position + Vector2(3, 5), r.size), ThemePalette.SHADOW)
		draw_rect(r.grow(4.0), ThemePalette.STICKER)
		draw_rect(r, ThemePalette.COBALT if filled else ThemePalette.CREAM)
		draw_rect(r, ThemePalette.INK, false, 3.0)
		x += PIP + GAP
