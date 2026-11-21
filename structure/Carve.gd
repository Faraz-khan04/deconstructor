class_name Carve
## The saw eats parts bit by bit instead of breaking them whole. Each bite
## chews a jagged notch out of the edge nearest the saw, flicks out chips and
## leaves a scar: glowing hot then charred (metal, plastic, rubber), chalky
## (glass, ceramic) or wet (fruit). Bites keep the eaten area in step with the
## damage done, so hp and power work exactly as before. A notch that splits
## a part drops the smaller bit as a loose chunk.

const GAP_MS := 70                # v14: fewer, slightly bigger bites (was 40)
const LEFT := 0.12               # less than this much left: it crumbles
const HOT_MS := 1100.0
# Per material: PLASTIC, METAL, GLASS, FRUIT, ELECTRO, RUBBER, CERAMIC
const SCAR := [Color(0.16, 0.1, 0.07, 0.85), Color(0.22, 0.2, 0.2, 0.9), Color(1, 1, 1, 0.9),
	Color(0, 0, 0, 0), Color(0.2, 0.2, 0.25, 0.9), Color(0.08, 0.07, 0.07, 0.9), Color(0.96, 0.94, 0.9, 0.95)]
const GLOW := [0.5, 1.0, 0.0, 0.0, 1.0, 0.35, 0.0]   # how long edges glow (share of HOT_MS)


static func setup(b: Block) -> void:
	b._area0 = b._area
	b._bite_r = clampf(sqrt(b._area) * 0.27, 10.0, 34.0)
	b._scar.resize(b._poly.size())
	b._scar.fill(0)


