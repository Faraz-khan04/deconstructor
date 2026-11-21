class_name Depth
## Fake 3D for flat shapes: every part is drawn as a thick chunk seen from
## slightly above. The side wall always points the same way on screen (down
## and a little right), so a spinning piece keeps looking solid. Light comes
## from the top left: top faces get a soft gradient and a shiny bevel edge.

const DIR := Vector2(0.28, 1.0)          # where the side wall shows (screen space)
const LIGHT := Vector2(-0.45, -1.0)      # where the light comes from
const BASE := 16.0                       # thickness of big parts
const INLAY := 6.0                       # buttons and labels sit on top: thin
const SHARD := 7.0


## Side walls of `poly` (local coords of a node turned by `rot`), sent to the
## renderer as ONE triangle batch: hidden walls first, visible walls over them.
## (No back face needed: the top plus the swept edges cover the whole chunk.)
static func walls(ci, poly: PackedVector2Array, rot: float, depth: float, col: Color,
		ink: bool = true) -> void:
	var n := poly.size()
	if n < 3:
		return
	var d := (DIR.normalized() * depth).rotated(-rot)
	var sgn := signf(ShapeUtil.signed_area(poly))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var lines := PackedVector2Array()
	var facing := PackedByteArray()
	facing.resize(n)
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		facing[i] = 1 if Vector2(b.y - a.y, a.x - b.x).dot(d) * sgn > 0.0 else 0
	for front in [0, 1]:
		for i in n:
			if facing[i] != front:
				continue
			var a := poly[i]
			var b := poly[(i + 1) % n]
			var nw := Vector2(b.y - a.y, a.x - b.x).normalized().rotated(rot) * sgn
			var c := col.darkened(0.22 + 0.22 * clampf(nw.x, 0.0, 1.0) if front == 1 else 0.45)
			var k := pts.size()
			pts.append_array([a, b, b + d, a + d])
			cols.append_array([c, c, c, c])
			idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
			if front == 1 and ink:
				lines.append_array([a + d, b + d])
	if not pts.is_empty():
		if ci is Batch:
			ci.add_tris(idx, pts, cols)
		else:
			RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)
	if not ink:
		return
	for i in n:                            # corner edges where the wall turns away
		if facing[i] != facing[(i + n - 1) % n]:
			lines.append_array([poly[i], poly[i] + d])
	if not lines.is_empty():
		ci.draw_multiline(lines, ThemePalette.with_alpha(ThemePalette.INK, 0.8), 2.5)


## Top face with a light-to-dark gradient (lit from the top left).
static func top(ci, poly: PackedVector2Array, rot: float, col: Color) -> void:
	var lo := INF
	var hi := -INF
	var ys := PackedFloat32Array()
	var l := LIGHT.normalized()
	for p in poly:
		var y := p.rotated(rot).dot(l)
		ys.append(y)
		lo = minf(lo, y)
		hi = maxf(hi, y)
	var cols := PackedColorArray()
	var span := maxf(hi - lo, 1.0)
	for y in ys:
		var t := (y - lo) / span           # 1 = nearest the light
		cols.append(col.lightened(0.16 * t).darkened(0.08 * (1.0 - t)))
	ci.draw_polygon(poly, cols)


## A thin shiny line just inside the edges that face the light.
static func bevel(ci, poly: PackedVector2Array, rot: float, col: Color, inset: float = 4.0) -> void:
	var n := poly.size()
	var sgn := signf(ShapeUtil.signed_area(poly))
	var l := LIGHT.normalized()
	var hl := col.lightened(0.55)
	hl.a = 0.75
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var nrm := Vector2(b.y - a.y, a.x - b.x).normalized() * sgn
		if nrm.rotated(rot).dot(l) > 0.35 and a.distance_to(b) > inset * 2.0:
			var k := (b - a).normalized() * inset
			ci.draw_line(a + k - nrm * inset, b - k - nrm * inset, hl, 3.0, true)


## Parts lower on screen are in front: draw base parts top-to-bottom, inlays last.
static func sort(host: Node, blocks: Array) -> void:
	var bases := blocks.filter(func(b): return not b.inlay)
	bases.sort_custom(func(a, b): return a.rest_pos.y < b.rest_pos.y)
	var i := 0
	for b in bases:
		host.move_child(b, i)
		i += 1
