class_name ObjectsFun2
## More soft objects. cake: three tiers of sponge that splat and paint the
## page, frosting drips, candles and a cherry that pops.

const L := preload("res://objects/ObjectLibrary.gd")


static func cake(p: Array) -> void:
	var P := ThemePalette
	var soft := {"mat": Materials.FRUIT}
	L.part(p, L.rect(540, 26, 12.0), Vector2(0, 205), P.STONE,
		{"hp": 2.0, "anchor": true, "mat": Materials.CERAMIC})                                     # plate
	L.slabs(p, Vector2(470, 140), 3, 1, P.PINK, [], _o(soft, {"hp": 2.0, "detail": L.Detail.SPRINKLES}))
	_shift(p, 3, Vector2(0, 120))
	L.slabs(p, Vector2(340, 120), 2, 1, P.CREAM, [], _o(soft, {"hp": 1.8}))
	_shift(p, 2, Vector2(0, -12))
	L.slabs(p, Vector2(220, 100), 1, 1, P.BUTTER, [], _o(soft, {"hp": 1.6}))
	_shift(p, 1, Vector2(0, -122))
	for i in 7:                                                                                    # frosting drips
		L.part(p, L.rect(34, 40 + (i % 3) * 14, 16.0), Vector2(-195 + i * 65, 68 + (i % 3) * 6), P.STICKER,
			_o(soft, {"inlay": true, "hp": 0.4}))
	for i in 3:
		var x := -60.0 + i * 60.0
		L.part(p, L.rect(14, 64, 5.0), Vector2(x, -204), [P.LILAC, P.MINT, P.COBALT][i], {"hp": 0.5})
		L.part(p, L.circle(10.0, 12), Vector2(x, -246), P.TANGERINE,
			{"hp": 0.3, "sound": "pop", "note": 1.3 + i * 0.1})                                   # flames
	L.part(p, L.circle(24.0, 16), Vector2(0, -190), P.RED,
		_o(soft, {"inlay": true, "hp": 0.4, "sound": "pop", "note": 0.7}))                         # cherry


## Moves the last `count` parts by `by` (slabs() always centres on 0, 0).
static func _shift(p: Array, count: int, by: Vector2) -> void:
	for i in range(p.size() - count, p.size()):
		p[i]["pos"] = p[i]["pos"] + by


static func _o(base: Dictionary, extra: Dictionary) -> Dictionary:
	var d := base.duplicate()
	d.merge(extra, true)
	return d
