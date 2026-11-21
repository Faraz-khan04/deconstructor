extends AnimatableBody2D
## The player's saw: offset one-thumb drag, smooth follow, spins up with speed,
## lifts off the paper while held, cuts what it touches, battery ring on the hub.
## Never dips into the peg board; drags while cutting so you feel it bite.

const SHADOW_REST := Vector2(7.0, 10.0)
const SHADOW_LIFTED := Vector2(16.0, 26.0)

@export var follow_sharpness: float = 18.0   # higher = snappier
@export var radius: float = 90.0
@export var idle_rpm: float = 90.0; @export var base_rpm: float = 300.0
@export var max_rpm: float = 1400.0
@export var spool_rate: float = 6.0; @export var lift_rate: float = 14.0
@export var swipe_speed: float = 2600.0       # px/s that counts as full speed
@export var trail_length: int = 16            # points (~0.27 s at 60 FPS)
@export var screen_margin: float = 90.0
@export var bottom_reserve: float = 440.0     # keeps the saw above shredder + buttons
@export var damage_per_second: float = 7.0    # at base RPM; scales with spin
var _drag: float = 1.0; var _hit_mat: int = 0   # what the saw is biting (Materials)

@onready var _saw: Node2D = $SawVisual
@onready var _shadow: Node2D = get_node_or_null("SawShadow")
@onready var _trail: Line2D = $Trail

var velocity: Vector2 = Vector2.ZERO; var rpm: float = 0.0
var punch_scale: float = 1.0  # animated by tween
var grinding: bool = false

var _query: PhysicsShapeQueryParameters2D; var _heat: HeatGauge
var _tools: ToolKit; var _orbit: OrbitSaws
var _body_shape: CircleShape2D
var _base_radius: float = 90.0
var damage_mult: float = 1.0          # from the POWER upgrade
var _lift: float = 0.0
var _target_screen: Vector2
var _grab_offset: Vector2 = Vector2.ZERO
var _touch_index: int = -1
var _punch_tween: Tween


func _ready() -> void:
	_target_screen = ScreenSpace.to_screen(self, global_position)
	_base_radius = radius
	rpm = idle_rpm
	_saw.set("radius", radius)
	if _shadow:
		_shadow.set("radius", radius); _shadow.set("shadow_only", true)
	_tools = ToolKit.new()
	add_child(_tools)                   # before the battery ring so it's drawn under it
	_tools.setup(self)
	_orbit = OrbitSaws.new()
	add_child(_orbit)
	_orbit.setup(self)
	_heat = HeatGauge.new()
	_heat.radius = radius
	add_child(_heat)                    # after SawVisual, so drawn on top
	_build_collision()
	_build_hitbox()
	TrailStyle.apply(_trail, radius)
	EventBus.upgrades_changed.connect(_on_upgrades_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			var y: float = event.position.y
			if y > get_viewport_rect().size.y - 250.0 or y < 290.0 or Catcher.owns_screen_point(self, event.position):
				return                          # buttons at the top/bottom, not the saw
			_touch_index = event.index
			_grab_offset = _target_screen - event.position
			_punch(0.85)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_punch(1.12)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_target_screen = ScreenSpace.clamp_play_area(self, event.position + _grab_offset,
			screen_margin, bottom_reserve)
		var w := ScreenSpace.to_world(self, _target_screen)
		var floor_y := PinField.BOARD_TOP - radius * 0.55
		if w.y > floor_y:                       # never down into the pegs
			_target_screen = ScreenSpace.to_screen(self, Vector2(w.x, floor_y))


func _physics_process(delta: float) -> void:
	var prev := global_position
	var target := ScreenSpace.to_world(self, _target_screen)
	var sharp := follow_sharpness * (_drag if grinding else 1.0)   # metal drags, glass glides
	global_position = global_position.lerp(target, 1.0 - exp(-sharp * delta))
	velocity = (global_position - prev) / maxf(delta, 0.0001)

	grinding = false
	if _heat.can_cut():                 # overheated saws don't cut
		grinding = _tools.cut(delta) if _tools.is_special() else _apply_damage(delta)
	_heat.tick(delta, grinding, is_held())
	grinding = _orbit.cut(delta) or grinding    # mini saws: free cutting
	Sfx.saw(is_held(), grinding, _hit_mat)
	_update_spin(delta)
	_update_lift(delta)
	_update_trail()


func is_held() -> bool: return _touch_index != -1


func _update_spin(delta: float) -> void:
	var speed_t := clampf(velocity.length() / swipe_speed, 0.0, 1.0)
	var target_rpm := lerpf(base_rpm, max_rpm, speed_t) if is_held() else idle_rpm
	if not _heat.can_cut():
		target_rpm = 0.0                # stalled: overheated
	rpm = lerpf(rpm, target_rpm, 1.0 - exp(-spool_rate * delta))
	_saw.rotation = wrapf(_saw.rotation + rpm / 60.0 * TAU * delta, 0.0, TAU)
	if _shadow:
		_shadow.rotation = _saw.rotation


func _update_lift(delta: float) -> void:
	var target := 1.0 if is_held() else 0.0
	_lift = lerpf(_lift, target, 1.0 - exp(-lift_rate * delta))
	var s := Vector2.ONE * punch_scale * (1.0 + 0.07 * _lift)
	var jitter := Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5)) if grinding else Vector2.ZERO
	_saw.scale = s
	_saw.position = jitter
	_heat.scale = s
	_heat.position = jitter
	if _shadow:
		_shadow.scale = s
		_shadow.position = SHADOW_REST.lerp(SHADOW_LIFTED, _lift) + jitter


