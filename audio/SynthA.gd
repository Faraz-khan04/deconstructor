class_name SynthA
## Sound effects built from maths at startup (no audio files): the saw, and
## how each material breaks. Mono 16-bit at RATE Hz. See SynthB for the rest.

const RATE := 22050


static func all() -> Dictionary:
	return {
		"whir": wav(_whir(), true), "grind": wav(_grind(), true),
		"crack": wav(_crack()), "glass": wav(_glass()), "metal": wav(_metal()),
		"squish": wav(_squish()), "zap": wav(_zap()), "thud": wav(_thud()),
		"whoosh": wav(_whoosh()), "shred": wav(_shred()),
	}


static func wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


static func buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Smoothly blend the end into the start so a noisy loop has no click.
static func loopify(b: PackedFloat32Array, fade: int) -> PackedFloat32Array:
	var n := b.size() - fade
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = b[i]
		if i < fade:
			var k := float(i) / fade
			out[i] = b[i] * k + b[n + i] * (1.0 - k)
	return out


## Idle whir: a soft buzzing hum (exactly 44 cycles so it loops cleanly).
static func _whir() -> PackedFloat32Array:
	var b := buffer(0.4)
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for h in range(1, 6):
			v += sin(TAU * 110.0 * h * t) / h
		b[i] = v * 0.22 * (0.85 + 0.15 * sin(TAU * 22.5 * t))
	return b


## Biting into something: gritty, chattering band of noise over a low growl.
static func _grind() -> PackedFloat32Array:
	var b := buffer(0.6)
	var lo := 0.0
	var lo2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf_range(-1.0, 1.0)
		lo += 0.35 * (n - lo)
		lo2 += 0.04 * (n - lo2)
		var chatter := 0.6 + 0.4 * signf(sin(TAU * 28.0 * t))
		b[i] = ((lo - lo2) * 0.9 * chatter + signf(sin(TAU * 56.0 * t)) * 0.08) * 0.8
	return loopify(b, int(0.1 * RATE))


## Plastic: a short dry crack with a knock under it.
static func _crack() -> PackedFloat32Array:
	var b := buffer(0.16)
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf_range(-1.0, 1.0)
		lo += 0.5 * (n - lo)
		b[i] = (n - lo * 0.6) * exp(-45.0 * t) * 0.8 + sin(TAU * 230.0 * t) * exp(-28.0 * t) * 0.45
	return b


## Glass: a bright burst, then little shards tinkling down.
static func _glass() -> PackedFloat32Array:
	var b := buffer(0.55)
	var tones: Array = []
	for k in 7:
		tones.append([randf_range(2100.0, 5600.0), randf_range(6.0, 14.0), randf_range(0.0, 0.09)])
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf_range(-1.0, 1.0)
		lo += 0.6 * (n - lo)
		var v := (n - lo) * exp(-30.0 * t) * 0.7
		for tone in tones:
			var tt: float = t - tone[2]
			if tt > 0.0:
				v += sin(TAU * tone[0] * tt) * exp(-tone[1] * tt) * 0.11
		b[i] = v
	return b


## Metal: a clang with the uneven overtones of a struck plate.
static func _metal() -> PackedFloat32Array:
	var b := buffer(0.6)
	var parts := [[1.0, 0.45, 6.0], [2.76, 0.3, 8.0], [5.4, 0.18, 11.0], [8.93, 0.1, 15.0]]
	for i in b.size():
		var t := float(i) / RATE
		var v := randf_range(-1.0, 1.0) * exp(-200.0 * t) * 0.6
		for p in parts:
			v += sin(TAU * 520.0 * p[0] * t) * exp(-p[2] * t) * p[1]
		b[i] = v * 0.8
	return b


## Fruit: a wet splat with a falling "blub".
static func _squish() -> PackedFloat32Array:
	var b := buffer(0.3)
	var lo := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lo += 0.09 * (randf_range(-1.0, 1.0) - lo)
		ph += TAU * (70.0 + 220.0 * exp(-14.0 * t)) / RATE
		var env := minf(t / 0.008, 1.0) * exp(-12.0 * t)
		b[i] = lo * 2.6 * env + sin(ph) * exp(-14.0 * t) * 0.5
	return b


## Electronics: a quick zap that drops in pitch.
static func _zap() -> PackedFloat32Array:
	var b := buffer(0.22)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (120.0 + 1600.0 * exp(-12.0 * t)) / RATE
		b[i] = (signf(sin(ph)) * 0.3 + randf_range(-0.1, 0.1)) * exp(-10.0 * t)
	return b


## A heavy section landing: deep thump.
static func _thud() -> PackedFloat32Array:
	var b := buffer(0.4)
	var ph := 0.0
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (40.0 + 90.0 * exp(-10.0 * t)) / RATE
		lo += 0.2 * (randf_range(-1.0, 1.0) - lo)
		b[i] = sin(ph) * exp(-8.0 * t) * 0.95 + lo * exp(-30.0 * t) * 0.8
	return b


## Air rushing past (a big chunk dropping away).
static func _whoosh() -> PackedFloat32Array:
	var b := buffer(0.45)
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / 0.45
		lo += (0.02 + 0.25 * sin(PI * k)) * (randf_range(-1.0, 1.0) - lo)
		b[i] = lo * pow(sin(PI * k), 2.0) * 1.4
	return b


## The shredder eating a piece: low chattering crunch.
static func _shred() -> PackedFloat32Array:
	var b := buffer(0.18)
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lo += 0.15 * (randf_range(-1.0, 1.0) - lo)
		b[i] = lo * absf(sin(TAU * 35.0 * t)) * exp(-12.0 * t) * 1.6
	return b
