extends Node
## Centralised game feel: trauma-based Perlin camera shake, hit-stop, pooled popups.
## Gameplay code talks to EventBus; this node listens. Direct calls also work.

const MAX_OFFSET := Vector2(70.0, 95.0)  # px at trauma = 1
const MAX_ROLL := 0.07                   # radians at trauma = 1
const TRAUMA_DECAY := 1.4                # trauma lost per second
const NOISE_SPEED := 28.0                # higher = more frantic shake
const HITSTOP_TIME_SCALE := 0.02         # near-freeze, not a hard 0
const SLOWMO_ZOOM := 1.14
const HITSTOP_GAP := 260                 # ms between small freezes

## 0 = shake off, 1 = full. Wire this to a settings toggle later.
var shake_strength: float = 1.0
var trauma: float = 0.0
## Settings toggle later.
var haptics_enabled: bool = true
var _last_buzz_ms: int = 0

var _noise := FastNoiseLite.new()
var _noise_t: float = 0.0
var _hitstop_until_ms: int = 0
var _last_hitstop_ms: int = 0
var _slowmo_until_ms: int = 0
var _slowmo_scale: float = 1.0
var _slowmo_focus := Vector2.ZERO
var _cam_home := Vector2.ZERO
var _cam_found: bool = false
var _last_us: int = 0
var _shaking: bool = false
var _popups: FloatingTextPool


func _ready() -> void:
	# Keep ticking during pause and while time_scale is crushed by hit-stop.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.seed = randi()
	_noise.frequency = 1.0

	_popups = FloatingTextPool.new()
	add_child(_popups)

	EventBus.impact.connect(impact)
	EventBus.shake_requested.connect(add_trauma)
	EventBus.hitstop_requested.connect(hit_stop)
	EventBus.popup_requested.connect(popup)
	EventBus.grind_tick.connect(_on_grind_tick)


func _process(delta: float) -> void:
	_update_time_scale()
	_update_shake(delta)
	_update_zoom()


# --- Public API -----------------------------------------------------------

## One call for "something got hit". Scales shake; big hits freeze time.
func impact(_world_pos: Vector2, strength: float) -> void:
	strength = clampf(strength, 0.0, 1.0)
	var kick := lerpf(0.22, 0.7, strength)
	# Rapid hits raise the shake to the biggest one, plus a little: a long combo
	# rumbles hard without pinning the camera at full shake.
	trauma = clampf(maxf(trauma, kick) + kick * 0.15, 0.0, 1.0)
	if strength >= 0.95:     # only the big moments freeze, and only briefly
		hit_stop(55)
	buzz(roundi(lerpf(8.0, 40.0, strength)), lerpf(0.25, 1.0, strength))
	

## Phone haptics: short tick for small hits, a heavier thump for big ones.
## Rate-limited so rapid combos stay crisp instead of becoming one long buzz.
func buzz(duration_ms: int, amplitude: float) -> void:
	if not haptics_enabled or not OS.has_feature("mobile"):
		return
	var now := Time.get_ticks_msec()
	if now - _last_buzz_ms < 45:
		return
	_last_buzz_ms = now
	Input.vibrate_handheld(duration_ms, clampf(amplitude, 0.05, 1.0))


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Freezes the game for duration_ms of real time. Overlapping calls extend it.
## Rate-limited (at most one small freeze per HITSTOP_GAP ms) so a long
## combo stays fluid instead of turning into slow motion.
func hit_stop(duration_ms: int = 30) -> void:
	duration_ms = clampi(duration_ms, 10, 120)
	var now := Time.get_ticks_msec()
	if now - _last_hitstop_ms < (HITSTOP_GAP if duration_ms < 80 else 120):
		return
	_last_hitstop_ms = now
	_hitstop_until_ms = maxi(_hitstop_until_ms, now + duration_ms)
	_update_time_scale()


## Slow motion + a gentle camera push toward `focus` (golden parts).
## duration_ms is real time.
func slowmo(focus: Vector2, duration_ms: int = 650, time_scale: float = 0.25) -> void:
	_slowmo_until_ms = Time.get_ticks_msec() + duration_ms
	_slowmo_scale = time_scale
	_slowmo_focus = focus
	_update_time_scale()


func popup(text: String, world_pos: Vector2, color: Color, size_mult: float = 1.0) -> void:
	_popups.spawn(text, world_pos, color, size_mult)


# --- Internals ------------------------------------------------------------

## Grinding: a light constant rumble, never enough to saturate the shake.
func _on_grind_tick(_world_pos: Vector2, mat: int) -> void:
	var metal := mat == Materials.METAL       # metal fights back: harder buzz, more rumble
	if trauma < (0.4 if metal else 0.3):
		add_trauma(0.07 if metal else 0.04)
	buzz(18 if metal else 10, 0.55 if metal else 0.22)


func _update_time_scale() -> void:
	var now := Time.get_ticks_msec()
	var ts := 1.0
	if now < _slowmo_until_ms:
		ts = _slowmo_scale
	if now < _hitstop_until_ms:
		ts = HITSTOP_TIME_SCALE
	Engine.time_scale = ts


## Zoom in during slow-mo, ease back out after. Uses real time.
func _update_zoom() -> void:
	var now_us := Time.get_ticks_usec()
	var dt := clampf((now_us - _last_us) / 1000000.0, 0.0, 0.1)
	_last_us = now_us
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	if not _cam_found:
		_cam_found = true
		_cam_home = cam.position
	var slow := Time.get_ticks_msec() < _slowmo_until_ms
	if not slow and is_equal_approx(cam.zoom.x, 1.0):
		return
	var z := lerpf(cam.zoom.x, SLOWMO_ZOOM if slow else 1.0, 1.0 - exp(-9.0 * dt))
	if not slow and absf(z - 1.0) < 0.002:
		z = 1.0
	cam.zoom = Vector2(z, z)
	# Lean toward the focus, but never show past the edge of the page.
	var max_off := get_viewport().get_visible_rect().size * 0.5 * (1.0 - 1.0 / z)
	var off := (_slowmo_focus - _cam_home).clamp(-max_off, max_off)
	cam.position = _cam_home + off


func _update_shake(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	if trauma <= 0.0:
		if _shaking:  # settle exactly once, then stop touching the camera
			cam.offset = Vector2.ZERO
			cam.rotation = 0.0
			_shaking = false
		return

	_shaking = true
	# delta is time-scaled, so the shake freezes during hit-stop (intended).
	trauma = maxf(trauma - TRAUMA_DECAY * delta, 0.0)
	_noise_t += delta * NOISE_SPEED

	var s := pow(trauma, 1.5) * shake_strength  # punchy falloff, small hits still read
	cam.offset = Vector2(
		MAX_OFFSET.x * s * _noise.get_noise_2d(_noise_t, 0.0),
		MAX_OFFSET.y * s * _noise.get_noise_2d(_noise_t, 100.0)
	)
	cam.rotation = MAX_ROLL * s * _noise.get_noise_2d(_noise_t, 200.0)
