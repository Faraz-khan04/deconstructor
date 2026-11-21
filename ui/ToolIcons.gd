class_name ToolIcons
## Tiny drawings of each tool for the catalog's tool picker.


static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, owned: bool) -> void:
	var ink := ThemePalette.INK if owned else ThemePalette.INK_SOFT
	match id:
		"twin":
			for d in [Vector2(-0.45, 0.0), Vector2(0.45, 0.0)]:
				_saw(ci, c + d * r, r * 0.5, owned, ink)
		"laser":
			ci.draw_circle(c, r * 0.6, ThemePalette.CHARCOAL if owned else ThemePalette.STONE)
			ci.draw_circle(c, r * 0.25, ThemePalette.RED if owned else ThemePalette.INK_SOFT)
			ci.draw_arc(c, r * 0.6, 0.0, TAU, 24, ink, 3.0, true)
		"hole":
			ci.draw_circle(c, r * 0.75, ThemePalette.INK if owned else ThemePalette.STONE)
			ci.draw_arc(c, r * 0.45, 0.4, 4.2, 20, ThemePalette.LILAC, 4.0, true)
			ci.draw_arc(c, r * 0.25, 2.0, 5.6, 16, ThemePalette.PINK, 4.0, true)
		_:
			_saw(ci, c, r * 0.8, owned, ink)
	if not owned:                                   # padlock
		var b := Rect2(c + Vector2(-r * 0.3, r * 0.05), Vector2(r * 0.6, r * 0.5))
		ci.draw_arc(c + Vector2(0.0, r * 0.05), r * 0.2, PI, TAU, 12, ThemePalette.INK, 4.0, true)
		ci.draw_rect(b, ThemePalette.BUTTER)
		ci.draw_rect(b, ThemePalette.INK, false, 3.0)


static func _saw(ci: CanvasItem, c: Vector2, r: float, owned: bool, ink: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		pts.append(c + Vector2.from_angle(TAU * i / 24.0) * (r if i % 2 == 0 else r * 0.8))
	ci.draw_colored_polygon(pts, ThemePalette.CREAM if owned else ThemePalette.STONE)
	pts.append(pts[0])
	ci.draw_polyline(pts, ink, 2.5, true)
	ci.draw_arc(c, r * 0.5, 0.0, TAU, 20, ThemePalette.COBALT if owned else ink, 4.0, true)
	ci.draw_circle(c, r * 0.15, ThemePalette.BUTTER if owned else ink)
