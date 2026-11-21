class_name Fragment
extends RigidBody2D
## A pooled shard from a shattered Block: small irregular sticker polygon with
## real physics. It falls through MultiplierGates (each multiplies its value
## once) into the Grinder, which turns it into cash. A gold peg doubles it
## once. Dark ink outline so pale shards still read on the paper.
## Batted by the blade, kept on screen by side walls. Recycled, never freed.

const MAX_AGE := 12.0

var active: bool = false
var color: Color
var value: int = 1
var mult: int = 1

var _gates_passed: int = 0
var _lucky: bool = false
var _rim := PackedVector2Array()
var _prev := Vector2.ZERO

var _poly := PackedVector2Array()
var _sticker := PackedVector2Array()
var _shape: CollisionPolygon2D
var _age: float = 0.0
var _drawn_rot: float = 0.0


func _init() -> void:
	_shape = CollisionPolygon2D.new()
	add_child(_shape)
	collision_layer = 4          # "fragments"
	collision_mask = 1 | 8 | 16  # blade, side walls, pegs (not each other: cheap)
	gravity_scale = 1.35
	can_sleep = false
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	visible = false


func _ready() -> void:
	_shape.disabled = true
	set_physics_process(false)


func activate(at: Vector2, poly: PackedVector2Array, col: Color, vel: Vector2, spin: float,
		p_value: int) -> void:
	value = p_value
	mult = 1
	_gates_passed = 0
	_lucky = false
	_prev = at
	_poly = poly
	_sticker = ShapeUtil.grow(poly, 4.0)
	_rim = ShapeUtil.grow(poly, 9.0)
	color = col
	_shape.polygon = poly
	_shape.disabled = false

	var xf := Transform2D(randf() * TAU, at)
	freeze = true
	global_transform = xf
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, xf)
	freeze = false
	linear_velocity = vel
	angular_velocity = spin

	_age = 0.0
	active = true
	visible = true
	set_physics_process(true)
	queue_redraw()


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	set_deferred("freeze", true)
	_shape.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	_age += delta
	var pos := global_position
	var g := MultiplierGate.check(_prev, pos, _gates_passed)
	if g.y > 1:
		_gates_passed = g.x
		mult *= g.y
		queue_redraw()
	if PinField.touch(pos, 26.0) and not _lucky:   # gold peg: x2 once
		_lucky = true
		mult *= 2
		queue_redraw()
	var caught := Catcher.check(_prev, pos)    # Rush: the bucket (-1 = not here)
	_prev = pos
	if caught == 0:
		deactivate()                           # missed the bucket: lost
	elif caught > 0:
		EventBus.fragment_collected.emit(pos, color, value * mult * caught)
		deactivate()
	elif pos.y >= Grinder.INTAKE_Y:
		EventBus.fragment_collected.emit(pos, color, value * mult)
		deactivate()
	elif _age > MAX_AGE:
		deactivate()


func _draw() -> void:
	var g := Batch.new(self)                   # v14: one draw call per shard
	if mult > 1:
		g.draw_colored_polygon(_rim, ThemePalette.BUTTER)
	_drawn_rot = rotation
	Depth.walls(g, _sticker, rotation, Depth.SHARD, color, false)
	g.draw_colored_polygon(_sticker, ThemePalette.INK)
	Depth.top(g, _poly, rotation, color)
	if mult > 1:   # stamped multiplier badge
		g.draw_circle(Vector2.ZERO, 15.0, ThemePalette.STICKER)
		g.draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 20, ThemePalette.INK, 2.0, true)
		g.draw_string(ThemePalette.display_font, Vector2(-15.0, 6.0), "x%d" % mult,
			HORIZONTAL_ALIGNMENT_CENTER, 30.0, 15, ThemePalette.RED)
	g.flush()