## Called by Block.take_damage after hp went down (saw_at = contact, world).
static func bite(b: Block, saw_at: Vector2, vel: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - b._carve_ms < GAP_MS:
		return
	b._carve_ms = now
	var want := (1.0 - b.hp / b.max_hp) * b._area0
	var at := b.to_local(saw_at)
	for k in 2:
		if b._area0 - b._area >= want or not _one(b, at, vel, now):
			break
	if b._area < b._area0 * LEFT:
		b.hp = 0.0                      # take_damage shatters what's left


static func _one(b: Block, at: Vector2, vel: Vector2, now: int) -> bool:
	var poly := b._poly
	var c := _closest(poly, at)
	var r := b._bite_r * randf_range(0.8, 1.15)
	var notch := PackedVector2Array()
	var start := randf() * TAU
	for i in 9:                         # jagged, so it looks chipped, not stamped
		notch.append(c + Vector2.from_angle(start + TAU * i / 9.0) * r * randf_range(0.7, 1.1))
	var res := Geometry2D.clip_polygons(poly, notch)
	if res.is_empty():
		b.hp = 0.0
		return false
	var cw := Geometry2D.is_polygon_clockwise(poly)
	var best := -1
	var best_a := 0.0
	for i in res.size():
		if Geometry2D.is_polygon_clockwise(res[i]) != cw or res.size() > 3:
			return false                # would punch a hole: skip this bite
		var a := absf(ShapeUtil.signed_area(res[i]))
		if a > best_a:
			best_a = a
			best = i
	var keep := _clean(res[best])
	if keep.size() < 3:
		b.hp = 0.0
		return false
	if Geometry2D.triangulate_polygon(keep).is_empty():
		return false                    # a twisted outline: skip this bite
	var removed := b._area - best_a
	for i in res.size():                # split off: the small bit falls away
		if i != best and absf(ShapeUtil.signed_area(res[i])) > 150.0:
			_drop_chunk(b, res[i], vel)
	_apply(b, keep, best_a, c, r, now)
	_chips(b, c, vel, removed)
	return true


static func _apply(b: Block, keep: PackedVector2Array, area: float, c: Vector2, r: float, now: int) -> void:
	var scar := PackedInt32Array()
	for v in keep:
		var t := now if v.distance_to(c) <= r * 1.25 else 0
		if t == 0:
			for j in b._poly.size():    # an old edge keeps its old scar
				if b._poly[j].distance_squared_to(v) < 2.5:
					t = b._scar[j] if j < b._scar.size() else 0
					break
		scar.append(t)
	b._poly = keep
	b._scar = scar
	b._area = area
	var st := keep if b.inlay else ShapeUtil.grow(keep, Block.BORDER)
	b._sticker = st if Geometry2D.triangulate_polygon(st).size() > 0 else keep
	b._cp.set_deferred("polygon", keep)
	if b._decor.has("pts"):             # sprinkles and dots over a notch go too
		var pts := PackedVector2Array()
		var ang := PackedFloat32Array()
		for i in b._decor["pts"].size():
			if Geometry2D.is_point_in_polygon(b._decor["pts"][i], keep):
				pts.append(b._decor["pts"][i])
				if b._decor.has("angles"): ang.append(b._decor["angles"][i])
		b._decor["pts"] = pts
		if b._decor.has("angles"): b._decor["angles"] = ang
	b.queue_redraw()


static func _chips(b: Block, c: Vector2, vel: Vector2, removed: float) -> void:
	# v14: ONE real shard carries the money; the rest are cheap crumbs (Sparks).
	var pay := maxi(1, int(round(b.value * 0.6 * Economy.value_mult() * removed / b._area0)))
	var col := b.color.lightened(0.5) if b.mat == Materials.GLASS else b.color
	EventBus.fragments_requested.emit(b.to_global(c), col, 1, randf_range(8.0, 12.0) * Materials.SIZE[b.mat],
		vel * 0.4 + Vector2(0.0, -250.0), pay)
	Sparks.chips(b.to_global(c), col, 3, vel)
	Sfx.play(Sfx.MAT_SOUND[b.mat], randf_range(1.25, 1.6), -7.0, 0.1)
	if b.mat == Materials.FRUIT:
		EventBus.splash.emit(b.to_global(c), vel, 0.12, b.paint_color)


static func _drop_chunk(b: Block, piece: PackedVector2Array, vel: Vector2) -> void:
	if Geometry2D.triangulate_polygon(piece).is_empty():
		return
	var mid := Vector2.ZERO
	for v in piece:
		mid += v
	mid /= piece.size()
	var local := PackedVector2Array()
	for v in piece:
		local.append(v - mid)
	var share := absf(ShapeUtil.signed_area(piece)) / b._area0
	FragmentPool.chunk(b.to_global(mid), local, b.color,
		vel * 0.3 + Vector2(randf_range(-150.0, 150.0), -200.0),
		maxi(1, int(round(b.value * 0.6 * Economy.value_mult() * share))))


## Nearest point on the outline (bites always start at an edge: no holes).
static func _closest(poly: PackedVector2Array, p: Vector2) -> Vector2:
	var best := poly[0]
	var bd := INF
	for i in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
		var d := q.distance_squared_to(p)
		if d < bd:
			bd = d
			best = q
	return best


## Drops points closer than 3 px to the last one (keeps outlines light).
static func _clean(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in poly:
		if out.is_empty() or out[out.size() - 1].distance_squared_to(v) > 9.0:
			out.append(v)
	if out.size() > 3 and out[0].distance_squared_to(out[out.size() - 1]) < 9.0:
		out.remove_at(out.size() - 1)
	return out


static func hot(b: Block) -> bool:
	return b._carve_ms > 0 and Time.get_ticks_msec() - b._carve_ms < HOT_MS * GLOW[b.mat] + 50.0


## Scars along the eaten edges: charred or chalky, glowing while fresh.
static func draw_scars(b: Block, g: Batch) -> void:
	var n := b._poly.size()
	if b._carve_ms == 0 or b._scar.size() != n:
		return
	var now := Time.get_ticks_msec()
	var scar := PackedVector2Array()
	var glow := PackedVector2Array()
	var glow_cols := PackedColorArray()
	var life: float = HOT_MS * GLOW[b.mat]
	for i in n:
		var j := (i + 1) % n
		if b._scar[i] == 0 or b._scar[j] == 0:
			continue
		scar.append_array([b._poly[i], b._poly[j]])
		var age := (now - maxi(b._scar[i], b._scar[j])) / maxf(life, 1.0)
		if age < 1.0:
			glow.append_array([b._poly[i], b._poly[j]])
			var c := ThemePalette.BUTTER.lerp(ThemePalette.TANGERINE, age)
			c.a = 1.0 - age * age
			glow_cols.append(c)
	if scar.is_empty():
		return
	var sc: Color = SCAR[b.mat] if b.mat != Materials.FRUIT else b.color.darkened(0.45)
	g.draw_multiline(scar, sc, 6.0)
	if not glow.is_empty():
		g.draw_multiline_colors(glow, glow_cols, 3.0)
