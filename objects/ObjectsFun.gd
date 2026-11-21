class_name ObjectsFun
## Objects with personality: each breaks in its own satisfying way.
##   piggy   ceramic shell, coins burst out of every piece
##   duck    rubber, squeaks, bits bounce around the pegs
##   guitar  six strings, each twangs its own note (swipe across = a strum)
##   clock   bells ring, gears spill out of the face
##   phone   glass screen panes burst into glitter, metal frame
##   jar     glass jar stuffed with candy that pops out
##   robot   metal limbs, glowing eyes, a zapping chest panel
##   pinata  candy bursts out of every point
## (cake lives in ObjectsFun2.) Object space centred on (0, 0), px at 1080 wide.

const L := preload("res://objects/ObjectLibrary.gd")


static func make(n: String, p: Array) -> void:
	match n:
		"piggy": piggy(p)
		"duck": duck(p)
		"guitar": guitar(p)
		"clock": clock(p)
		"phone": phone(p)
		"jar": jar(p)
		"robot": robot(p)
		"pinata": pinata(p)
		"cake": ObjectsFun2.cake(p)
		_: ObjectsMore.donut(p)


static func piggy(p: Array) -> void:
	var P := ThemePalette
	var o := {"mat": Materials.CERAMIC}
	var body := {"mat": Materials.CERAMIC, "hp": 2.2, "value": 12, "spill": 4, "spill_color": P.BUTTER}
	L.arc_band(p, Vector2.ZERO, 26.0, 190.0, 0.0, TAU, 8, P.PINK, [2, 6], body)
	L.part(p, L.circle(58.0, 24), Vector2(198, 24), P.PINK.darkened(0.08), _o(o, {"hp": 1.6}))   # snout
	for y in [10.0, 38.0]:
		L.part(p, L.circle(10.0, 12), Vector2(214, y), P.INK, _o(o, {"inlay": true, "hp": 0.4}))
	L.part_abs(p, PackedVector2Array([Vector2(-120, -150), Vector2(-60, -175), Vector2(-110, -235)]),
		P.PINK.darkened(0.12), _o(o, {"hp": 1.0}))                                                  # ears
	L.part_abs(p, PackedVector2Array([Vector2(40, -178), Vector2(105, -150), Vector2(95, -230)]),
		P.PINK.darkened(0.12), _o(o, {"hp": 1.0}))
	for x in [-110.0, -40.0, 40.0, 110.0]:
		L.part(p, L.rect(46, 70, 12.0), Vector2(x, 200), P.PINK.darkened(0.15), _o(o, {"hp": 1.2}))
	L.part(p, L.circle(18.0, 14), Vector2(-200, -20), P.PINK.darkened(0.15), _o(o, {"hp": 0.6}))  # tail
	L.part(p, L.circle(15.0, 14), Vector2(110, -70), P.INK, _o(o, {"inlay": true, "hp": 0.4}))   # eye
	L.part(p, L.rect(100, 16, 8.0), Vector2(0, -150), P.INK, _o(o, {"inlay": true, "hp": 0.5}))   # coin slot


static func duck(p: Array) -> void:
	var P := ThemePalette
	var o := {"mat": Materials.RUBBER, "bouncy": true, "sound": "squeak"}
	L.arc_band(p, Vector2(-20, 70), 24.0, 175.0, 0.0, TAU, 6, P.BUTTER, [1, 4], _o(o, {"hp": 2.4}))
	L.part(p, L.circle(115.0, 28), Vector2(60, -150), P.BUTTER, _o(o, {"hp": 2.6, "anchor": true}))
	L.part(p, L.rect(120, 52, 24.0), Vector2(195, -128), P.TANGERINE, _o(o, {"hp": 1.4}))       # beak
	L.part_abs(p, PackedVector2Array([Vector2(-185, 30), Vector2(-260, -40), Vector2(-175, -10)]),
		P.BUTTER, _o(o, {"hp": 0.8}))                                                               # tail
	L.part(p, L.circle(17.0, 14), Vector2(95, -180), P.INK, _o(o, {"inlay": true, "hp": 0.5}))
	L.part(p, L.circle(6.0, 10), Vector2(101, -186), P.STICKER, _o(o, {"inlay": true, "hp": 0.3}))
	L.part(p, L.circle(72.0, 24), Vector2(-40, 70), P.BUTTER.darkened(0.12), _o(o, {"inlay": true, "hp": 1.2}))


