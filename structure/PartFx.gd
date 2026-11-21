class_name PartFx
## What happens when a part breaks or comes loose, so Block stays small:
##   burst():   shards by material, then the part's own behaviour:
##              spill (piggy-bank coins, candy, gears bursting out) and its
##              own sound (a guitar string's note, a bell, a squeak).
##   on_loose(): thrown objects keep their speed; gold floats down slowly;
##              rubber bounces off the pegs.

static var _bounce: PhysicsMaterial


static func burst(b: Block, vel: Vector2) -> void:
	var at := b.global_position
	EventBus.block_shattered.emit(at, b.paint_color, b.value, vel, b.mat)
	var count := clampi(int(b._area / 1600.0 * Materials.SHARDS[b.mat]), 2, 9)
	var each := maxi(1, int(round(b.value * 0.6 * b._gate_mult * Economy.value_mult() * b._area / b._area0 / count)))
	EventBus.fragments_requested.emit(at, b.color, count,
		clampf(sqrt(b._area) * 0.26 * Materials.SIZE[b.mat], 6.0, 34.0), vel + b.linear_velocity, each)
	if b.spill > 0:                       # the good stuff bursts out
		var coin := maxi(1, int(round(b.value * 0.4 * Economy.value_mult())))
		EventBus.fragments_requested.emit(at, b.spill_color, b.spill, randf_range(10.0, 14.0),
			Vector2(0.0, -900.0), coin)
		Sfx.play("coins" if b.spill_color == ThemePalette.BUTTER else "pop", 1.0, 0.0, 0.1)
	if b.sound != "":
		Sfx.play(b.sound, b.note, 0.0, 0.01 if b.sound == "twang" else 0.08)


static func on_loose(b: Block, fling: Vector2) -> void:
	var host_vel = b.get_parent().get("vel")    # thrown objects: pieces keep flying
	if host_vel is Vector2:
		b.linear_velocity += host_vel * 0.7
	if b.golden:                                # floats down slowly: time to catch it
		b.gravity_scale = 0.3
		b.linear_velocity = Vector2(fling.x * 0.3, -380.0)
	if b.bouncy:
		if _bounce == null:
			_bounce = PhysicsMaterial.new()
			_bounce.bounce = 0.8
			_bounce.friction = 0.1
		b.physics_material_override = _bounce
		b.collision_mask |= 16                  # rubber bounces off the pegs
		b.linear_velocity += Vector2(randf_range(-300.0, 300.0), -500.0)
