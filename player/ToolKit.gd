class_name ToolKit
extends Node2D
## The swappable cutting tools, attached to the player's saw node.
##   saw   - the classic buzzsaw (the blade script handles it)
##   twin  - two smaller saws circling your thumb
##   laser - small, strong, leaves scorch marks on the paper
##   hole  - black hole: pulls loose pieces in, then throws them down
## The chosen tool is saved; new ones unlock as you reach levels.

const TOOLS := {
	"saw": {"name": "BUZZSAW", "desc": "All-rounder", "unlock": 1},
	"twin": {"name": "TWIN SAWS", "desc": "Two saws orbit", "unlock": 5},
	"laser": {"name": "LASER", "desc": "Strong, burns paper", "unlock": 10},
	"hole": {"name": "BLACK HOLE", "desc": "Pulls, then throws", "unlock": 15},
}
const ORDER := ["saw", "twin", "laser", "hole"]
const PULL_RANGE := 430.0

var tool: String = "saw"

var _blade                     # the DeconstructorBlade (untyped: its own vars)
var _twins: Array[Node2D] = []
var _orbit: float = 0.0
var _t: float = 0.0
var _last_pos := Vector2.ZERO
var _q: PhysicsShapeQueryParameters2D


func setup(blade) -> void:
	_blade = blade
	var saw_script := load("res://player/SawVisual.gd")
	for i in 2:
		var s: Node2D = saw_script.new()
		s.set("radius", blade.radius * 0.6)
		s.visible = false
		add_child(s)
		_twins.append(s)
	_q = PhysicsShapeQueryParameters2D.new()
	_q.shape = CircleShape2D.new()
	_q.collide_with_bodies = true
	_q.collide_with_areas = false
	EventBus.tool_changed.connect(set_tool)
	EventBus.upgrades_changed.connect(_resize_twins)
	set_tool(String(Save.data["tool"]))


## SIZE upgrade grows the twin saws too.
func _resize_twins() -> void:
	for s in _twins:
		s.set("radius", _blade.radius * 0.6)


func is_special() -> bool:
	return tool != "saw"


func set_tool(id: String) -> void:
	tool = id if TOOLS.has(id) else "saw"
	var classic := tool == "saw"
	_blade.get_node("SawVisual").visible = classic
	var shadow = _blade.get_node_or_null("SawShadow")
	if shadow:
		shadow.visible = classic
	for s in _twins:
		s.visible = tool == "twin"
	queue_redraw()


## Cut with the current special tool. Returns true if anything was cut.
func cut(delta: float) -> bool:
	var center: Vector2 = _blade.global_position
	var hit := false
	match tool:
		"twin":
			for s in _twins:
				hit = _cut_circle(s.global_position, _blade.radius * 0.6, 0.65, delta) or hit
		"laser":
			hit = _cut_circle(center, _blade.radius * 0.35, 1.7, delta)
			if hit and center.distance_to(_last_pos) > 2.0:
				EventBus.burn.emit(_last_pos, center)
		"hole":
			_pull()
			hit = _cut_circle(center, _blade.radius * 0.8, 0.6, delta)
	_last_pos = center
	return hit


func _cut_circle(at: Vector2, r: float, mult: float, delta: float) -> bool:
	(_q.shape as CircleShape2D).radius = r
	_q.collision_mask = 2
	_q.transform = Transform2D(0.0, at)
	var hit := false
	var rpm_factor := clampf(_blade.rpm / _blade.base_rpm, 0.4, 3.0)
	var dmg: float = _blade.damage_per_second * _blade.damage_mult * mult * rpm_factor * delta
	for res in get_world_2d().direct_space_state.intersect_shape(_q, 48):
		var body: Object = res["collider"]
		if body and body.has_method("take_damage"):
			var contact: Vector2 = at + ((body as Node2D).global_position - at).limit_length(r * 0.9)
			body.take_damage(dmg, contact, _blade.velocity)
			hit = true
	return hit


## Black hole: drag loose parts and shards in; once close, fling them down.
func _pull() -> void:
	var center: Vector2 = _blade.global_position
	(_q.shape as CircleShape2D).radius = PULL_RANGE
	_q.collision_mask = 2 | 4
	_q.transform = Transform2D(0.0, center)
	for res in get_world_2d().direct_space_state.intersect_shape(_q, 64):
		var body := res["collider"] as RigidBody2D
		if body == null or body.freeze:
			continue
		var to := center - body.global_position
		if to.length() < _blade.radius * 0.7:
			body.linear_velocity = Vector2(randf_range(-260.0, 260.0), 1150.0)
		else:
			body.apply_central_force(to.normalized() * 2600.0 * body.mass)


func _process(delta: float) -> void:
	_t += delta
	if tool == "twin":
		_orbit += delta * 3.2
		for i in _twins.size():
			var s := _twins[i]
			s.position = Vector2.from_angle(_orbit + PI * i) * _blade.radius * 0.85
			s.rotation += _blade.rpm / 60.0 * TAU * delta
	if tool == "laser" or tool == "hole":
		queue_redraw()


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var r: float = _blade.radius
	if tool == "laser":
		var glow := 0.6 + 0.4 * sin(_t * 30.0)
		g.draw_circle(Vector2(5, 8), r * 0.44, ThemePalette.SHADOW)
		g.draw_circle(Vector2.ZERO, r * 0.44, ThemePalette.STICKER)
		g.draw_circle(Vector2.ZERO, r * 0.38, ThemePalette.CHARCOAL)
		g.draw_circle(Vector2.ZERO, r * 0.2, ThemePalette.with_alpha(ThemePalette.RED, 0.35 + 0.3 * glow))
		g.draw_circle(Vector2.ZERO, r * 0.11, ThemePalette.RED)
		g.draw_circle(Vector2(-r * 0.04, -r * 0.04), r * 0.04, ThemePalette.STICKER)
	elif tool == "hole":
		g.draw_circle(Vector2(5, 8), r * 0.85, ThemePalette.SHADOW)
		g.draw_circle(Vector2.ZERO, r * 0.85, ThemePalette.STICKER)
		g.draw_circle(Vector2.ZERO, r * 0.78, ThemePalette.INK)
		for i in 3:
			var a := _t * (2.5 + i) + i * 2.0
			g.draw_arc(Vector2.ZERO, r * (0.3 + i * 0.15), a, a + PI * 1.2, 24,
				[ThemePalette.LILAC, ThemePalette.PINK, ThemePalette.COBALT][i], 5.0, true)
		g.draw_arc(Vector2.ZERO, PULL_RANGE, _t, _t + TAU, 64,
			ThemePalette.with_alpha(ThemePalette.LILAC, 0.18), 3.0, true)
	g.flush()
