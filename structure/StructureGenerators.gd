class_name StructureGenerators
## Procedural structure layouts around a central core. Each generator returns:
##   { core_radius: float, blocks: Array[Dictionary] } where every block is
##   { pos: Vector2 (rest position relative to core), poly: PackedVector2Array
##     (centred on pos), band: int, alt: int, hp: float, value: int,
##     anchor: bool (touches the core), neighbors: Array (block indices) }
## Difficulty rises gently with `level` (more rings / bigger lattices / more HP).

enum Kind { RINGS, LATTICE }

const GAP := 7.0  # px between tiles, filled by their white sticker borders


static func generate(kind: int, level: int) -> Dictionary:
	if kind == Kind.LATTICE:
		return lattice(level)
	return rings(level)


static func rings(level: int) -> Dictionary:
	var core_r := 64.0
	var ring_count := clampi(2 + int(level * 0.5) + randi_range(0, 1), 2, 5)
	var thickness := randf_range(44.0, 58.0)
	var blocks: Array = []
	var meta: Array = []  # Vector3(ring, mid_angle, half_width_with_gap)

	for ring in ring_count:
		var inner := core_r + GAP + ring * (thickness + GAP)
		var outer := inner + thickness
		var mid_r := (inner + outer) * 0.5
		var segs := clampi(int(TAU * mid_r / randf_range(95.0, 135.0)), 5, 22)
		var off := randf() * TAU
		var seg_w := TAU / segs
		for s in segs:
			# Random notches in the outer rim give each structure a silhouette.
			if ring == ring_count - 1 and ring > 0 and randf() < 0.12:
				continue
			var a0 := off + s * seg_w + GAP * 0.5 / mid_r
			var a1 := off + (s + 1) * seg_w - GAP * 0.5 / mid_r
			var pts := _annular(inner, outer, a0, a1)
			var c := _centroid(pts)
			blocks.append({
				"pos": c, "poly": _shift(pts, -c), "band": ring, "alt": s % 2,
				"hp": 2.6 + (ring_count - ring) * 0.7 + level * 0.25,
				"value": 10 + ring * 5, "anchor": ring == 0, "neighbors": [],
			})
			meta.append(Vector3(ring, (a0 + a1) * 0.5, (a1 - a0) * 0.5 + GAP / mid_r))

	# Neighbours: touching in the same ring, or overlapping in the next ring.
	for i in blocks.size():
		for j in range(i + 1, blocks.size()):
			var mi: Vector3 = meta[i]
			var mj: Vector3 = meta[j]
			if absf(mi.x - mj.x) > 1.0:
				continue
			if absf(angle_difference(mi.y, mj.y)) <= mi.z + mj.z + 0.02:
				blocks[i]["neighbors"].append(j)
				blocks[j]["neighbors"].append(i)
	return {"core_radius": core_r, "blocks": blocks}


static func lattice(level: int) -> Dictionary:
	var size := randf_range(66.0, 82.0)
	var step := size + GAP
	var shape := randi() % 3              # 0 diamond, 1 square, 2 round
	var n := clampi(2 + int(level * 0.34), 2, 4)
	if shape == 1:
		n = mini(n, 3)                     # squares get big fast
	var tilt := PI * 0.25 if randf() < 0.5 else 0.0
	var tile := _chamfer_square(size, size * 0.2)
	var blocks: Array = []
	var index := {}                        # Vector2i -> block index

	for gx in range(-n, n + 1):
		for gy in range(-n, n + 1):
			if gx == 0 and gy == 0:
				continue                   # the core lives here
			var inside := true
			match shape:
				0: inside = absi(gx) + absi(gy) <= n
				2: inside = Vector2(gx, gy).length() <= n + 0.35
			if not inside:
				continue
			var ring := maxi(absi(gx), absi(gy))
			index[Vector2i(gx, gy)] = blocks.size()
			blocks.append({
				"pos": (Vector2(gx, gy) * step).rotated(tilt), "poly": _rotate(tile, tilt),
				"band": ring - 1, "alt": (gx + gy) & 1,
				"hp": 2.8 + (n - ring) * 0.5 + level * 0.25,
				"value": 10 + ring * 5, "anchor": absi(gx) + absi(gy) == 1, "neighbors": [],
			})

	for key in index:
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var other: Vector2i = key + d
			if index.has(other):
				blocks[index[key]]["neighbors"].append(index[other])
				blocks[index[other]]["neighbors"].append(index[key])
	return {"core_radius": size * 0.55, "blocks": blocks}


# --- Geometry helpers --------------------------------------------------------

static func _annular(inner: float, outer: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(3, int((a1 - a0) * outer / 14.0))
	for i in n + 1:
		pts.append(Vector2.from_angle(lerpf(a0, a1, float(i) / n)) * outer)
	for i in n + 1:
		pts.append(Vector2.from_angle(lerpf(a1, a0, float(i) / n)) * inner)
	return pts


static func _chamfer_square(s: float, cut: float) -> PackedVector2Array:
	var h := s * 0.5
	return PackedVector2Array([
		Vector2(-h + cut, -h), Vector2(h - cut, -h), Vector2(h, -h + cut), Vector2(h, h - cut),
		Vector2(h - cut, h), Vector2(-h + cut, h), Vector2(-h, h - cut), Vector2(-h, -h + cut),
	])


static func _centroid(pts: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	return c / pts.size()


static func _shift(pts: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + by)
	return out


static func _rotate(pts: PackedVector2Array, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p.rotated(angle))
	return out
