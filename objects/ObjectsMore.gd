class_name ObjectsMore
## More objects: boombox, headphones, Polaroid camera, watermelon, donut.
## Object space is centred on (0, 0); sizes are in px at 1080-wide.



static func boombox(p: Array) -> void:
	var P := ThemePalette
	var body: Color = [P.RED, P.COBALT, P.TANGERINE, P.TEAL].pick_random()
	ObjectLibrary.slabs(p, Vector2(680, 340), 4, 1, body, [Vector2i(1, 0), Vector2i(2, 0)], {"hp": 4.5})
	ObjectLibrary.part(p, ObjectLibrary.rect(380, 28, 14.0), Vector2(0, -236), P.CHARCOAL, {"hp": 2.0})      # handle
	for x in [-178.0, 178.0]:
		ObjectLibrary.part(p, ObjectLibrary.rect(28, 70, 8.0), Vector2(x, -200), P.CHARCOAL, {"hp": 1.5})
	for x in [-205.0, 205.0]:
		ObjectLibrary.part(p, ObjectLibrary.circle(112.0, 32), Vector2(x, 18), P.CHARCOAL,
			{"inlay": true, "hp": 2.5, "detail": ObjectLibrary.Detail.DOTS, "detail_color": P.INK_SOFT})
		ObjectLibrary.part(p, ObjectLibrary.circle(58.0, 26), Vector2(x, 18), P.STONE,
			{"inlay": true, "hp": 1.5, "value": 8, "detail": ObjectLibrary.Detail.HUB})
	ObjectLibrary.part(p, ObjectLibrary.rect(150, 92, 10.0), Vector2(0, -28), P.CHARCOAL,
		{"inlay": true, "hp": 1.5, "detail": ObjectLibrary.Detail.GLOSS})                 # tape deck
	for x in [-38.0, 38.0]:
		ObjectLibrary.part(p, ObjectLibrary.circle(15.0, 16), Vector2(x, 102), P.BUTTER,
			{"inlay": true, "hp": 0.8, "value": 5, "detail": ObjectLibrary.Detail.HUB})


static func headphones(p: Array) -> void:
	var P := ThemePalette
	var band: Color = [P.CHARCOAL, P.COBALT, P.TEAL].pick_random()
	var cup: Color = [P.PINK, P.BUTTER, P.MINT, P.LILAC, P.TANGERINE].pick_random()
	ObjectLibrary.arc_band(p, Vector2(0, 40), 212.0, 248.0, PI * 1.04, PI * 1.96, 7, band, [3], {"hp": 2.5})
	for side in [-1.0, 1.0]:
		var cx: float = 222.0 * side
		ObjectLibrary.part(p, ObjectLibrary.rect(34, 70, 8.0), Vector2(cx, -8), P.STONE, {"hp": 1.5})   # yoke
		ObjectLibrary.part(p, ObjectLibrary.circle(92.0, 30), Vector2(cx, 92), cup, {"hp": 3.5, "value": 15})
		ObjectLibrary.part(p, ObjectLibrary.circle(64.0, 26), Vector2(cx, 92), P.CHARCOAL, {"inlay": true, "hp": 1.5})
		ObjectLibrary.part(p, ObjectLibrary.circle(22.0, 16), Vector2(cx, 92), cup,
			{"inlay": true, "hp": 0.8, "detail": ObjectLibrary.Detail.HUB, "detail_color": P.CREAM})


static func camera(p: Array) -> void:
	var P := ThemePalette
	ObjectLibrary.slabs(p, Vector2(560, 400), 3, 2, P.CREAM, [Vector2i(1, 0), Vector2i(1, 1)], {"hp": 4.0})
	ObjectLibrary.part(p, ObjectLibrary.rect(70, 50, 8.0), Vector2(-205, -135), P.CHARCOAL,
		{"inlay": true, "hp": 1.0, "detail": ObjectLibrary.Detail.GLOSS})                 # viewfinder
	ObjectLibrary.part(p, ObjectLibrary.rect(112, 62, 8.0), Vector2(185, -132), P.STONE,
		{"inlay": true, "hp": 1.2, "detail": ObjectLibrary.Detail.LINES})                 # flash
	var stripes := [P.RED, P.TANGERINE, P.BUTTER, P.MINT, P.COBALT]
	for i in stripes.size():
		ObjectLibrary.part(p, ObjectLibrary.rect(16, 230, 0.0), Vector2(150 + i * 19, 60), stripes[i],
			{"inlay": true, "hp": 0.8, "value": 6})
	ObjectLibrary.part(p, ObjectLibrary.circle(122.0, 34), Vector2(-40, 30), P.CHARCOAL, {"inlay": true, "hp": 3.0})
	ObjectLibrary.part(p, ObjectLibrary.circle(80.0, 30), Vector2(-40, 30), P.COBALT, {"inlay": true, "hp": 2.0})
	ObjectLibrary.part(p, ObjectLibrary.circle(46.0, 24), Vector2(-40, 30), P.INK,
		{"inlay": true, "hp": 1.2, "value": 12, "detail": ObjectLibrary.Detail.GLOSS})
	ObjectLibrary.part(p, ObjectLibrary.circle(22.0, 16), Vector2(-215, 130), P.RED,
		{"inlay": true, "hp": 0.8, "detail": ObjectLibrary.Detail.GLOSS})                 # shutter


static func watermelon(p: Array) -> void:
	var P := ThemePalette
	var c := Vector2(0, -90)                       # flat side up, slice hangs down
	ObjectLibrary.arc_band(p, c, 196.0, 222.0, 0.0, PI, 7, P.TEAL, [], {"hp": 1.5, "value": 6})
	ObjectLibrary.arc_band(p, c, 176.0, 196.0, 0.0, PI, 6, P.MINT, [], {"hp": 1.2, "value": 6})
	ObjectLibrary.arc_band(p, c, 18.0, 176.0, 0.0, PI, 5, P.RED, [2],
		{"hp": 3.0, "value": 12, "detail": ObjectLibrary.Detail.SEEDS})


static func donut(p: Array) -> void:
	var P := ThemePalette
	var icing: Color = [P.PINK, P.LILAC, P.MINT, P.COBALT].pick_random()
	ObjectLibrary.arc_band(p, Vector2.ZERO, 86.0, 210.0, 0.0, TAU, 10, P.BUTTER, [0, 5], {"hp": 3.0})
	ObjectLibrary.arc_band(p, Vector2.ZERO, 104.0, 188.0, 0.0, TAU, 10, icing, [],
		{"inlay": true, "hp": 1.5, "value": 8, "detail": ObjectLibrary.Detail.SPRINKLES})
