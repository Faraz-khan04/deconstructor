class_name Block
extends RigidBody2D
## One cuttable part of a real-world object (a key, a pad, a reel, a slab...).
## ATTACHED: held in place by its object. LOOSE: cut free, falls, still cuttable.
## CHEWING: wedged in the shredder for a moment. DEAD: shattered into shards.
## Locked by its object (boss shells, gold while attached): the saw just sparks.
## `mat` (Materials) sets how it cuts and breaks; `weak` = glowing weak point.

signal destroyed(block: Block, shattered: bool)

enum State { ATTACHED, LOOSE, CHEWING, DEAD }

const CHEW_TIME := 0.25
const BORDER := 5.0
const SHADOW_BASE := Vector2(12.0, 26.0)
const SHADOW_INLAY := Vector2(3.0, 8.0)

var index: int = -1
var color: Color
var paint_color: Color          # transparent = let PaintLayer pick a colour
var value: int = 10
var inlay: bool = false
var armor: bool = false
var screw: bool = false
var golden: bool = false; var golden_slot: int = -1
var hazard: bool = false           # lithium battery: cutting it = explosion
var spill: int = 0; var spill_color := Color.WHITE; var bouncy: bool = false
var sound: String = ""; var note: float = 1.0   # PartFx: what it does when it breaks
var mat: int = Materials.PLASTIC; var weak: bool = false; var drop: int = 0
var was_chewed: bool = false
var locked_look: bool = false
var max_hp: float = 3.0
var hp: float = 3.0
var state: State = State.ATTACHED
var rest_pos: Vector2 = Vector2.ZERO
var flash: float = 0.0:
	set(v):
		flash = v
		queue_redraw()

var _poly: PackedVector2Array
var _sticker: PackedVector2Array
var _area: float = 1.0; var _decor: Dictionary = {}
var _detail_color: Color
var _text: String = ""
var _area0: float = 1.0; var _bite_r: float = 20.0; var _carve_ms: int = 0   # Carve: eaten bit by bit
var _scar := PackedInt32Array(); var _cp: CollisionPolygon2D
var _flash_tween: Tween; var _drawn_rot: float = 0.0; var _last_tick_ms: int = 0; var _last_splash_ms: int = 0
var _prev := Vector2.ZERO           # for gate crossing while loose
var _gate_mask: int = 0; var _gate_mult: int = 1
var _loose_time: float = 0.0
var _chew_left: float = 0.0; var _chew_tick: float = 0.0
var _chew_at := Vector2.ZERO


func setup(i: int, d: Dictionary) -> void:
	index = i; _poly = d["poly"]; color = d["color"]; value = d["value"]
	max_hp = d["hp"]; hp = max_hp; mat = int(d.get("mat", Materials.PLASTIC))
	inlay = d["inlay"]; armor = d.get("armor", false); screw = d.get("screw", false)
	golden = d.get("golden", false); golden_slot = int(d.get("golden_slot", -1)); hazard = d.get("hazard", false)
	_detail_color = d["detail_color"]; _text = d["text"]; spill = int(d.get("spill", 0))
	spill_color = d.get("spill_color", ThemePalette.BUTTER); bouncy = d.get("bouncy", false)
	sound = d.get("sound", ""); note = float(d.get("note", 1.0))
	# Greys, creams and near-blacks make dull paint: swap in a juicy colour.
	paint_color = color if color.s > 0.3 and color.v > 0.25 else Color(0, 0, 0, 0)
	_area = maxf(absf(ShapeUtil.signed_area(_poly)), 1.0)
	_sticker = _poly if inlay else ShapeUtil.grow(_poly, BORDER)
	if int(d["detail"]) != ObjectLibrary.Detail.NONE:
		_decor = PartDecor.prepare(int(d["detail"]), _poly)

	var cp := CollisionPolygon2D.new()
	cp.polygon = _poly
	add_child(cp)
	_cp = cp
	collision_layer = 2       # "blocks"
	collision_mask = 0        # attached parts touch nothing physically
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	gravity_scale = 1.3
	Carve.setup(self)


func set_weak(on: bool, drops: int) -> void:
	drop = drops
	if on != weak:
		weak = on
		queue_redraw()


