class_name BlockLook
## Draws a Block as a thick chunk (Depth): world-aligned soft shadow, side walls, white die-cut border (base parts),
## colour fill with hit flash, surface details, ink outline, carve scars (Carve).
## Golden parts get a pulsing glow; locked shells show a faint padlock tint.
## Weak points: a pulsing red halo and marching dashes around the edge.


static func draw(b: Block) -> void:
	b._drawn_rot = b.rotation
	var g := Batch.new(b)           # v14: the whole part = one draw call
	g.draw_set_transform((Block.SHADOW_INLAY if b.inlay else Block.SHADOW_BASE).rotated(-b.rotation))
	g.draw_colored_polygon(b._sticker, ThemePalette.SHADOW)
	g.draw_set_transform(Vector2.ZERO)

	if b.hazard:                 # battery: angry red pulse, "don't cut me"
		var hp := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		g.draw_circle(Vector2.ZERO, 58.0 + hp * 10.0, ThemePalette.with_alpha(ThemePalette.RED, 0.18 + 0.22 * hp))
	if b.golden:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
		g.draw_circle(Vector2.ZERO, 40.0 + pulse * 8.0,
			ThemePalette.with_alpha(ThemePalette.BUTTER, 0.25 + 0.25 * pulse))
	var t := Time.get_ticks_msec() * 0.001
	if b.weak:
		var ring := b._sticker.duplicate()
		ring.append(b._sticker[0])
		g.draw_polyline(ring, ThemePalette.with_alpha(ThemePalette.RED, 0.35 + 0.25 * sin(t * 7.0)),
			16.0, true)
	var fill := b.color.lerp(ThemePalette.STICKER, b.flash)
	if b.locked_look:
		fill = fill.darkened(0.12)
	Depth.walls(g, b._sticker, b.rotation, Depth.INLAY if b.inlay else Depth.BASE, fill)
	if not b.inlay:
		Depth.top(g, b._sticker, b.rotation, ThemePalette.STICKER)
	if b.weak:
		_dashes(g, b._sticker, t * 60.0)

	Depth.top(g, b._poly, b.rotation, fill)
	if not b._decor.is_empty():
		PartDecor.draw(g, b._decor, b._detail_color, b._text)
	var outline := b._poly.duplicate()
	outline.append(b._poly[0])
	Depth.bevel(g, b._poly, b.rotation, fill)
	g.draw_polyline(outline, ThemePalette.INK, 2.0 if b.inlay else 3.0, true)

	Carve.draw_scars(b, g)
	g.flush()


## Marching dashes along a closed outline: "cut here".
static func _dashes(b: Batch, poly: PackedVector2Array, offset: float) -> void:
	var run := offset
	for i in poly.size():
		var a := poly[i]
		var c := poly[(i + 1) % poly.size()]
		var len := a.distance_to(c)
		var d := 0.0
		while d < len:
			var phase := fmod(run + d, 30.0)
			var seg := minf(18.0 - phase, len - d) if phase < 18.0 else minf(30.0 - phase, len - d)
			if phase < 18.0:
				b.draw_line(a.lerp(c, d / len), a.lerp(c, (d + seg) / len), ThemePalette.RED, 5.0, true)
			d += maxf(seg, 0.5)
		run += len
