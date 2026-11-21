extends Node2D
## Cash you can see: every shard the shredder eats bursts out as a spinning
## coin that arcs up and homes in on the cash counter. The money is added
## when the coin lands, so the counter ticks up coin by coin.
## Pooled (no allocations). If every coin is busy, the cash is paid directly.

const POOL := 56
const TOP := 90.0
const R := 17.0

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _value: Array[int] = []
var _on: Array[bool] = []
var _next: int = 0
var _active: int = 0
var _ladder: float = 0.0
var _last_land_ms: int = 0


func _ready() -> void:
	z_index = 5
	for i in POOL:
		_pos.append(Vector2.ZERO)
		_vel.append(Vector2.ZERO)
		_age.append(0.0)
		_value.append(0)
		_on.append(false)
	EventBus.fragment_collected.connect(_on_collected)


func _exit_tree() -> void:
	_flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush()


func _on_collected(world_pos: Vector2, _color: Color, amount: int) -> void:
	for k in POOL:
		var i := (_next + k) % POOL
		if not _on[i]:
			_next = (i + 1) % POOL
			_on[i] = true
			_active += 1
			_pos[i] = ScreenSpace.to_screen(self, world_pos)
			_vel[i] = Vector2(randf_range(-420.0, 420.0), randf_range(-1500.0, -1050.0))
			_age[i] = 0.0
			_value[i] = amount
			return
	EventBus.score_added.emit(amount)        # all coins in the air: pay now


func _target() -> Vector2:
	return Vector2(get_viewport_rect().size.x - 150.0, TOP + 74.0)


func _process(delta: float) -> void:
	if _active == 0:
		return
	var goal := _target()
	for i in POOL:
		if not _on[i]:
			continue
		_age[i] += delta
		var a := _age[i]
		var v := _vel[i]
		if a < 0.28:
			v.y += 2600.0 * delta                    # burst up, slow down
		else:
			var want := (goal - _pos[i]).normalized() * lerpf(1600.0, 4200.0, minf((a - 0.28) * 1.5, 1.0))
			v = v.lerp(want, 1.0 - exp(-7.0 * delta))
		_pos[i] += v * delta
		_vel[i] = v
		if _pos[i].distance_squared_to(goal) < 2500.0 or a > 1.8:
			_land(i)
	queue_redraw()


func _land(i: int) -> void:
	_on[i] = false
	_active -= 1
	EventBus.score_added.emit(_value[i])
	JuiceManager.buzz(4, 0.12)
	var now := Time.get_ticks_msec()            # coins landing close together climb in pitch
	_ladder = minf(_ladder + 0.05, 0.7) if now - _last_land_ms < 150 else 0.0
	_last_land_ms = now
	Sfx.play("coin", 1.0 + _ladder, 0.0, 0.02)


func _flush() -> void:
	for i in POOL:
		if _on[i]:
			_land(i)


func _draw() -> void:
	for i in POOL:
		if not _on[i]:
			continue
		var flip := absf(cos(_age[i] * 14.0 + i))
		draw_set_transform(_pos[i], 0.0, Vector2(maxf(flip, 0.2), 1.0))
		draw_circle(Vector2(3, 5), R + 3.0, ThemePalette.SHADOW)
		draw_circle(Vector2.ZERO, R + 3.0, ThemePalette.INK)
		draw_circle(Vector2.ZERO, R, ThemePalette.BUTTER)
		draw_arc(Vector2.ZERO, R - 5.0, 0.0, TAU, 18, ThemePalette.TANGERINE, 2.5, true)
		if flip > 0.5:
			draw_string(ThemePalette.display_font, Vector2(-R, 8.0), "$", HORIZONTAL_ALIGNMENT_CENTER,
				R * 2.0, 22, ThemePalette.INK)
	draw_set_transform(Vector2.ZERO)
