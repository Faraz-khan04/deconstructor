extends ColorRect
## Full-screen graph-paper background. Oversized so camera shake never shows
## an edge. All colours come from ThemePalette and are pushed into the shader.
## v14: the shader paints a half-size picture only 8 times a second (its grain
## already ticks at 8 fps); the picture is shown stretched. Much cheaper.

const PAD := 240.0  # extra px on every side (covers max shake offset)
const SCALE := 0.5
const REFRESH := 0.125

var _view: SubViewport
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # never steal touches
	z_index = -10

	var vp := get_viewport_rect().size
	position = Vector2(-PAD, -PAD)
	size = vp + Vector2(PAD, PAD) * 2.0

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/paper.gdshader")
	mat.set_shader_parameter("origin", position)
	mat.set_shader_parameter("rect_size", size)

	mat.set_shader_parameter("paper", ThemePalette.PAPER)
	mat.set_shader_parameter("minor_color", ThemePalette.with_alpha(ThemePalette.INK, 0.06))
	mat.set_shader_parameter("major_color", ThemePalette.with_alpha(ThemePalette.INK, 0.11))

	# Pastel haze across the top, faint cool wash lower down.
	mat.set_shader_parameter("blob_a", ThemePalette.with_alpha(ThemePalette.PINK, 0.42))
	mat.set_shader_parameter("blob_a_geo", Vector3(vp.x * 0.2, vp.y * 0.04, 760.0))
	mat.set_shader_parameter("blob_b", ThemePalette.with_alpha(ThemePalette.BUTTER, 0.55))
	mat.set_shader_parameter("blob_b_geo", Vector3(vp.x * 0.85, vp.y * 0.02, 720.0))
	mat.set_shader_parameter("blob_c", ThemePalette.with_alpha(ThemePalette.COBALT, 0.10))
	mat.set_shader_parameter("blob_c_geo", Vector3(vp.x * 0.9, vp.y * 0.55, 650.0))

	# Drifting, breathing glow along the bottom of the page.
	mat.set_shader_parameter("blob_d", ThemePalette.with_alpha(ThemePalette.LILAC, 0.30))
	mat.set_shader_parameter("blob_d_geo", Vector3(vp.x * 0.15, vp.y * 0.97, 820.0))
	mat.set_shader_parameter("blob_e", ThemePalette.with_alpha(ThemePalette.MINT, 0.28))
	mat.set_shader_parameter("blob_e_geo", Vector3(vp.x * 0.85, vp.y * 1.02, 780.0))

	_bake(mat)


## Shader -> half-size picture, refreshed by _process.
func _bake(mat: ShaderMaterial) -> void:
	self_modulate.a = 0.0               # the rect itself draws nothing now
	_view = SubViewport.new()
	_view.size = Vector2i((size * SCALE).ceil())
	_view.disable_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_view)
	var rect := ColorRect.new()
	rect.size = Vector2(_view.size)
	rect.material = mat
	_view.add_child(rect)
	var show := Sprite2D.new()
	show.centered = false
	show.texture = _view.get_texture()
	show.scale = Vector2.ONE / SCALE
	add_child(show)


func _process(delta: float) -> void:
	_t += delta
	if _t >= REFRESH and _view:
		_t = 0.0
		_view.render_target_update_mode = SubViewport.UPDATE_ONCE
