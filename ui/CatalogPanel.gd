extends Control
## Blueprint-style catalog: every gadget (smashed ones in colour, the rest as
## outlines), golden parts found per gadget, and the tool picker. All drawn by
## hand on one Control; taps are checked against the card rectangles.

signal closed

const COLS := 4
const MARGIN := 48.0
const GAP := 24.0
const CARD_H := 230.0
const TOP_Y := 290.0

var _art: Dictionary = {}          # gadget -> Array of [pos, poly, color, inlay]
var _tool_rects: Dictionary = {}   # tool id -> Rect2
var _close_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP     # nothing reaches the game below


func refresh() -> void:
	_art.clear()
	for g in ObjectLibrary.ALL:
		var parts: Array = []
		for p in ObjectLibrary.build(g)["parts"]:
			parts.append([p["pos"], p["poly"], p["color"], p["inlay"]])
		_art[g] = parts
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var at: Vector2 = event.position
	if _close_rect.has_point(at):
		closed.emit()
		return
	for id in _tool_rects:
		if (_tool_rects[id] as Rect2).has_point(at) and Save.has_tool(id):
			Save.set_tool(id)
			JuiceManager.buzz(20, 0.5)
			queue_redraw()


func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(Vector2.ZERO, size), ThemePalette.COBALT)
	_grid(60.0, 0.1)
	_grid(240.0, 0.2)
	var light := ThemePalette.STICKER
	var gold_total := 0
	for g in ObjectLibrary.ALL:
		gold_total += Save.golden_found(g).size()
	draw_string(ThemePalette.display_font, Vector2(MARGIN, 170.0), "CATALOG",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 64, light)
	draw_string(ThemePalette.mono_font, Vector2(MARGIN, 220.0),
		"SMASHED %d/%d   ·   GOLDEN PARTS %d/%d" % [Save.smashed_count(), ObjectLibrary.ALL.size(),
		gold_total, ObjectLibrary.ALL.size() * Save.GOLDEN_SLOTS],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ThemePalette.with_alpha(light, 0.8))
	var reward := "REWARD UNLOCKED: ALL CASH x2 FOREVER" if bool(Save.data.get("catalog_done", false)) \
		else "FIND ALL %d FOR A REWARD: ALL CASH x2 FOREVER" % ObjectLibrary.ALL.size()
	draw_string(ThemePalette.mono_font, Vector2(MARGIN, 252.0), reward, HORIZONTAL_ALIGNMENT_LEFT, -1,
		22, ThemePalette.BUTTER)

	var cw := (w - MARGIN * 2.0 - GAP * (COLS - 1)) / COLS
	for i in ObjectLibrary.ALL.size():
		var r := Rect2(MARGIN + (i % COLS) * (cw + GAP), TOP_Y + (i / COLS) * (CARD_H + GAP), cw, CARD_H)
		_card(r, ObjectLibrary.ALL[i])

	var ty := TOP_Y + ceilf(ObjectLibrary.ALL.size() / float(COLS)) * (CARD_H + GAP) + 40.0
	draw_string(ThemePalette.display_font, Vector2(MARGIN, ty), "TOOLS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 44, light)
	var tw := (w - MARGIN * 2.0 - 20.0 * 3.0) / 4.0
	for i in ToolKit.ORDER.size():
		var id: String = ToolKit.ORDER[i]
		var r := Rect2(MARGIN + i * (tw + 20.0), ty + 30.0, tw, 250.0)
		_tool_rects[id] = r
		_tool_card(r, id)

	_close_rect = Rect2(w * 0.5 - 200.0, ty + 320.0, 400.0, 110.0)
	_sticker_rect(_close_rect, ThemePalette.BUTTER)
	draw_string(ThemePalette.display_font, Vector2(_close_rect.position.x, _close_rect.position.y + 72.0),
		"CLOSE", HORIZONTAL_ALIGNMENT_CENTER, _close_rect.size.x, 44, ThemePalette.INK)


func _card(r: Rect2, g: String) -> void:
	var seen := Save.is_smashed(g)
	if seen:
		_sticker_rect(r, ThemePalette.PAPER)
	else:
		draw_rect(r, ThemePalette.COBALT.darkened(0.25))
		draw_rect(r, ThemePalette.with_alpha(ThemePalette.STICKER, 0.5), false, 2.0)
	_draw_art(Rect2(r.position + Vector2(18, 18), Vector2(r.size.x - 36, r.size.y - 100)), g, seen)
	var name_col := ThemePalette.INK if seen else ThemePalette.with_alpha(ThemePalette.STICKER, 0.7)
	draw_string(ThemePalette.mono_font, Vector2(r.position.x + 16.0, r.end.y - 46.0),
		ObjectLibrary.DISPLAY[g] if seen else "???", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, name_col)
	for s in Save.GOLDEN_SLOTS:                          # golden part pips
		var c := Vector2(r.position.x + 28.0 + s * 34.0, r.end.y - 22.0)
		if Save.has_golden(g, s):
			draw_circle(c, 11.0, ThemePalette.BUTTER)
		draw_arc(c, 11.0, 0.0, TAU, 16, name_col, 2.0, true)
	if g in ObjectLibrary.BOSSES:
		draw_string(ThemePalette.mono_font, Vector2(r.position.x, r.end.y - 18.0), "BOSS  ",
			HORIZONTAL_ALIGNMENT_RIGHT, r.size.x, 16, ThemePalette.RED if seen else name_col)


## Gadget drawn from its real parts, scaled to fit the card.
func _draw_art(area: Rect2, g: String, seen: bool) -> void:
	var parts: Array = _art.get(g, [])
	if parts.is_empty():
		return
	var box := Rect2()
	var first := true
	for p in parts:
		for q in p[1]:
			var pt: Vector2 = q + p[0]
			box = Rect2(pt, Vector2.ZERO) if first else box.expand(pt)
			first = false
	var s := minf(area.size.x / box.size.x, area.size.y / box.size.y)
	var origin := area.get_center() - box.get_center() * s
	for p in parts:
		if not seen and p[3]:
			continue                                     # silhouettes: outer shell only
		draw_set_transform(origin + p[0] * s, 0.0, Vector2(s, s))
		var col: Color = p[2] if seen else ThemePalette.with_alpha(ThemePalette.STICKER, 0.3)
		draw_colored_polygon(p[1], col)
		if seen:
			var o: PackedVector2Array = (p[1] as PackedVector2Array).duplicate()
			o.append(o[0])
			draw_polyline(o, ThemePalette.INK, 1.5 / s, true)
	draw_set_transform(Vector2.ZERO)


func _tool_card(r: Rect2, id: String) -> void:
	var info: Dictionary = ToolKit.TOOLS[id]
	var owned := Save.has_tool(id)
	var in_use := String(Save.data["tool"]) == id
	_sticker_rect(r, ThemePalette.BUTTER if in_use else (ThemePalette.PAPER if owned else ThemePalette.STONE))
	if in_use:
		draw_rect(r.grow(-6.0), ThemePalette.INK, false, 4.0)
	var c := r.position + Vector2(r.size.x * 0.5, 80.0)
	ToolIcons.draw(self, id, c, 46.0, owned)
	draw_string(ThemePalette.display_font, Vector2(r.position.x, r.position.y + 168.0), info["name"],
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, ThemePalette.INK)
	var sub: String = "IN USE" if in_use else ("TAP TO USE" if owned else "LEVEL %d" % info["unlock"])
	draw_string(ThemePalette.mono_font, Vector2(r.position.x, r.position.y + 204.0), sub,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, ThemePalette.INK_SOFT)
	draw_string(ThemePalette.mono_font, Vector2(r.position.x + 8.0, r.position.y + 232.0), info["desc"],
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16.0, 12, ThemePalette.INK_SOFT)


func _sticker_rect(r: Rect2, fill: Color) -> void:
	draw_rect(Rect2(r.position + Vector2(5, 8), r.size), ThemePalette.SHADOW)
	draw_rect(r.grow(5.0), ThemePalette.STICKER)
	draw_rect(r, fill)
	draw_rect(r, ThemePalette.INK, false, 3.0)


func _grid(step: float, alpha: float) -> void:
	var col := ThemePalette.with_alpha(ThemePalette.STICKER, alpha)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), col, 1.5)
		x += step
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), col, 1.5)
		y += step
