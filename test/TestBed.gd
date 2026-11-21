extends Node2D
## Phase 1 juice testbed (attach to the Main scene root).
## Device:  drag = blade, fast swipe = small hit + paint splash + combo popup,
##          tap a SECOND finger = big hit (hit-stop + heavy shake + big splash).
## Desktop: 1 = small hit, 2 = big hit, 3 = 8-popup burst, C = wash the paint off.

const COMBO_RESET := 1.0

@onready var _blade: Node2D = $DeconstructorBlade

var _combo: int = 0
var _since_swipe: float = 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(ThemePalette.PAPER)
	EventBus.blade_swiped.connect(_on_blade_swiped)


func _process(delta: float) -> void:
	_since_swipe += delta
	if _combo > 0 and _since_swipe > COMBO_RESET:
		_combo = 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _small_hit(_blade.global_position, _blade_velocity())
			KEY_2: _big_hit()
			KEY_3: _burst()
			KEY_C: EventBus.paint_clear_requested.emit()
	elif event is InputEventScreenTouch and event.pressed and event.index >= 1:
		_big_hit()


func _on_blade_swiped(pos: Vector2, velocity: Vector2) -> void:
	_since_swipe = 0.0
	_small_hit(pos, velocity)


func _small_hit(pos: Vector2, velocity: Vector2) -> void:
	_combo += 1
	var points := _combo * 3
	var strength := clampf(velocity.length() / 7000.0, 0.25, 0.6)
	# Combo escalation: every chained hit makes the splash juicier.
	var combo_boost := minf(_combo * 0.05, 0.4)
	EventBus.impact.emit(pos, strength)
	EventBus.splash.emit(pos, velocity, strength + 0.1 + combo_boost)
	EventBus.popup_requested.emit("+%d" % points, pos + Vector2(0.0, -130.0),
		ThemePalette.random_text_accent(), 1.0 + minf(_combo * 0.05, 0.6))
	EventBus.score_added.emit(points)


func _big_hit() -> void:
	var pos := _blade.global_position
	var vel := _blade_velocity()
	EventBus.impact.emit(pos, 1.0)
	# Two overlapping splashes in different colours for a heavier burst
	EventBus.splash.emit(pos, vel, 1.0)
	EventBus.splash.emit(pos, -vel if vel.length() > 1.0 else Vector2.ZERO, 0.7)
	EventBus.popup_requested.emit("SHATTER!", pos + Vector2(0.0, -160.0),
		ThemePalette.RED, 1.4)
	EventBus.score_added.emit(100)


func _burst() -> void:
	for i in 8:
		var offset := Vector2(randf_range(-320.0, 320.0), randf_range(-400.0, 200.0))
		EventBus.popup_requested.emit("x%d" % (i + 2), _blade.global_position + offset,
			ThemePalette.random_text_accent(), randf_range(0.8, 1.2))


func _blade_velocity() -> Vector2:
	var v: Variant = _blade.get("velocity")
	return v if v is Vector2 else Vector2.ZERO
