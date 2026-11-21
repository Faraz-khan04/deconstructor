class_name PartDecor
## Procedural surface details for object parts (all drawn in the part's own
## _draw, so they rotate and flash with it). prepare() runs once per part and
## caches random layouts; draw() is cheap.



static func prepare(kind: int, poly: PackedVector2Array) -> Dictionary:
	var bbox := _bbox(poly)
	var data := {"kind": kind, "bbox": bbox}
	if kind == ObjectLibrary.Detail.DOTS:
		var pts := PackedVector2Array()
		var step := 15.0
		var y := bbox.position.y + step
		while y < bbox.end.y - step * 0.5 and pts.size() < 80:
			var x := bbox.position.x + step
			while x < bbox.end.x - step * 0.5:
				var q := Vector2(x, y)
				if Geometry2D.is_point_in_polygon(q, _shrink(poly, 0.8)):
					pts.append(q)
				x += step
			y += step
		data["pts"] = pts
	elif kind == ObjectLibrary.Detail.SEEDS or kind == ObjectLibrary.Detail.SPRINKLES:
		var pts := PackedVector2Array()
		var angles := PackedFloat32Array()
		var inner := _shrink(poly, 0.72)
		var want := 5 if kind == ObjectLibrary.Detail.SEEDS else 9
		var tries := 0
		while pts.size() < want and tries < 80:
			tries += 1
			var q := Vector2(randf_range(bbox.position.x, bbox.end.x),
				randf_range(bbox.position.y, bbox.end.y))
			if Geometry2D.is_point_in_polygon(q, inner):
				pts.append(q)
				angles.append(randf() * TAU)
		data["pts"] = pts
		data["angles"] = angles
	return data


static func draw(ci, data: Dictionary, color: Color, text: String) -> void:
	var b: Rect2 = data["bbox"]
	var k := int(data["kind"])
	if k == ObjectLibrary.Detail.GLOSS:
		var a := b.position + b.size * Vector2(0.18, 0.2)
		var w := maxf(3.0, minf(b.size.x, b.size.y) * 0.09)
		var hl := Color(1, 1, 1, 0.55)
		ci.draw_line(a, a + Vector2(b.size.x * 0.28, 0.0), hl, w, true)
		ci.draw_circle(a + Vector2(b.size.x * 0.36, 0.0), w * 0.5, hl)
	elif k == ObjectLibrary.Detail.HUB:
		var r := minf(b.size.x, b.size.y) * 0.28
		var c := b.get_center()
		ci.draw_arc(c, r, 0.0, TAU, 20, color, 3.0, true)
		for i in 3:
			var d := Vector2.from_angle(TAU * i / 3.0)
			ci.draw_line(c + d * r * 0.3, c + d * r, color, 3.0, true)
		ci.draw_circle(c, r * 0.25, color)
	elif k == ObjectLibrary.Detail.DOTS:
		for q in data["pts"]:
			ci.draw_circle(q, 3.2, color)
	elif k == ObjectLibrary.Detail.SEEDS:
		var pts: PackedVector2Array = data["pts"]
		for i in pts.size():
			var dir := Vector2.from_angle(data["angles"][i]) * 4.0
			ci.draw_line(pts[i] - dir, pts[i] + dir, ThemePalette.INK, 7.0, true)
			ci.draw_circle(pts[i] - dir * 0.6, 1.4, Color(1, 1, 1, 0.7))
	elif k == ObjectLibrary.Detail.SPRINKLES:
		var pts: PackedVector2Array = data["pts"]
		for i in pts.size():
			var dir := Vector2.from_angle(data["angles"][i]) * 7.0
			var sc: Color = ThemePalette.PAINT[i % ThemePalette.PAINT.size()]
			ci.draw_line(pts[i] - dir, pts[i] + dir, sc, 5.0, true)
	elif k == ObjectLibrary.Detail.LINES:
		var y := b.position.y + b.size.y * 0.25
		while y < b.end.y - 4.0:
			ci.draw_line(Vector2(b.position.x + 10.0, y), Vector2(b.end.x - 10.0, y),
				ThemePalette.with_alpha(color, 0.45), 2.0)
			y += 10.0
	elif k == ObjectLibrary.Detail.SCREW:
		var c := b.get_center()
		var r := minf(b.size.x, b.size.y) * 0.32
		ci.draw_line(c - Vector2(r, 0.0).rotated(0.6), c + Vector2(r, 0.0).rotated(0.6), ThemePalette.INK, 3.0, true)
		ci.draw_line(c - Vector2(0.0, r).rotated(0.6), c + Vector2(0.0, r).rotated(0.6), ThemePalette.INK, 3.0, true)
	elif k == ObjectLibrary.Detail.SHINE:
		var c := b.get_center()
		var r := minf(b.size.x, b.size.y) * 0.5
		ci.draw_circle(c, r * 0.32, ThemePalette.TANGERINE)
		ci.draw_circle(c, r * 0.14, ThemePalette.STICKER)
		for d in [Vector2(-0.35, -0.35), Vector2(0.4, -0.15)]:       # little sparkles
			var p: Vector2 = c + d * r
			ci.draw_line(p - Vector2(5, 0), p + Vector2(5, 0), ThemePalette.STICKER, 2.5, true)
			ci.draw_line(p - Vector2(0, 5), p + Vector2(0, 5), ThemePalette.STICKER, 2.5, true)
	elif k == ObjectLibrary.Detail.TEXT:
		var size := int(clampf(b.size.y * 0.22, 14.0, 26.0))
		ci.draw_string(ThemePalette.mono_font, Vector2(b.position.x, b.get_center().y + size * 0.35),
			text, HORIZONTAL_ALIGNMENT_CENTER, b.size.x, size, color)
		ci.draw_line(Vector2(b.position.x + 24.0, b.get_center().y + size * 0.9),
			Vector2(b.end.x - 24.0, b.get_center().y + size * 0.9),
			ThemePalette.with_alpha(color, 0.35), 2.0)


static func _bbox(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		r = r.expand(q)
	return r


static func _shrink(poly: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in poly:
		out.append(q * k)
	return out
