class_name Slicer
extends Node2D
## RUSH controls: swipe to slice. Fast finger movement cuts through every part
## along its path (instantly), leaving a bright tapered streak. Slow movement
## doesn't cut, so it's about quick, decisive swipes.
## One swipe = finger down until it stops moving or lifts; when it ends we
## report how many separate objects it sliced (2+ = DOUBLE/TRIPLE bonus).
## Touches in the bottom zone belong to the bucket (Catcher), not to us.

signal swipe_finished(objects: int, at: Vector2)

static var last_vel := Vector2.ZERO   # the current swipe: sliced pieces fly this way

const MIN_SPEED := 650.0       # px/s needed to cut
const WIDTH := 40.0
const TRAIL_LIFE := 0.13
const PAUSE_ENDS := 0.22       # this long without cutting speed ends a swipe

var _touch: int = -1
var _pos := Vector2.ZERO
var _prev := Vector2.ZERO
var _hits := {}
var _slow: float = 0.0
var _trail: Line2D
var _points: Array = []        # [world pos, time]
var _q: PhysicsShapeQueryParameters2D
var _rect := RectangleShape2D.new()


func _ready() -> void:
	z_index = 40
	_trail = Line2D.new()
	_trail.width = 26.0
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = curve
	var g := Gradient.new()
	g.set_color(0, ThemePalette.with_alpha(ThemePalette.TANGERINE, 0.0))
	g.set_color(1, ThemePalette.STICKER)
	_trail.gradient = g
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_trail)
	_q = PhysicsShapeQueryParameters2D.new()
	_q.shape = _rect
	_q.collision_mask = 2                  # "blocks"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and not Catcher.owns_screen_point(self, event.position):
			_touch = event.index
			_pos = ScreenSpace.to_world(self, event.position)
			_prev = _pos
			_points.clear()
		elif not event.pressed and event.index == _touch:
			_end_swipe()
			_touch = -1
	elif event is InputEventScreenDrag and event.index == _touch:
		_pos = ScreenSpace.to_world(self, event.position)


func _physics_process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	while not _points.is_empty() and now - float(_points[0][1]) > TRAIL_LIFE:
		_points.pop_front()
	if _touch != -1:
		var seg := _pos - _prev
		var speed := seg.length() / maxf(delta, 0.001)
		if speed >= MIN_SPEED:
			_slow = 0.0
			_points.append([_pos, now])
			_cut(_prev, _pos, seg / maxf(delta, 0.001))
		else:
			_slow += delta
			if _slow >= PAUSE_ENDS:
				_end_swipe()
		_prev = _pos
	var pts := PackedVector2Array()
	for p in _points:
		pts.append(p[0])
	_trail.points = pts


func _cut(a: Vector2, b: Vector2, v: Vector2) -> void:
	_rect.size = Vector2(a.distance_to(b) + WIDTH, WIDTH)
	_q.transform = Transform2D((b - a).angle(), (a + b) * 0.5)
	Sfx.play("slash", 1.0 + randf() * 0.2)
	v = v.limit_length(1700.0)
	last_vel = v
	for r in get_world_2d().direct_space_state.intersect_shape(_q, 32):
		var body: Object = r["collider"]
		if body is Block and body.state != Block.State.DEAD:
			var host := (body as Node).get_parent()
			if host is Thrown:
				_hits[host.get_instance_id()] = true
			body.take_damage(9999.0, (body as Node2D).global_position, v)


func _end_swipe() -> void:
	if not _hits.is_empty():
		swipe_finished.emit(_hits.size(), _pos)
	_hits.clear()
	_slow = 0.0
