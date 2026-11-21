extends Control
## The job's goals, top centre under the progress squares:
##   a POWER bar (what's left of this job's cutting budget) with a star tick
##   at 35% (finish above it for the 3rd star), "+8%" when a clean cut refunds
##   power, red and shaking when low; then the gold goal.

const W := 360.0
const H := 54.0

var _pop: float = 0.0
var _added: float = 0.0
var _added_t: float = 0.0
var _shown: float = 1.0
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.time_added.connect(_on_refund)


func _on_refund(percent: float) -> void:
	_added = percent
	_added_t = 1.2
	_pop = 1.0


func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(0.0, _pop - delta * 3.0)
	_added_t = maxf(0.0, _added_t - delta)
	if Job.cur:
		_shown = lerpf(_shown, Job.cur.fraction(), 1.0 - exp(-10.0 * delta))
	queue_redraw()


func _draw() -> void:
	var job := Job.cur
	if job == null or job.phase == Job.Phase.IDLE or job.capacity <= 0.0:
		return
	var cx := size.x * 0.5
	var low := _shown < 0.2 and job.running()
	var shake := Vector2(randf_range(-2, 2), randf_range(-2, 2)) if low else Vector2.ZERO
	var sc := 1.0 + 0.1 * sin(_pop * PI)
	draw_set_transform(Vector2(cx, 40.0) + shake, 0.0, Vector2(sc, sc))
	var r := Rect2(-W * 0.5, -H * 0.5, W, H)
	draw_rect(Rect2(r.position + Vector2(4, 7), r.size), ThemePalette.SHADOW)
	draw_rect(r.grow(5.0), ThemePalette.STICKER)
	draw_rect(r, ThemePalette.STONE)
	if TestSwitches.on("free"):              # test switch: no budget to show
		draw_rect(r, ThemePalette.MINT)
		draw_rect(r, ThemePalette.INK, false, 3.0)
		draw_string(ThemePalette.display_font, Vector2(r.position.x, 14.0), "FREE CUTTING",
			HORIZONTAL_ALIGNMENT_CENTER, W, 32, ThemePalette.INK)
		draw_set_transform(Vector2.ZERO)
		_gold(job, cx)
		return
	var fill := ThemePalette.RED if low else (ThemePalette.MINT if Frenzy.active else ThemePalette.COBALT)
	draw_rect(Rect2(r.position, Vector2(W * clampf(_shown, 0.0, 1.0), H)), fill)
	var tick_x := r.position.x + W * Job.STAR_POWER               # the 3rd-star line
	draw_line(Vector2(tick_x, r.position.y - 8), Vector2(tick_x, r.end.y + 8), ThemePalette.INK, 4.0)
	MenuScreen.draw_star(self, Vector2(tick_x, r.position.y - 18), 13.0, _shown >= Job.STAR_POWER)
	draw_rect(r, ThemePalette.INK, false, 3.0)
	draw_string(ThemePalette.display_font, Vector2(r.position.x, 14.0),
		"POWER %d%%" % int(round(_shown * 100.0)), HORIZONTAL_ALIGNMENT_CENTER, W, 32,
		ThemePalette.STICKER if _shown > 0.55 else ThemePalette.INK)
	draw_set_transform(Vector2.ZERO)
	if _added_t > 0.0:
		draw_string(ThemePalette.display_font, Vector2(cx + W * 0.5 + 14.0, 52.0 - (1.2 - _added_t) * 20.0),
			"+%d%%" % int(round(_added)), HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
			ThemePalette.with_alpha(ThemePalette.TEAL, minf(_added_t * 2.0, 1.0)))

	_gold(job, cx)


## The gold goal under the bar.
func _gold(job: Job, cx: float) -> void:
	var g := Vector2(cx - 50.0, 112.0)
	draw_circle(g, 15.0, ThemePalette.BUTTER if job.gold == 1 else ThemePalette.CREAM)
	draw_arc(g, 15.0, 0.0, TAU, 20, ThemePalette.INK, 3.0, true)
	if job.gold == -1:
		draw_line(g + Vector2(-10, -10), g + Vector2(10, 10), ThemePalette.RED, 4.0)
		draw_line(g + Vector2(10, -10), g + Vector2(-10, 10), ThemePalette.RED, 4.0)
	var label := "GOLD FREED!" if job.gold == 1 else ("GOLD LOST" if job.gold == -1 else "FREE THE GOLD")
	draw_string(ThemePalette.display_font, Vector2(g.x + 26.0, 122.0), label, HORIZONTAL_ALIGNMENT_LEFT,
		-1, 26, ThemePalette.RED if job.gold == -1 else ThemePalette.INK)
