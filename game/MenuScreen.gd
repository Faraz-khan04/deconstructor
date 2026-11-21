class_name MenuScreen
extends Control
## The start menu: pick a mode. Modes unlock with stars (earned in Jobs and
## Rush). Also holds small helpers the modes share (scene switching, the
## MENU button, big sticker buttons, drawing a star).

const MODES := [
	{"id": "jobs", "name": "JOBS", "desc": "WRECK IT BEFORE THE CLOCK RUNS OUT", "stars": 0,
		"scene": "res://main.tscn", "color": "COBALT"},
	{"id": "rush", "name": "RUSH", "desc": "SLICE EVERYTHING IN 60 SECONDS", "stars": 3,
		"scene": "res://rush.tscn", "color": "RED"},
	{"id": "zen", "name": "ZEN", "desc": "SLOW, SATISFYING CUTS. NO CLOCK.", "stars": 15,
		"scene": "", "color": "MINT"},
	{"id": "factory", "name": "FACTORY", "desc": "BUILD A MACHINE THAT CUTS FOR YOU", "stars": 30,
		"scene": "", "color": "TANGERINE"},
]
const TOP := 90.0


static func go(scene: String) -> void:
	Save.save_game()
	Engine.time_scale = 1.0
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	tree.change_scene_to_file(scene)


static func menu_button(at: Vector2) -> Button:
	var b := big_button("< MENU", ThemePalette.STICKER, 26)
	b.position = at
	b.size = Vector2(170.0, 64.0)
	b.pressed.connect(func(): go("res://menu.tscn"))
	return b


static func big_button(text: String, fill: Color, font_size: int = 44) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", ThemePalette.display_font)
	b.add_theme_font_size_override("font_size", font_size)
	var dark := fill == ThemePalette.STONE or fill == ThemePalette.STICKER or fill == ThemePalette.MINT
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, ThemePalette.INK if dark else ThemePalette.STICKER)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = ThemePalette.INK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(26)
	sb.shadow_color = ThemePalette.SHADOW
	sb.shadow_offset = Vector2(5, 8)
	sb.shadow_size = 2
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	return b


static func draw_star(on: CanvasItem, c: Vector2, rad: float, lit: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * (rad if i % 2 == 0 else rad * 0.45))
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(5, 8))
	on.draw_colored_polygon(shadow, ThemePalette.SHADOW)
	on.draw_colored_polygon(pts, ThemePalette.BUTTER if lit else ThemePalette.STONE)
	pts.append(pts[0])
	on.draw_polyline(pts, ThemePalette.INK, 4.0, true)


func _ready() -> void:
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(ThemePalette.PAPER)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var stars := Save.total_stars()
	var y := 520.0
	for m in MODES:
		var open: bool = stars >= int(m["stars"]) and m["scene"] != ""
		var col: Color = _color(m["color"]) if open else ThemePalette.STONE
		var card := big_button("", col)
		card.position = Vector2(60.0, y)
		card.size = Vector2(get_viewport_rect().size.x - 120.0, 330.0)
		card.disabled = not open
		if open:
			card.pressed.connect(go.bind(m["scene"]))
		card.add_child(_card_text(m, open, stars))
		add_child(card)
		y += 370.0


func _color(n: String) -> Color:
	return {"COBALT": ThemePalette.COBALT, "RED": ThemePalette.RED, "MINT": ThemePalette.MINT,
		"TANGERINE": ThemePalette.TANGERINE}.get(n, ThemePalette.STONE)


func _card_text(m: Dictionary, open: bool, stars: int) -> Control:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ThemePalette.STICKER if open and m["color"] != "MINT" else ThemePalette.INK
	var status := "PLAY"
	if m["id"] == "jobs":
		status = "LEVEL %d  ·  PLAY" % int(Save.data["level"])
	elif m["id"] == "rush" and open:
		status = "BEST %s  ·  PLAY" % NumFmt.money(int(Save.data.get("rush_best", 0)))
	elif m["scene"] == "":
		status = "COMING SOON  ·  %d STARS" % int(m["stars"])
	elif not open:
		status = "%d STARS TO UNLOCK  (YOU HAVE %d)" % [int(m["stars"]), stars]
	for line in [[m["name"], ThemePalette.display_font, 96], [m["desc"], ThemePalette.mono_font, 26],
			[status, ThemePalette.display_font, 34]]:
		var l := Label.new()
		var ls := LabelSettings.new()
		ls.font = line[1]
		ls.font_size = line[2]
		ls.font_color = ink
		l.label_settings = ls
		l.text = line[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)
	return box


func _draw() -> void:
	var w := size.x
	draw_string(ThemePalette.display_font, Vector2(0, TOP + 150.0), "deconstructor",
		HORIZONTAL_ALIGNMENT_CENTER, w, 120, ThemePalette.INK)
	draw_star(self, Vector2(w * 0.5 - 120.0, TOP + 280.0), 44.0, true)
	draw_string(ThemePalette.display_font, Vector2(w * 0.5 - 60.0, TOP + 300.0),
		"%d STARS" % Save.total_stars(), HORIZONTAL_ALIGNMENT_LEFT, -1, 56, ThemePalette.INK)
	draw_string(ThemePalette.mono_font, Vector2(0, TOP + 370.0), "CASH " + NumFmt.money(Economy.cash),
		HORIZONTAL_ALIGNMENT_CENTER, w, 30, ThemePalette.INK_SOFT)