## Six strings tuned E A D G B E: every string you cut rings its own note.
static func guitar(p: Array) -> void:
	var P := ThemePalette
	var wood: Color = [P.TANGERINE, P.RED, P.TEAL, P.COBALT].pick_random()
	L.arc_band(p, Vector2(0, 110), 44.0, 140.0, 0.0, TAU, 6, wood, [1, 4], {"hp": 2.2})          # lower bout
	L.part(p, L.circle(100.0, 28), Vector2(0, -70), wood, {"hp": 2.4})                          # upper bout
	L.part(p, L.rect(42, 230, 6.0), Vector2(0, -280), P.BUTTER.darkened(0.25), {"hp": 1.8})      # neck
	L.part(p, L.rect(74, 80, 14.0), Vector2(0, -430), P.CHARCOAL, {"hp": 1.4})                   # headstock
	for i in 6:
		L.part(p, L.circle(9.0, 10), Vector2(-44.0 if i < 3 else 44.0, -455.0 + (i % 3) * 25.0),
			P.STONE, {"hp": 0.4, "mat": Materials.METAL})                                          # tuning pegs
	L.part(p, L.circle(54.0, 24), Vector2(0, 110), P.INK, {"inlay": true, "hp": 0.8})            # sound hole
	L.part(p, L.rect(96, 20, 6.0), Vector2(0, 190), P.INK, {"inlay": true, "hp": 0.8})           # bridge
	var notes := [0.375, 0.5, 0.667, 0.891, 1.122, 1.498]       # E2 A2 D3 G3 B3 E4 (vs A3 base)
	for i in 6:
		L.part(p, L.rect(4, 600, 0.0), Vector2(-17.5 + i * 7.0, -110), P.CREAM,
			{"inlay": true, "hp": 0.15, "value": 4, "mat": Materials.METAL, "sound": "twang", "note": notes[i]})


static func clock(p: Array) -> void:
	var P := ThemePalette
	var rim: Color = [P.RED, P.COBALT, P.TEAL, P.MINT].pick_random()
	L.arc_band(p, Vector2.ZERO, 30.0, 150.0, 0.0, TAU, 8, P.CREAM, [0, 4],
		{"hp": 1.6, "spill": 3, "spill_color": P.STONE})                                         # face: gears inside
	L.arc_band(p, Vector2.ZERO, 154.0, 188.0, 0.0, TAU, 10, rim, [], {"hp": 1.4, "mat": Materials.METAL})
	for side in [-1.0, 1.0]:
		L.part(p, L.circle(60.0, 24), Vector2(118 * side, -182), P.BUTTER,
			{"hp": 2.0, "mat": Materials.METAL, "sound": "ring", "note": 1.0 if side < 0 else 1.19})
		L.part(p, L.rotated(L.rect(24, 70, 8.0), 0.5 * side), Vector2(112 * side, 182), rim,
			{"hp": 1.0, "mat": Materials.METAL})                                                   # legs
	L.part(p, L.rect(16, 54, 4.0), Vector2(0, -205), P.CHARCOAL, {"hp": 0.8, "mat": Materials.METAL})
	L.part(p, L.rect(12, 100, 4.0), Vector2(0, -45), P.INK, {"inlay": true, "hp": 0.4})          # hands
	L.part(p, L.rotated(L.rect(10, 80, 4.0), 2.0), Vector2(32, 20), P.INK, {"inlay": true, "hp": 0.4})
	L.part(p, L.circle(38.0, 18), Vector2.ZERO, P.RED, {"inlay": true, "hp": 0.6})
	for a in 4:
		L.part(p, L.circle(9.0, 10), Vector2.from_angle(a * PI * 0.5) * 118.0, P.INK,
			{"inlay": true, "hp": 0.3})


static func phone(p: Array) -> void:
	var P := ThemePalette
	var frame: Color = [P.CHARCOAL, P.STONE, P.PINK, P.COBALT].pick_random()
	L.slabs(p, Vector2(300, 590), 2, 3, frame, [Vector2i(0, 1), Vector2i(1, 1)],
		{"hp": 2.2, "mat": Materials.METAL})
	var glass := {"inlay": true, "hp": 0.9, "mat": Materials.GLASS, "detail": L.Detail.GLOSS,
		"spill": 3, "spill_color": P.STICKER}                      # glitter of glass
	for row in 3:
		for col in 2:
			L.part(p, L.rect(124, 168, 8.0), Vector2(-68 + col * 136, -184 + row * 184), P.TEAL, glass)
	var apps := [P.RED, P.BUTTER, P.MINT, P.PINK, P.LILAC, P.TANGERINE]
	for i in 6:
		L.part(p, L.rect(46, 46, 12.0), Vector2(-80 + (i % 3) * 80, -210 + (i / 3) * 80), apps[i],
			{"inlay": true, "hp": 0.4, "value": 6, "sound": "pop", "note": 0.8 + i * 0.1})
	L.part(p, L.circle(16.0, 14), Vector2(0, 250), P.STONE, {"inlay": true, "hp": 0.5})
	L.part(p, L.circle(13.0, 14), Vector2(0, -262), P.INK, {"inlay": true, "hp": 0.4, "mat": Materials.GLASS})


