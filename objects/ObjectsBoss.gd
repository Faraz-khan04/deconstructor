class_name ObjectsBoss
## Boss gadgets (end of every 5th level): old TV, arcade cabinet, synth.
## Their shell slabs are armored: the saw only sparks off them until every
## screw has been cut out. Object space is centred on (0, 0), px at 1080-wide.


static func tv(p: Array) -> void:
	var P := ThemePalette
	var body: Color = [P.TANGERINE, P.TEAL, P.RED, P.LILAC].pick_random()
	ObjectLibrary.slabs(p, Vector2(720, 600), 3, 3, body,
		[Vector2i(1, 0), Vector2i(1, 1)], {"hp": 5.0, "armor": true, "value": 20})
	# Antenna on top (not armored: an easy first bite)
	ObjectLibrary.part(p, ObjectLibrary.circle(26.0, 18), Vector2(0, -318), P.CHARCOAL, {"hp": 1.5})
	for side in [-1.0, 1.0]:
		ObjectLibrary.part(p, ObjectLibrary.rotated(ObjectLibrary.rect(14, 220, 7.0), 0.45 * side),
			Vector2(48.0 * side, -415), P.INK_SOFT, {"hp": 1.0, "value": 8})
		ObjectLibrary.part(p, ObjectLibrary.rect(70, 34, 8.0), Vector2(250.0 * side, 318),
			P.CHARCOAL, {"hp": 1.0})                                    # feet
	ObjectLibrary.part(p, ObjectLibrary.rect(480, 410, 46.0), Vector2(-85, -10), P.CHARCOAL,
		{"inlay": true, "hp": 3.0})
	ObjectLibrary.part(p, ObjectLibrary.rect(400, 330, 60.0), Vector2(-85, -10), P.MINT,
		{"inlay": true, "hp": 2.0, "value": 20, "detail": ObjectLibrary.Detail.GLOSS})
	for y in [-160.0, -55.0]:
		ObjectLibrary.part(p, ObjectLibrary.circle(30.0, 20), Vector2(250, y), P.STONE,
			{"inlay": true, "hp": 1.2, "detail": ObjectLibrary.Detail.HUB})
	ObjectLibrary.part(p, ObjectLibrary.rect(110, 150, 14.0), Vector2(250, 120), P.STONE,
		{"inlay": true, "hp": 1.5, "detail": ObjectLibrary.Detail.DOTS})
	for c in [Vector2(-330, -270), Vector2(330, -270), Vector2(-330, 270), Vector2(330, 270),
			Vector2(-330, 0), Vector2(330, 0)]:
		ObjectLibrary.screw(p, c)


static func arcade(p: Array) -> void:
	var P := ThemePalette
	var body: Color = [P.COBALT, P.RED, P.LILAC, P.TEAL].pick_random()
	ObjectLibrary.slabs(p, Vector2(500, 820), 2, 4, body,
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
		{"hp": 5.0, "armor": true, "value": 20})
	ObjectLibrary.part(p, ObjectLibrary.rect(440, 80, 12.0), Vector2(0, -352), P.BUTTER,
		{"inlay": true, "hp": 1.5, "detail": ObjectLibrary.Detail.TEXT, "text": "ARCADE"})
	ObjectLibrary.part(p, ObjectLibrary.rect(420, 300, 24.0), Vector2(0, -150), P.CHARCOAL,
		{"inlay": true, "hp": 2.5})
	ObjectLibrary.part(p, ObjectLibrary.rect(340, 230, 30.0), Vector2(0, -150), P.MINT,
		{"inlay": true, "hp": 1.5, "value": 20, "detail": ObjectLibrary.Detail.GLOSS})
	ObjectLibrary.part(p, ObjectLibrary.rect(440, 120, 16.0), Vector2(0, 85), P.STONE,
		{"inlay": true, "hp": 2.0})                                     # control panel
	ObjectLibrary.part(p, ObjectLibrary.rect(12, 46, 6.0), Vector2(-130, 100), P.INK,
		{"inlay": true, "hp": 0.8})                                     # joystick stick
	ObjectLibrary.part(p, ObjectLibrary.circle(24.0, 18), Vector2(-130, 72), P.RED,
		{"inlay": true, "hp": 0.8, "value": 10, "detail": ObjectLibrary.Detail.GLOSS})
	var cols := [P.BUTTER, P.PINK, P.MINT, P.TANGERINE]
	for i in 4:
		ObjectLibrary.part(p, ObjectLibrary.circle(19.0, 16), Vector2(10 + i * 50, 85), cols[i],
			{"inlay": true, "hp": 0.8, "value": 8, "detail": ObjectLibrary.Detail.GLOSS})
	ObjectLibrary.part(p, ObjectLibrary.rect(130, 160, 12.0), Vector2(0, 268), P.CHARCOAL,
		{"inlay": true, "hp": 2.0})                                     # coin door
	for x in [-26.0, 26.0]:
		ObjectLibrary.part(p, ObjectLibrary.rect(14, 54, 5.0), Vector2(x, 255), P.RED,
			{"inlay": true, "hp": 0.6, "value": 10})
	for c in [Vector2(-215, -385), Vector2(215, -385), Vector2(-215, 0), Vector2(215, 0),
			Vector2(-215, 385), Vector2(215, 385)]:
		ObjectLibrary.screw(p, c)


static func synth(p: Array) -> void:
	var P := ThemePalette
	var body: Color = [P.RED, P.TEAL, P.COBALT, P.TANGERINE].pick_random()
	ObjectLibrary.slabs(p, Vector2(860, 380), 5, 1, body, [Vector2i(2, 0)],
		{"hp": 5.0, "armor": true, "value": 20})
	for i in 5:
		ObjectLibrary.part(p, ObjectLibrary.circle(22.0, 18), Vector2(-330 + i * 100, -120), P.STONE,
			{"inlay": true, "hp": 1.0, "value": 8, "detail": ObjectLibrary.Detail.HUB})
	ObjectLibrary.part(p, ObjectLibrary.rect(170, 64, 10.0), Vector2(275, -120), P.MINT,
		{"inlay": true, "hp": 1.2, "detail": ObjectLibrary.Detail.GLOSS})
	var x0 := -364.0
	for i in 14:                                                      # white keys
		ObjectLibrary.part(p, ObjectLibrary.rect(52, 170, 6.0), Vector2(x0 + i * 56, 70), P.CREAM,
			{"inlay": true, "hp": 1.0, "value": 6})
	for i in 13:                                                      # black keys
		if i % 7 == 2 or i % 7 == 6:
			continue
		ObjectLibrary.part(p, ObjectLibrary.rect(32, 100, 5.0), Vector2(x0 + i * 56 + 28, 35),
			P.CHARCOAL, {"inlay": true, "hp": 0.8, "value": 8})
	for c in [Vector2(-405, -165), Vector2(405, -165), Vector2(-405, 165), Vector2(405, 165)]:
		ObjectLibrary.screw(p, c)
