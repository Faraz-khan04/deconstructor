class_name ObjectLibrary
## Catalogue of procedural real-world objects, built from cuttable parts.
## A part = { pos, poly, color, hp, value, anchor, inlay, detail, text, armor,
## screw, golden, hazard } plus optional behaviour keys (EXTRA): mat (force a
## material), spill (bonus pieces burst out: coins, candy, gears), spill_color,
## bouncy (rubber: bounces off pegs), sound (+ note) played when it breaks.
## Inlays sit ON a base part; cutting the base drops everything on it.

enum Detail { NONE, GLOSS, DOTS, HUB, TEXT, LINES, SPRINKLES, SEEDS, SCREW, SHINE }

const NAMES := ["keyboard", "sampler", "cassette", "gameboy", "boombox",
	"headphones", "camera", "watermelon", "donut", "piggy", "duck", "guitar", "clock",
	"phone", "jar", "cake", "robot", "pinata"]
const BOSSES := ["tv", "arcade", "synth"]
const ALL := ["keyboard", "sampler", "cassette", "gameboy", "boombox",
	"headphones", "camera", "watermelon", "donut", "piggy", "duck", "guitar", "clock",
	"phone", "jar", "cake", "robot", "pinata", "tv", "arcade", "synth"]   # catalog order
const EXTRA := ["mat", "spill", "spill_color", "bouncy", "sound", "note"]
const SPINNERS := ["donut"]
const DISPLAY := {
	"keyboard": "KEYBOARD", "sampler": "SAMPLER", "cassette": "CASSETTE",
	"gameboy": "GAME BOY", "boombox": "BOOMBOX", "headphones": "HEADPHONES",
	"camera": "CAMERA", "watermelon": "WATERMELON", "donut": "DONUT",
	"tv": "OLD TV", "arcade": "ARCADE", "synth": "SYNTH", "piggy": "PIGGY BANK",
	"duck": "RUBBER DUCK", "guitar": "GUITAR", "clock": "ALARM CLOCK", "phone": "PHONE",
	"jar": "CANDY JAR", "cake": "CAKE", "robot": "ROBOT", "pinata": "PINATA",
}


static func build(obj_name: String) -> Dictionary:
	var parts: Array = []
	match obj_name:
		"keyboard": ObjectsTech.keyboard(parts)
		"sampler": ObjectsTech.sampler(parts)
		"cassette": ObjectsTech.cassette(parts)
		"gameboy": ObjectsTech.gameboy(parts)
		"boombox": ObjectsMore.boombox(parts)
		"headphones": ObjectsMore.headphones(parts)
		"camera": ObjectsMore.camera(parts)
		"watermelon": ObjectsMore.watermelon(parts)
		"tv": ObjectsBoss.tv(parts)
		"arcade": ObjectsBoss.arcade(parts)
		"synth": ObjectsBoss.synth(parts)
		"donut": ObjectsMore.donut(parts)
		_: ObjectsFun.make(obj_name, parts)
	return {"name": obj_name, "parts": parts, "spin": obj_name in SPINNERS}


static func pick_names(count: int, avoid: Array) -> Array:
	var pool := NAMES.duplicate()
	pool.shuffle()
	var out: Array = []
	for n in pool:
		if out.size() >= count:
			break
		if not n in avoid:
			out.append(n)
	while out.size() < count:
		out.append(pool.pick_random())
	return out


# --- Part builders -----------------------------------------------------------

static func part(parts: Array, poly: PackedVector2Array, at: Vector2, color: Color,
		opts: Dictionary = {}) -> void:
	var d := {
		"pos": at, "poly": poly, "color": color,
		"hp": opts.get("hp", 3.0), "value": opts.get("value", 10),
		"anchor": opts.get("anchor", false), "inlay": opts.get("inlay", false),
		"detail": opts.get("detail", Detail.NONE),
		"detail_color": opts.get("detail_color", ThemePalette.INK),
		"text": opts.get("text", ""),
		"armor": opts.get("armor", false), "screw": opts.get("screw", false),
		"golden": opts.get("golden", false), "hazard": opts.get("hazard", false),
	}
	for k in EXTRA:
		if opts.has(k): d[k] = opts[k]
	parts.append(d)


