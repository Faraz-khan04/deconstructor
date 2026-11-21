class_name ScreenSpace
## Screen <-> world conversion that deliberately ignores camera-shake offset,
## so touch input stays rock steady while the screen shakes.


static func to_world(node: CanvasItem, p: Vector2) -> Vector2:
	var cam := node.get_viewport().get_camera_2d()
	if cam == null:
		return p
	return p - node.get_viewport_rect().size * 0.5 + cam.global_position


static func to_screen(node: CanvasItem, p: Vector2) -> Vector2:
	var cam := node.get_viewport().get_camera_2d()
	if cam == null:
		return p
	return p + node.get_viewport_rect().size * 0.5 - cam.global_position


## Clamp inside the screen; `bottom` reserves space for shredder + buttons.
static func clamp_play_area(node: CanvasItem, p: Vector2, margin: float, bottom: float) -> Vector2:
	var s := node.get_viewport_rect().size
	return Vector2(clampf(p.x, margin, s.x - margin), clampf(p.y, margin + 200.0, s.y - bottom))
