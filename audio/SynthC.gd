class_name SynthC
## Character sounds for the special objects, made in code:
##   twang  plucked string (Karplus-Strong: real-sounding guitar notes)
##   squeak rubber duck   ceramic  piggy-bank clink   ring  alarm bell
##   coins  a cascade of coins   pop  candy popping out

const RATE := 22050


static func all() -> Dictionary:
	return {"twang": SynthA.wav(_twang()), "squeak": SynthA.wav(_squeak()),
		"ceramic": SynthA.wav(_ceramic()), "ring": SynthA.wav(_ring()),
		"coins": SynthA.wav(_coins()), "pop": SynthA.wav(_pop())}


## A string plucked at A3 (220 Hz); pitch_scale picks the note.
static func _twang() -> PackedFloat32Array:
	var b := SynthA.buffer(1.6)
	var n := int(RATE / 220.0)
	var line := PackedFloat32Array()
	line.resize(n)
	var lo := 0.0
	for i in n:                                  # a softened burst of noise = the pluck
		lo += 0.6 * (randf_range(-1.0, 1.0) - lo)
		line[i] = lo
	for i in b.size():
		var k := i % n
		var v := line[k]
		b[i] = v * 0.7 * minf(1.0, (b.size() - i) / 2000.0)
		line[k] = 0.5 * (v + line[(k + 1) % n]) * 0.9965
	return b


static func _squeak() -> PackedFloat32Array:
	var b := SynthA.buffer(0.3)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 900.0 + 750.0 * sin(PI * t / 0.3) + 40.0 * sin(TAU * 32.0 * t)
		ph += TAU * f / RATE
		var env := minf(t / 0.02, 1.0) * minf((0.3 - t) / 0.06, 1.0)
		b[i] = (sin(ph) + 0.35 * sin(ph * 2.0) + randf_range(-0.08, 0.08)) * env * 0.4
	return b


static func _ceramic() -> PackedFloat32Array:
	var b := SynthA.buffer(0.5)
	var lo := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf_range(-1.0, 1.0)
		lo += 0.7 * (n - lo)
		var v := (n - lo) * exp(-38.0 * t) * 0.6
		v += sin(TAU * 2900.0 * t) * exp(-13.0 * t) * 0.22 + sin(TAU * 4310.0 * t) * exp(-17.0 * t) * 0.15
		var t2 := t - 0.055
		if t2 > 0.0:
			v += sin(TAU * 3650.0 * t2) * exp(-15.0 * t2) * 0.18 + (n - lo) * exp(-45.0 * t2) * 0.3
		b[i] = v
	return b


## Alarm-clock bell: bright struck partials, hammered fast.
static func _ring() -> PackedFloat32Array:
	var b := SynthA.buffer(1.2)
	var parts := [[1.0, 0.5], [2.0, 0.3], [2.76, 0.22], [4.07, 0.14], [5.4, 0.08]]
	for i in b.size():
		var t := float(i) / RATE
		var hammer := 0.55 + 0.45 * absf(sin(TAU * 9.0 * t)) if t < 0.6 else 1.0
		var v := 0.0
		for p in parts:
			v += sin(TAU * 1046.5 * p[0] * t) * p[1] * exp(-(2.5 + p[0]) * t)
		b[i] = v * hammer * 0.4
	return b


static func _coins() -> PackedFloat32Array:
	var b := SynthA.buffer(0.8)
	var hits: Array = []
	for k in 10:
		hits.append([randf_range(0.0, 0.5), randf_range(1800.0, 3400.0)])
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for h in hits:
			var tt: float = t - h[0]
			if tt > 0.0:
				v += (sin(TAU * h[1] * tt) + 0.6 * sin(TAU * h[1] * 1.34 * tt)) * exp(-26.0 * tt)
		b[i] = v * 0.12
	return b


static func _pop() -> PackedFloat32Array:
	var b := SynthA.buffer(0.15)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (260.0 + 1300.0 * exp(-30.0 * t)) / RATE
		b[i] = sin(ph) * exp(-22.0 * t) * 0.6 + randf_range(-1.0, 1.0) * exp(-200.0 * t) * 0.4
	return b