## A screw holding a boss shell shut.
static func screw(parts: Array, at: Vector2) -> void:
	part(parts, circle(15.0, 16), at, ThemePalette.STONE,
		{"inlay": true, "screw": true, "hp": 1.2, "value": 15, "detail": Detail.SCREW})


## Maybe hide a golden gear on one of the anchor parts. Each job puts one on
## exactly one of its objects (chance 1). Slot -1 = gadget complete: bonus gold.
static func add_golden(parts: Array, gadget: String, chance: float) -> void:
	var slot := Save.next_golden_slot(gadget)
	if randf() >= chance:
		return
	var spots: Array = []
	for p in parts:
		if p["anchor"] and not p["inlay"]:
			spots.append(p["pos"])
	if not spots.is_empty():
		parts.append(golden_gear(spots.pick_random(), slot))


## A golden gear, placed on top of a base part. It can't be cut while
## attached: free it, then slice it before it reaches the shredder.
static func golden_gear(at: Vector2, slot: int) -> Dictionary:
	var pts := PackedVector2Array()
	for i in 20:
		var r := 30.0 if i % 2 == 0 else 22.0
		pts.append(Vector2.from_angle(TAU * i / 20.0) * r)
	var parts: Array = []
	part(parts, pts, at, ThemePalette.BUTTER,
		{"inlay": true, "golden": true, "hp": 1.0, "value": 60, "detail": Detail.SHINE})
	parts[0]["golden_slot"] = slot
	return parts[0]


## Same as part() but takes points in object space and centres them itself.
static func part_abs(parts: Array, pts: PackedVector2Array, color: Color,
		opts: Dictionary = {}) -> void:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	var local := PackedVector2Array()
	for p in pts:
		local.append(p - c)
	part(parts, local, c, color, opts)


## Splits a body of `size` into cols x rows slabs. `anchors` = Vector2i cells.
static func slabs(parts: Array, size: Vector2, cols: int, rows: int, color: Color,
		anchors: Array, opts: Dictionary = {}) -> void:
	var gap := 6.0
	var cw := (size.x - gap * (cols - 1)) / cols
	var ch := (size.y - gap * (rows - 1)) / rows
	for cy in rows:
		for cx in cols:
			var at := Vector2(-size.x * 0.5 + cw * 0.5 + cx * (cw + gap),
				-size.y * 0.5 + ch * 0.5 + cy * (ch + gap))
			var o := opts.duplicate()
			o["anchor"] = Vector2i(cx, cy) in anchors
			part(parts, rect(cw, ch, 14.0), at, color, o)


## Splits an arc band into `segs` pieces (object space, angles in radians).
static func arc_band(parts: Array, center: Vector2, inner: float, outer: float,
		a0: float, a1: float, segs: int, color: Color, anchor_ids: Array,
		opts: Dictionary = {}) -> void:
	var gap := 6.0 / ((inner + outer) * 0.5)
	var w := (a1 - a0) / segs
	for s in segs:
		var pts := annular(inner, outer, a0 + s * w + gap * 0.5,
			a0 + (s + 1) * w - gap * 0.5)
		for i in pts.size():
			pts[i] = pts[i] + center
		var o := opts.duplicate()
		o["anchor"] = s in anchor_ids
		part_abs(parts, pts, color, o)


static func rect(w: float, h: float, r: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var hw := w * 0.5
	var hh := h * 0.5
	r = minf(r, minf(hw, hh))
	if r <= 0.5:
		return PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	var corners := [Vector2(hw - r, -hh + r), Vector2(hw - r, hh - r),
		Vector2(-hw + r, hh - r), Vector2(-hw + r, -hh + r)]
	var start_angles := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for i in 4:
		for s in 4:
			var a: float = start_angles[i] + (PI * 0.5) * s / 3.0
			pts.append(corners[i] + Vector2.from_angle(a) * r)
	return pts


## Arc band polygon (outer arc forward, inner arc back), object space.
static func annular(inner: float, outer: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(3, int((a1 - a0) * outer / 14.0))
	for i in n + 1:
		pts.append(Vector2.from_angle(lerpf(a0, a1, float(i) / n)) * outer)
	for i in n + 1:
		pts.append(Vector2.from_angle(lerpf(a1, a0, float(i) / n)) * inner)
	return pts


static func circle(r: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(Vector2.from_angle(TAU * i / n) * r)
	return pts


static func rotated(pts: PackedVector2Array, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p.rotated(angle))
	return out
