extends Line2D
## The thin hand-drawn ink cable that loops across the page and slowly drifts.
## Layered sines are tuned so the path crosses over itself like a loose wire.

const POINTS := 140

@export var drift_speed: float = 0.12
@export var line_alpha: float = 0.28

var _t: float = 0.0


func _ready() -> void:
	z_index = -5
	width = 3.0
	antialiased = true
	default_color = ThemePalette.with_alpha(ThemePalette.INK, line_alpha)
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	clear_points()
	for i in POINTS:
		add_point(Vector2.ZERO)
	_rebuild()


func _process(delta: float) -> void:
	_t += delta * drift_speed
	_rebuild()


func _rebuild() -> void:
	var s := get_viewport_rect().size
	for i in POINTS:
		var u := float(i) / float(POINTS - 1)
		var x := s.x * 0.5 \
			+ s.x * 0.42 * sin(TAU * u * 1.15 + _t) \
			+ s.x * 0.14 * sin(TAU * u * 3.4 - _t * 1.7)
		# Vertical wobble is big enough to make the path loop back on itself.
		var y := lerpf(-140.0, s.y + 140.0, u) + 240.0 * sin(TAU * u * 2.3 + _t * 1.3)
		set_point_position(i, Vector2(x, y))
