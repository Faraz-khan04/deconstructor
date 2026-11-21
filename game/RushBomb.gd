class_name RushBomb
## The RUSH bomb, built like any other object (one round part + a fuse) so
## the saw, physics and drawing all just work. Bright red so you can't miss it.


static func def() -> Dictionary:
	var parts: Array = []
	var body := PackedVector2Array()
	for i in 28:
		body.append(Vector2.from_angle(TAU * i / 28.0) * 86.0)
	ObjectLibrary.part(parts, body, Vector2.ZERO, ThemePalette.RED,
		{"anchor": true, "hp": 0.2, "value": 0, "detail": ObjectLibrary.Detail.TEXT, "text": "BOMB"})
	var fuse := PackedVector2Array([Vector2(-10, -26), Vector2(10, -26), Vector2(10, 26), Vector2(-10, 26)])
	ObjectLibrary.part(parts, fuse, Vector2(0, -104), ThemePalette.INK,
		{"inlay": true, "hp": 0.2, "value": 0})
	return {"name": "bomb", "spin": false, "parts": parts}
