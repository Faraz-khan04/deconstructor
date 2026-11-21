class_name ObjectsTech
## Retro tech objects: keyboard, MPC sampler, cassette tape, Game Boy.
## Object space is centred on (0, 0); sizes are in px at 1080-wide.



static func keyboard(p: Array) -> void:
	var P := ThemePalette
	var case_col: Color = [P.CHARCOAL, P.TEAL, P.COBALT].pick_random()
	ObjectLibrary.slabs(p, Vector2(660, 260), 4, 1, case_col, [Vector2i(1, 0), Vector2i(2, 0)], {"hp": 4.5})
	var pitch := 56.0
	var key := 46.0
	var x0 := -pitch * 5.0
	for row in 3:
		for col in 11:
			var c: Color = P.CREAM
			if row == 0 and col == 0:
				c = P.RED                                  # Esc
			elif row == 1 and col == 10:
				c = P.RED                                  # Enter
			elif row == 2 and (col == 0 or col == 10):
				c = P.COBALT                               # Shifts
			ObjectLibrary.part(p, ObjectLibrary.rect(key, key, 8.0), Vector2(x0 + col * pitch, -84.0 + row * pitch), c,
				{"inlay": true, "hp": 1.0, "value": 5, "detail": ObjectLibrary.Detail.GLOSS})
	var y := 84.0
	for col in [0, 1, 2, 8, 9, 10]:
		ObjectLibrary.part(p, ObjectLibrary.rect(key, key, 8.0), Vector2(x0 + col * pitch, y), P.STONE,
			{"inlay": true, "hp": 1.0, "value": 5, "detail": ObjectLibrary.Detail.GLOSS})
	ObjectLibrary.part(p, ObjectLibrary.rect(pitch * 5.0 - 10.0, key, 8.0), Vector2(x0 + 5.0 * pitch, y), P.CREAM,
		{"inlay": true, "hp": 2.0, "value": 10, "detail": ObjectLibrary.Detail.GLOSS})   # Spacebar


static func sampler(p: Array) -> void:
	var P := ThemePalette
	ObjectLibrary.slabs(p, Vector2(460, 580), 2, 3, P.CREAM, [Vector2i(0, 1), Vector2i(1, 1)], {"hp": 4.0})
	ObjectLibrary.part(p, ObjectLibrary.rect(200, 92, 10.0), Vector2(-100, -200), P.TEAL,
		{"inlay": true, "detail": ObjectLibrary.Detail.GLOSS, "hp": 2.0})                # LCD
	for i in 3:
		ObjectLibrary.part(p, ObjectLibrary.circle(17.0, 18), Vector2(70 + i * 58, -215), P.CHARCOAL,
			{"inlay": true, "hp": 1.0, "value": 5, "detail": ObjectLibrary.Detail.HUB, "detail_color": P.CREAM})
	ObjectLibrary.part(p, ObjectLibrary.rect(130, 22, 11.0), Vector2(128, -160), P.RED, {"inlay": true, "hp": 1.0})
	var red_pad := Vector2i(randi() % 4, randi() % 4)
	for row in 4:
		for col in 4:
			var c: Color = P.RED if Vector2i(col, row) == red_pad else P.STONE
			ObjectLibrary.part(p, ObjectLibrary.rect(84, 84, 10.0), Vector2(-141 + col * 94, -60 + row * 94), c,
				{"inlay": true, "hp": 1.2, "value": 6})


static func cassette(p: Array) -> void:
	var P := ThemePalette
	var body: Color = [P.BUTTER, P.PINK, P.TANGERINE, P.MINT, P.LILAC].pick_random()
	ObjectLibrary.slabs(p, Vector2(600, 380), 3, 1, body, [Vector2i(1, 0)], {"hp": 4.5})
	ObjectLibrary.part(p, ObjectLibrary.rect(500, 120, 12.0), Vector2(0, -88), P.CREAM,
		{"inlay": true, "hp": 2.5, "detail": ObjectLibrary.Detail.TEXT, "text": "SIDE A — MIXTAPE"})
	ObjectLibrary.part(p, ObjectLibrary.rect(290, 96, 40.0), Vector2(0, 46), P.CHARCOAL, {"inlay": true, "hp": 2.0})
	for x in [-92.0, 92.0]:
		ObjectLibrary.part(p, ObjectLibrary.circle(40.0, 22), Vector2(x, 46), P.CREAM,
			{"inlay": true, "hp": 1.2, "value": 8, "detail": ObjectLibrary.Detail.HUB})
	ObjectLibrary.part_abs(p, PackedVector2Array([Vector2(-180, 172), Vector2(180, 172),
		Vector2(145, 120), Vector2(-145, 120)]), P.STONE, {"inlay": true, "hp": 1.5})
	for c in [Vector2(-270, -160), Vector2(270, -160), Vector2(-270, 160), Vector2(270, 160)]:
		ObjectLibrary.part(p, ObjectLibrary.circle(9.0, 12), c, P.INK_SOFT, {"inlay": true, "hp": 0.5, "value": 3})


static func gameboy(p: Array) -> void:
	var P := ThemePalette
	var body: Color = [P.STONE, P.LILAC, P.MINT, P.BUTTER].pick_random()
	ObjectLibrary.slabs(p, Vector2(400, 660), 2, 3, body, [Vector2i(0, 1), Vector2i(1, 1)], {"hp": 4.0})
	ObjectLibrary.part(p, ObjectLibrary.rect(330, 250, 18.0), Vector2(0, -170), P.CHARCOAL, {"inlay": true, "hp": 2.5})
	ObjectLibrary.part(p, ObjectLibrary.rect(220, 170, 6.0), Vector2(10, -170), P.MINT,
		{"inlay": true, "hp": 1.5, "detail": ObjectLibrary.Detail.GLOSS})
	ObjectLibrary.part(p, ObjectLibrary.circle(7.0, 10), Vector2(-138, -200), P.RED, {"inlay": true, "hp": 0.5})
	ObjectLibrary.part(p, ObjectLibrary.rect(116, 38, 6.0), Vector2(-95, 110), P.CHARCOAL, {"inlay": true, "hp": 1.2})
	ObjectLibrary.part(p, ObjectLibrary.rect(38, 116, 6.0), Vector2(-95, 110), P.CHARCOAL, {"inlay": true, "hp": 1.2})
	for b in [Vector2(85, 125), Vector2(150, 90)]:
		ObjectLibrary.part(p, ObjectLibrary.circle(29.0, 20), b, P.RED,
			{"inlay": true, "hp": 1.0, "value": 6, "detail": ObjectLibrary.Detail.GLOSS})
	for s in [Vector2(-40, 225), Vector2(30, 225)]:
		ObjectLibrary.part(p, ObjectLibrary.rotated(ObjectLibrary.rect(62, 18, 9.0), -0.45), s, P.INK_SOFT, {"inlay": true, "hp": 0.6})
	ObjectLibrary.part(p, ObjectLibrary.rect(100, 80, 14.0), Vector2(115, 255), P.STONE,
		{"inlay": true, "hp": 1.0, "detail": ObjectLibrary.Detail.DOTS})                  # speaker grill
