class_name ShapeUtil
## Small polygon helpers shared by parts, shards and decorations.


## Grow a polygon outward with round corners (works for either winding).
static func grow(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var res := Geometry2D.offset_polygon(pts, amount, Geometry2D.JOIN_ROUND)
	if res.is_empty():
		return pts
	var out: PackedVector2Array = res[0]
	if absf(signed_area(out)) < absf(signed_area(pts)):   # winding flipped it
		res = Geometry2D.offset_polygon(pts, -amount, Geometry2D.JOIN_ROUND)
		out = res[0] if not res.is_empty() else pts
	return out


static func signed_area(pts: PackedVector2Array) -> float:
	var a := 0.0
	for i in pts.size():
		var p := pts[i]
		var q := pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


static func bbox(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for q in pts:
		r = r.expand(q)
	return r


## Three wobbly crack lines from near the middle out to the edge.
static func cracks(poly: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for c in 3:
		var target: Vector2 = poly[randi() % poly.size()] * 0.9
		var start := target * randf_range(-0.15, 0.1)
		var side := (target - start).orthogonal().normalized()
		var path := PackedVector2Array([start])
		for s in range(1, 5):
			var t := s / 4.0
			path.append(start.lerp(target, t) + side * randf_range(-5.0, 5.0) * (1.0 - t * 0.5))
		out.append(path)
	return out


## Which parts touch? Two base parts touch if their outlines (grown by
## `grow_px`) overlap; anything involving an inlay must genuinely overlap
## (keys sit ON the plate, but neighbouring keys don't hold each other up).
## polys are in object space. Returns Array of Arrays of indices.
static func neighbors(polys: Array, inlays: Array, grow_px: float) -> Array:
	var out: Array = []
	var grown: Array = []
	var boxes: Array = []
	for i in polys.size():
		out.append([])
		var g: PackedVector2Array = polys[i] if inlays[i] else grow(polys[i], grow_px)
		grown.append(g)
		boxes.append(bbox(g))
	for i in polys.size():
		for j in range(i + 1, polys.size()):
			if not (boxes[i] as Rect2).intersects(boxes[j]):
				continue
			var both_base: bool = not inlays[i] and not inlays[j]
			var a: PackedVector2Array = grown[i] if both_base else polys[i]
			var b: PackedVector2Array = grown[j] if both_base else polys[j]
			if not Geometry2D.intersect_polygons(a, b).is_empty():
				out[i].append(j)
				out[j].append(i)
	return out
