class_name FragmentPool
extends Node2D
## Owns every Fragment. All are created once; shatters recycle them in a
## ring buffer so breaking things never allocates mid-game.

const POOL_SIZE := 72                 # v14: was 110 (each shard = 1 draw call)

var _pool: Array[Fragment] = []
var _next: int = 0
static var _me: FragmentPool


func _ready() -> void:
	_me = self
	for i in POOL_SIZE:
		var f := Fragment.new()
		add_child(f)
		_pool.append(f)
	EventBus.fragments_requested.connect(_spawn)


func _spawn(at: Vector2, color: Color, count: int, size: float, vel: Vector2, value_each: int) -> void:
	for i in count:
		var f := _pool[_next]
		_next = (_next + 1) % POOL_SIZE
		var dir := Vector2.from_angle(randf() * TAU)
		var v := vel.limit_length(900.0) * 0.35 \
			+ dir * randf_range(220.0, 620.0) + Vector2(0.0, -180.0)
		f.activate(at + dir * size * 0.5, _random_poly(size * randf_range(0.7, 1.15)),
			color, v, randf_range(-9.0, 9.0), value_each)


## A bit the saw split off a part (Carve): falls as one loose chunk.
static func chunk(at: Vector2, poly: PackedVector2Array, color: Color, vel: Vector2, value: int) -> void:
	if _me == null:
		return
	var f := _me._pool[_me._next]
	_me._next = (_me._next + 1) % POOL_SIZE
	f.activate(at, poly, color, vel, randf_range(-5.0, 5.0), value)


## Irregular 4-6 sided shard.
func _random_poly(size: float) -> PackedVector2Array:
	var n := randi_range(4, 6)
	var start := randf() * TAU
	var pts := PackedVector2Array()
	for i in n:
		var a := start + TAU * i / n + randf_range(-0.3, 0.3) * TAU / n
		pts.append(Vector2.from_angle(a) * size * randf_range(0.6, 1.0))
	return pts