func _update_trail() -> void:
	_trail.add_point(global_position)
	while _trail.get_point_count() > trail_length:
		_trail.remove_point(0)


func _punch(from_scale: float) -> void:
	if _punch_tween and _punch_tween.is_valid():
		_punch_tween.kill()
	punch_scale = from_scale
	_punch_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(self, "punch_scale", 1.0, 0.55)


func _build_collision() -> void:
	_body_shape = CircleShape2D.new()
	_body_shape.radius = radius
	_heat.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = _body_shape
	add_child(cs)


## RPM -> cutting power, SIZE -> bigger saw (visual, hitbox, body, trail).
func _on_upgrades_changed() -> void:
	damage_mult = Economy.damage_mult()
	radius = _base_radius * Economy.size_mult()
	_saw.set("radius", radius)
	if _shadow:
		_shadow.set("radius", radius)
	_body_shape.radius = radius
	_heat.radius = radius
	(_query.shape as CircleShape2D).radius = radius * 1.02
	_trail.width = radius * 1.15
	_orbit.rebuild()
	_punch(1.3)


## Damages every part under the saw (direct shape query). True if anything was cut.
## A weak point under the saw takes all the damage (aim pays off).
func _apply_damage(delta: float) -> bool:
	_query.transform = Transform2D(0.0, global_position)
	var bodies := {}
	var focus := false
	_drag = 1.0
	for r in get_world_2d().direct_space_state.intersect_shape(_query, 48):
		var body: Object = r["collider"]
		if body != null and body.has_method("take_damage"):
			bodies[body] = true
			focus = focus or (body is Block and body.weak and body.state == Block.State.ATTACHED)
	var dmg := damage_per_second * damage_mult * clampf(rpm / base_rpm, 0.4, 3.0) * delta
	for body in bodies:
		if focus and not (body is Block and body.weak and body.state == Block.State.ATTACHED):
			continue
		var contact: Vector2 = global_position \
			+ ((body as Node2D).global_position - global_position).limit_length(radius * 0.9)
		if body is Block and Materials.DRAG[body.mat] <= _drag:
			_drag = Materials.DRAG[body.mat]; _hit_mat = body.mat
		body.take_damage(dmg, contact, velocity)
	return not bodies.is_empty()


func _build_hitbox() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius * 1.02
	_query = PhysicsShapeQueryParameters2D.new()
	_query.shape = shape
	_query.collision_mask = 2             # "blocks"
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
