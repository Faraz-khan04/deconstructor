class_name TrailStyle
## Pink highlighter trail behind the saw: tapered, rounded, fades at the tail.


static func apply(trail: Line2D, radius: float) -> void:
	trail.top_level = true          # points live in world space
	trail.z_index = -1              # under the saw and its shadow
	trail.clear_points()
	trail.width = radius * 1.15
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.0))
	taper.add_point(Vector2(1.0, 1.0))
	trail.width_curve = taper
	trail.gradient = ThemePalette.trail_gradient(ThemePalette.PINK, 0.55)
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
