class_name SynthB
## Musical sounds made in code: peg pings, coins, gates, buttons, stars,
## winning, failing, gold, title cards, the clock.

const RATE := 22050


static func all() -> Dictionary:
	return {
		"ping": SynthA.wav(_ping()), "coin": SynthA.wav(_coin()), "gate": SynthA.wav(_gate()),
		"tick": SynthA.wav(_tick()), "buy": SynthA.wav(_buy()), "star": SynthA.wav(_star()),
		"win": SynthA.wav(_notes([523.3, 659.3, 784.0, 1046.5], 0.11, 1.1, 5.0)),
		"gold": SynthA.wav(_notes([1046.5, 1318.5, 1568.0, 2093.0, 2637.0], 0.05, 0.8, 7.0)),
		"fail": SynthA.wav(_fail()), "card": SynthA.wav(_card()),
		"slash": SynthA.wav(_slash()), "boom": SynthA.wav(_boom()),
		"catch": SynthA.wav(_notes([1568.0, 2093.0], 0.035, 0.22, 16.0)),
	}


## Several bell-ish notes, one after another (arpeggio).
static func _notes(freqs: Array, gap: float, seconds: float, decay: float) -> PackedFloat32Array:
	var b := SynthA.buffer(seconds)
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for k in freqs.size():
			var tt: float = t - k * gap
			if tt > 0.0:
				v += (sin(TAU * freqs[k] * tt) + 0.3 * sin(TAU * freqs[k] * 2.0 * tt)) * exp(-decay * tt)
		b[i] = v * 0.22
	return b


## Pinball peg: a clear little bell (pitched per peg to play a scale).
static func _ping() -> PackedFloat32Array:
	var b := SynthA.buffer(0.4)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 523.3 * t) * exp(-9.0 * t) + 0.25 * sin(TAU * 1046.5 * t) * exp(-15.0 * t)) * 0.45
	return b


## Coin landing on the pile: two bright clinks.
static func _coin() -> PackedFloat32Array:
	var b := SynthA.buffer(0.25)
	for i in b.size():
		var t := float(i) / RATE
		var v := (sin(TAU * 1975.5 * t) + sin(TAU * 2637.0 * t) * 0.7) * exp(-22.0 * t)
		var t2 := t - 0.05
		if t2 > 0.0:
			v += (sin(TAU * 2637.0 * t2) + sin(TAU * 3951.0 * t2) * 0.5) * exp(-20.0 * t2)
		b[i] = v * 0.18
	return b


## A piece passing a gate: rising blip.
static func _gate() -> PackedFloat32Array:
	var b := SynthA.buffer(0.14)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (500.0 + 6000.0 * t) / RATE
		b[i] = signf(sin(ph)) * 0.12 * (1.0 - t / 0.14)
	return b


## Clock tick / soft button click.
static func _tick() -> PackedFloat32Array:
	var b := SynthA.buffer(0.06)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 1800.0 * t) * exp(-70.0 * t) * 0.5
	return b


## Buying an upgrade: ka-ching.
static func _buy() -> PackedFloat32Array:
	var b := _notes([1318.5, 1975.5], 0.07, 0.4, 9.0)
	var c := _coin()
	for i in c.size():
		b[i] += c[i]
	return b


## A star slamming onto the result card: thump + bright chord.
static func _star() -> PackedFloat32Array:
	var b := SynthA.buffer(0.7)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (60.0 + 120.0 * exp(-12.0 * t)) / RATE
		var v := sin(ph) * exp(-12.0 * t) * 0.6
		for f in [1046.5, 1318.5, 1568.0]:
			v += sin(TAU * f * t) * exp(-5.0 * t) * 0.14
		b[i] = v
	return b


## Time's up: three sad notes sliding down.
static func _fail() -> PackedFloat32Array:
	var b := SynthA.buffer(1.0)
	var notes := [392.0, 370.0, 349.2, 329.6]
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := mini(int(t / 0.2), 3)
		var f: float = notes[k] * (1.0 - (0.04 * (t - 0.6) if k == 3 else 0.0))
		ph += TAU * f / RATE
		var local := t - k * 0.2
		var env := minf(local / 0.01, 1.0) * (exp(-3.0 * local) if k == 3 else exp(-6.0 * local))
		b[i] = (asin(sin(ph)) / (PI * 0.5)) * env * 0.35        # triangle wave
	return b


## Title card slapped on: thump + snare hiss.
static func _card() -> PackedFloat32Array:
	var b := SynthA.buffer(0.35)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (55.0 + 100.0 * exp(-14.0 * t)) / RATE
		b[i] = sin(ph) * exp(-9.0 * t) * 0.7 + randf_range(-1.0, 1.0) * exp(-22.0 * t) * 0.35
	return b


## A blade swishing through the air: quick high noise sweep.
static func _slash() -> PackedFloat32Array:
	var b := SynthA.buffer(0.16)
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf_range(-1.0, 1.0)
		lo += (0.05 + t * 4.0) * (n - lo)
		b[i] = (n - lo) * sin(PI * t / 0.16) * 0.55
	return b


## Bomb: a big low boom with a long rumble.
static func _boom() -> PackedFloat32Array:
	var b := SynthA.buffer(1.1)
	var ph := 0.0
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (30.0 + 90.0 * exp(-6.0 * t)) / RATE
		lo += 0.06 * (randf_range(-1.0, 1.0) - lo)
		b[i] = sin(ph) * exp(-3.5 * t) * 0.8 + lo * 3.0 * exp(-2.5 * t)
	return b