static func jar(p: Array) -> void:
	var P := ThemePalette
	var glass := P.MINT.lerp(P.STICKER, 0.55)
	L.slabs(p, Vector2(320, 380), 2, 3, glass, [Vector2i(0, 0), Vector2i(1, 0)],
		{"hp": 1.4, "mat": Materials.GLASS, "detail": L.Detail.GLOSS})
	L.part(p, L.rect(340, 60, 14.0), Vector2(0, -222), P.RED, {"hp": 2.0, "mat": Materials.METAL, "anchor": true})
	L.part(p, L.rect(80, 34, 10.0), Vector2(0, -268), P.RED.darkened(0.2), {"hp": 1.0, "mat": Materials.METAL})
	var candy := [P.PINK, P.BUTTER, P.LILAC, P.TANGERINE, P.RED, P.COBALT]
	for i in 12:
		var c: Color = candy[i % candy.size()]
		L.part(p, L.circle(25.0, 16), Vector2(-110 + (i % 4) * 73 + (18 if (i / 4) % 2 == 1 else 0),
			-120 + (i / 4) * 105), c, {"inlay": true, "hp": 0.5, "value": 6, "spill": 2, "spill_color": c,
			"sound": "pop", "note": 0.9 + randf() * 0.4})


static func robot(p: Array) -> void:
	var P := ThemePalette
	var steel: Color = [P.STONE, P.COBALT, P.TEAL, P.CHARCOAL].pick_random()
	var m := {"mat": Materials.METAL}
	L.slabs(p, Vector2(250, 230), 2, 2, steel, [Vector2i(0, 0), Vector2i(1, 0)], _o(m, {"hp": 2.6}))
	L.part(p, L.rect(150, 90, 10.0), Vector2(0, -10), P.TEAL,
		{"inlay": true, "hp": 1.0, "mat": Materials.ELECTRO, "detail": L.Detail.LINES})            # chest panel
	L.part(p, L.rect(190, 140, 24.0), Vector2(0, -185), steel, _o(m, {"hp": 2.2}))               # head
	for x in [-45.0, 45.0]:
		L.part(p, L.circle(24.0, 18), Vector2(x, -195), P.MINT, {"inlay": true, "hp": 0.6, "mat": Materials.GLASS})
	L.part(p, L.rect(90, 22, 6.0), Vector2(0, -140), P.INK, {"inlay": true, "hp": 0.5, "detail": L.Detail.DOTS})
	L.part(p, L.rect(10, 50, 3.0), Vector2(0, -280), P.CHARCOAL, _o(m, {"hp": 0.5}))              # antenna
	L.part(p, L.circle(17.0, 16), Vector2(0, -318), P.RED, {"hp": 0.5, "sound": "ring", "note": 1.6})
	for s in [-1.0, 1.0]:
		L.part(p, L.rect(48, 105, 14.0), Vector2(150 * s, -40), steel, _o(m, {"hp": 1.4}))
		L.part(p, L.rect(44, 100, 14.0), Vector2(152 * s, 68), steel.darkened(0.15), _o(m, {"hp": 1.2}))
		L.part(p, L.circle(32.0, 18), Vector2(152 * s, 145), P.CHARCOAL, _o(m, {"hp": 1.0}))
		L.part(p, L.rect(66, 110, 12.0), Vector2(60 * s, 172), steel.darkened(0.1), _o(m, {"hp": 1.6}))
		L.part(p, L.rect(104, 38, 12.0), Vector2(66 * s, 245), P.CHARCOAL, _o(m, {"hp": 1.0}))
		L.part(p, L.circle(10.0, 12), Vector2(95 * s, -90), P.BUTTER,
			{"inlay": true, "hp": 0.3, "mat": Materials.METAL, "spill": 1, "spill_color": P.STONE})


## A star pinata: every point is stuffed with candy.
static func pinata(p: Array) -> void:
	var P := ThemePalette
	var cols := [P.PINK, P.BUTTER, P.MINT, P.LILAC, P.TANGERINE]
	var core := PackedVector2Array()
	for i in 5:
		core.append(Vector2.from_angle(-PI * 0.5 + TAU * i / 5.0 + PI / 5.0) * 105.0)
	L.part(p, core, Vector2.ZERO, P.RED, {"hp": 2.0, "anchor": true, "spill": 6, "spill_color": P.PINK})
	for i in 5:
		var a := -PI * 0.5 + TAU * i / 5.0
		var tip := Vector2.from_angle(a) * 250.0
		var l := Vector2.from_angle(a - PI / 5.0) * 111.0
		var r := Vector2.from_angle(a + PI / 5.0) * 111.0
		L.part_abs(p, PackedVector2Array([l, tip, r]), cols[i],
			{"hp": 1.6, "spill": 5, "spill_color": cols[(i + 2) % 5], "sound": "pop", "note": 0.8 + i * 0.12})
		var mid := (l + r) * 0.5
		L.part(p, L.rotated(L.rect(16, 90, 4.0), a), mid.lerp(tip, 0.45), cols[(i + 1) % 5],
			{"inlay": true, "hp": 0.4})                                                            # fringe


static func _o(base: Dictionary, extra: Dictionary) -> Dictionary:
	var d := base.duplicate()
	d.merge(extra, true)
	return d
