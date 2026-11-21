class_name SplashRecipes
## Five splash personalities. Each recipe fills a PaintSplash via its builder
## API; size, counts, angles and colours are randomised inside every recipe,
## so no two splashes match even within the same style.
##   BURST  - classic hit: blob + flung droplets that arc under gravity
##   SMEAR  - brush stroke dragged along the blade's path, parallel bristle streaks
##   DRIP   - heavy blob with paint runs sliding down the page
##   SPRAY  - airbrush cloud of fine two-tone mist, tiny core
##   CROWN  - concentric two-colour puddle ringed with short spikes and dots

enum Style { BURST, SMEAR, DRIP, SPRAY, CROWN }


## Weighted pick. Fast swipes favour SMEAR, big hits favour CROWN/BURST,
## and the previous style is heavily discouraged so it never feels repetitive.
static func pick(strength: float, speed: float, last: int) -> int:
	var w := [
		3.0,                                   # BURST
		0.6 + clampf(speed / 1500.0, 0.0, 3.0),  # SMEAR
		2.0,                                   # DRIP
		1.6,                                   # SPRAY
		1.2 + strength * 2.0,                  # CROWN
	]
	if last >= 0 and last < w.size():
		w[last] *= 0.15
	var total := 0.0
	for v in w:
		total += v
	var roll := randf() * total
	for i in w.size():
		roll -= w[i]
		if roll <= 0.0:
			return i
	return Style.BURST


static func build(s, style: int, k: float) -> void:
	var scale := randf_range(0.75, 1.3)   # overall size variety
	match style:
		Style.SMEAR: _smear(s, k, scale)
		Style.DRIP: _drip(s, k, scale)
		Style.SPRAY: _spray(s, k, scale)
		Style.CROWN: _crown(s, k, scale)
		_: _burst(s, k, scale)


static func _burst(s, k: float, sc: float) -> void:
	var r := lerpf(26.0, 62.0, k) * sc
	s.add_blob(Vector2.ZERO, r, randf_range(1.0, 1.35), false)
	if randf() < 0.55:
		s.add_blob(s.dir * r * 0.7 + _jit(r * 0.3), r * randf_range(0.35, 0.55), 1.0, true)
	s.gravity = randf_range(500.0, 900.0)
	s.drag = 4.0
	for i in int(lerpf(7.0, 13.0, k)):
		var d: Vector2 = s.dir.rotated(randf_range(-1.3, 1.3)) if randf() > 0.3 \
			else Vector2.from_angle(randf() * TAU)
		var size := pow(randf(), 2.2)   # mostly small, a few fat ones
		s.add_drop(d * r * 0.5, d * randf_range(350.0, 1400.0) * lerpf(0.7, 1.2, k),
			lerpf(4.5, 15.0, size), randf_range(0.1, 0.3), randf() < 0.6, randf() < 0.25)
	_specks(s, r * 2.6, int(lerpf(8.0, 22.0, k)), 1.6, 0.3)
	if randf() < 0.35:
		_drips(s, r, randi_range(1, 2))


static func _smear(s, k: float, sc: float) -> void:
	var r := lerpf(22.0, 46.0, k) * sc
	s.gloss = false
	s.drag = 1.5
	s.add_blob(s.dir * r * 0.8, r, randf_range(2.2, 3.4), false)
	s.add_blob(s.dir * r * 2.6, r * 0.5, randf_range(1.6, 2.2), randf() < 0.5)
	var side: Vector2 = s.dir.orthogonal()
	for i in int(lerpf(5.0, 9.0, k)):
		var off: Vector2 = side * randf_range(-r * 0.8, r * 0.8) + s.dir * r * 1.6
		var d: Vector2 = s.dir.rotated(randf_range(-0.1, 0.1))
		s.add_drop(off, d * randf_range(600.0, 1500.0), randf_range(3.5, 7.5),
			randf_range(0.14, 0.3), randf() < 0.4, randf() < 0.15)
	_specks(s, r * 4.0, 10, 0.35, 0.2)


static func _drip(s, k: float, sc: float) -> void:
	var r := lerpf(30.0, 60.0, k) * sc
	s.add_blob(Vector2.ZERO, r, randf_range(1.0, 1.2), false)
	s.add_blob(_jit(r * 0.4), r * randf_range(0.4, 0.6), 1.0, true)
	s.gravity = 1800.0
	s.drag = 3.0
	for i in randi_range(4, 7):
		var d: Vector2 = s.dir.rotated(randf_range(-1.0, 1.0))
		s.add_drop(d * r * 0.6, d * randf_range(300.0, 800.0) + Vector2(0.0, -250.0),
			randf_range(3.0, 8.0), randf_range(0.2, 0.35), true, false)
	_drips(s, r, randi_range(3, 5))
	_specks(s, r * 2.0, 10, PI, 0.25)


static func _spray(s, k: float, sc: float) -> void:
	var r := lerpf(14.0, 28.0, k) * sc
	s.gloss = false
	s.add_blob(Vector2.ZERO, r, 1.0, false)
	_specks(s, r * 5.0, int(lerpf(30.0, 48.0, k)), 0.75, 0.45)
	for i in 8:
		var d: Vector2 = s.dir.rotated(randf_range(-0.6, 0.6))
		s.add_drop(d * r, d * randf_range(700.0, 1600.0), randf_range(2.5, 5.5),
			randf_range(0.08, 0.2), true, randf() < 0.45)


static func _crown(s, k: float, sc: float) -> void:
	var r := lerpf(30.0, 56.0, k) * sc
	s.add_blob(Vector2.ZERO, r, 1.0, false)
	s.add_blob(Vector2.ZERO, r * randf_range(0.45, 0.6), 1.0, true)  # concentric core
	var n := randi_range(10, 16)
	var start := randf() * TAU
	for i in n:
		var d := Vector2.from_angle(start + TAU * i / n + randf_range(-0.1, 0.1))
		s.add_drop(d * r * 0.8, d * randf_range(250.0, 480.0), randf_range(3.5, 8.0),
			randf_range(0.08, 0.15), true, i % 3 == 0)
	_specks(s, r * 2.3, 14, PI, 0.35)


# --- Shared helpers -----------------------------------------------------------

static func _specks(s, dist: float, n: int, spread: float, accent_chance: float) -> void:
	for i in n:
		var d: Vector2 = s.dir.rotated(randf_range(-spread, spread))
		s.add_speck(d * randf_range(dist * 0.35, dist), randf_range(1.8, 4.8),
			randf() < accent_chance)


## Paint runs sliding down from the lower half of the blob.
static func _drips(s, r: float, n: int) -> void:
	for i in n:
		var x := randf_range(-r * 0.7, r * 0.7)
		var start := Vector2(x, sqrt(maxf(r * r - x * x, 0.0)) * 0.6)
		var width := randf_range(5.0, 11.0) * (1.0 - absf(x) / r * 0.5)
		s.add_drip(start, randf_range(60.0, 280.0), width, randf_range(0.6, 1.4))


static func _jit(m: float) -> Vector2:
	return Vector2(randf_range(-m, m), randf_range(-m, m))