## Called every physics frame by the blade while it overlaps this part.
func take_damage(amount: float, hit_pos: Vector2, blade_vel: Vector2) -> void:
	if state == State.DEAD or state == State.CHEWING:
		return
	var host = get_parent()            # the Structure (untyped: custom methods)
	var locked: bool = host != null and host.has_method("is_locked") and host.is_locked(self)
	var now := Time.get_ticks_msec()
	if now - _last_tick_ms > 90:
		_last_tick_ms = now
		_do_flash()
		EventBus.grind_tick.emit(hit_pos, mat)
		if host and host.has_method("jolt"):
			host.jolt()                # whole object judders while being sawed
	if state == State.ATTACHED and Job.cur:  # Jobs: cutting spends power (locked: a little)
		Job.cur.spend(amount * 0.25 if locked else minf(amount, maxf(hp, 0.0)))
	if locked:
		return                         # sparks only: can't cut this yet
	hp -= amount
	if mat == Materials.FRUIT and now - _last_splash_ms > 300:     # juice while cutting fruit
		_last_splash_ms = now
		EventBus.splash.emit(hit_pos, blade_vel, 0.18, paint_color)
	if state == State.LOOSE:
		apply_central_impulse(blade_vel.limit_length(1500.0) * 0.015 * mass)

	if hp > 0.0 and TestSwitches.on("chew"):
		Carve.bite(self, hit_pos, blade_vel)   # chips a notch out where the saw is
	if hp <= 0.0:
		shatter(blade_vel)


func set_loose(fling: Vector2) -> void:
	if state != State.ATTACHED:
		return
	state = State.LOOSE
	_prev = global_position
	freeze = false
	collision_mask = 1 | 8    # batted by the blade, walls
	linear_velocity = fling
	angular_velocity = randf_range(-4.0, 4.0)
	PartFx.on_loose(self, fling)


func shatter(vel: Vector2) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	PartFx.burst(self, vel)                   # shards, spill, its own sound
	destroyed.emit(self, true)
	queue_free()


func _physics_process(delta: float) -> void:
	if state == State.LOOSE:
		if Catcher.catch_block(self, _prev, global_position):
			return                            # landed in a bucket
		var g := MultiplierGate.check(_prev, global_position, _gate_mask)
		_gate_mask = g.x
		_gate_mult *= g.y
		_prev = global_position
		_loose_time += delta
		if global_position.y > Grinder.INTAKE_Y - 20.0:
			_start_chewing()
			return
		if _loose_time > 4.5:                 # stuck on a peg too long
			shatter(Vector2(0.0, 300.0))
			return
	if state == State.CHEWING:
		_chew(delta)
		return
	# Glows pulse, hot edges fade, the shadow stays world-aligned. v14: 20 times
	# a second, parts take turns (redrawing every part every frame was costly).
	if (Engine.get_physics_frames() + index) % 3 == 0 and (golden or weak or hazard \
			or Carve.hot(self) or absf(angle_difference(rotation, _drawn_rot)) > 0.04):
		queue_redraw()


func _draw() -> void: BlockLook.draw(self)


func _do_flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	flash = 0.85
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "flash", 0.0, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Wedged in the shredder: shudder violently while the teeth spin up.
func _start_chewing() -> void:
	state = State.CHEWING
	freeze = true
	_chew_at = Vector2(global_position.x, Grinder.INTAKE_Y - 10.0)
	_chew_left = CHEW_TIME
	_chew_tick = 0.0


func _chew(delta: float) -> void:
	_chew_left -= delta
	_chew_tick -= delta
	global_position = _chew_at + Vector2(randf_range(-7.0, 7.0), randf_range(-5.0, 5.0))
	rotation += randf_range(-0.15, 0.15)
	if _chew_tick <= 0.0:
		_chew_tick = 0.06
		EventBus.grind_tick.emit(_chew_at + Vector2(randf_range(-20.0, 20.0), 0.0), mat)
	if _chew_left <= 0.0:
		was_chewed = true
		state = State.LOOSE                   # let shatter() run normally
		shatter(Vector2(0.0, 300.0))
