class_name Thrown
extends Structure
## RUSH: an object tossed up from the bottom (or across), spinning, under
## gravity. The first slice bursts the whole thing apart (the parts the
## swipe crossed shatter, the rest flies off, still sliceable in the air).
## Bombs: slicing one costs you time. Falling off the bottom unsliced = miss.

signal missed(thing: Thrown)
signal sliced(thing: Thrown)

const GRAVITY := 1500.0

var vel := Vector2.ZERO
var spin := 0.0
var is_bomb: bool = false
var _sliced: bool = false


func launch(at: Vector2, v: Vector2, s: float) -> void:
	global_position = at
	vel = v
	spin = s
	_place_blocks()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	vel.y += GRAVITY * delta
	global_position += vel * delta
	_angle += spin * delta
	_place_blocks()
	if global_position.y > 2650.0:
		_active = false
		if not _sliced:
			missed.emit(self)
		queue_free()


func _refresh_weak() -> void:
	pass                                   # no weak-point outlines in Rush: keep it clean


func _plan() -> void:
	pass                                   # no clock/par in Rush (also saves ~5 ms per throw)


func _on_block_destroyed(b: Block, shattered: bool) -> void:
	if not _sliced:
		_sliced = true
		sliced.emit(self)
		if is_bomb:
			EventBus.bomb_hit.emit(global_position)
		_burst()
	super(b, shattered)


## Everything still attached flies apart from the centre.
func _burst() -> void:
	for i in _blocks.size():
		if _is_attached(i):
			var p: Block = _blocks[i]
			var out := (p.global_position - global_position).normalized()
			# Mostly the way you swiped (aim for the bins), a little burst outward.
			p.set_loose(Slicer.last_vel * randf_range(0.55, 0.8) + out * randf_range(120.0, 260.0))
