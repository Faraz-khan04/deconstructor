class_name OrbitSaws
extends Node2D
## MINI SAWS upgrade: 1-3 little saws circling the main saw. They cut while
## your thumb is down and never use the battery. Works with every tool.

const SIZE_K := 0.36          # mini saw radius vs main saw
const DIST_K := 1.5           # orbit distance vs main saw
const DAMAGE_K := 0.45
const SPEED := 2.8            # radians per second

var _blade                     # the DeconstructorBlade (untyped: its own vars)
var _saws: Array[Node2D] = []
var _angle: float = 0.0
var _q: PhysicsShapeQueryParameters2D


func setup(blade) -> void:
	_blade = blade
	_q = PhysicsShapeQueryParameters2D.new()
	_q.shape = CircleShape2D.new()
	_q.collision_mask = 2                  # "blocks"
	_q.collide_with_bodies = true
	_q.collide_with_areas = false
	rebuild()


## Called by the blade after upgrades change (so it uses the new saw size).
func rebuild() -> void:
	var want: int = Economy.mini_saws()
	var saw_script := load("res://player/SawVisual.gd")
	while _saws.size() < want:
		var s: Node2D = saw_script.new()
		add_child(s)
		_saws.append(s)
		s.scale = Vector2.ZERO               # pop in
		s.create_tween().tween_property(s, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for s in _saws:
		s.set("radius", _blade.radius * SIZE_K)


func _process(delta: float) -> void:
	if _saws.is_empty():
		return
	_angle += delta * SPEED
	for i in _saws.size():
		var s := _saws[i]
		s.position = Vector2.from_angle(_angle + TAU * i / _saws.size()) * _blade.radius * DIST_K
		s.rotation += _blade.rpm / 60.0 * TAU * delta * 1.4


## Called every physics frame by the blade. True if anything was cut.
func cut(delta: float) -> bool:
	if _saws.is_empty() or not _blade.is_held():
		return false
	var r: float = _blade.radius * SIZE_K
	(_q.shape as CircleShape2D).radius = r
	var dmg: float = _blade.damage_per_second * _blade.damage_mult * DAMAGE_K * delta
	var hit := false
	var space := get_world_2d().direct_space_state
	for s in _saws:
		_q.transform = Transform2D(0.0, s.global_position)
		for res in space.intersect_shape(_q, 16):
			var body: Object = res["collider"]
			if body and body.has_method("take_damage"):
				var contact: Vector2 = s.global_position \
					+ ((body as Node2D).global_position - s.global_position).limit_length(r * 0.9)
				body.take_damage(dmg, contact, _blade.velocity)
				hit = true
	return hit
