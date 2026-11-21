extends Node2D
## Persistent paint on the paper. A SubViewport that NEVER clears acts as the
## canvas; pooled PaintSplash nodes draw into it, and a Sprite2D shows it in
## world space with the glossy "puffy paint" shader.
## Each canvas uses ONE curated palette so the artwork always looks designed.
## Cost stays flat no matter how much paint has built up.

const POOL_SIZE := 12
const CANVAS_SCALE := 0.5

@export_range(0.0, 1.0) var paint_opacity: float = 0.72  # softer, so objects stay sharp
## false = always use the full colour range (palette 0).
## true  = each fresh canvas picks a themed 4-colour set.
@export var themed_palettes: bool = false

var palette_index: int = -1

var _canvas: SubViewport
var _mat: ShaderMaterial
var _splash_count: int = 0
var _pool: Array[PaintSplash] = []
var _next: int = 0
var _last_color: Color
var _last_style: int = -1


func _ready() -> void:
	z_index = -8  # above Paper (-10), below trail (-1) and the saw

	_canvas = SubViewport.new()
	_canvas.size = Vector2i(get_viewport_rect().size * CANVAS_SCALE)   # v14: half size
	_canvas.transparent_bg = true
	_canvas.disable_3d = true
	_canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_canvas.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE  # then never
	add_child(_canvas)
	_canvas.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * CANVAS_SCALE)

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/paint_gloss.gdshader")
	mat.set_shader_parameter("shadow_color", ThemePalette.INK)
	mat.set_shader_parameter("opacity", paint_opacity)
	mat.set_shader_parameter("canvas_height", get_viewport_rect().size.y)
	mat.set_shader_parameter("bevel_px", 2.5)
	mat.set_shader_parameter("shadow_offset_px", Vector2(2.0, 3.5))
	_mat = mat

	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = _canvas.get_texture()
	sprite.material = mat
	sprite.scale = Vector2.ONE / CANVAS_SCALE
	add_child(sprite)

	for i in POOL_SIZE:
		var s := PaintSplash.new()
		_canvas.add_child(s)
		_pool.append(s)
	_canvas.add_child(preload("res://paint/BurnMarks.gd").new())   # laser scorch lines

	EventBus.splash.connect(_on_splash)
	EventBus.paint_clear_requested.connect(func(): EventBus.wipe_requested.emit())
	EventBus.wipe_progress.connect(_on_wipe_progress)
	EventBus.wipe_finished.connect(_on_wipe_finished)
	_next_palette.call_deferred()  # deferred so the HUD is listening


## Wipes the paper and moves on to a fresh palette.
func clear_paint() -> void:
	_canvas.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	_next_palette()


## How many splashes are on the page right now (used for the wipe bonus).
func splash_count() -> int:
	return _splash_count


func _on_wipe_progress(world_y: float) -> void:
	_mat.set_shader_parameter("wipe_y", world_y)


## Squeegee is past the bottom: really clear the canvas, then (two frames
## later, once the cleared canvas has rendered) drop the erase mask.
func _on_wipe_finished() -> void:
	_canvas.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	_splash_count = 0
	await get_tree().process_frame
	await get_tree().process_frame
	_mat.set_shader_parameter("wipe_y", -100000.0)


func _on_splash(world_pos: Vector2, direction: Vector2, strength: float, color: Color) -> void:
	_splash_count += 1
	var s := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	var main := color if color.a > 0.0 else _pick_color(_last_color)
	_last_color = main
	var accent := _pick_color(main)
	var style := SplashRecipes.pick(strength, direction.length(), _last_style)
	_last_style = style
	s.play(world_pos, direction, strength, main, accent, style)


func _next_palette() -> void:
	var count: int = ThemePalette.PAINT_PALETTES.size()
	var i := 0
	if themed_palettes and count > 2:
		i = randi_range(1, count - 1)          # themed sets only
		while i == palette_index:
			i = randi_range(1, count - 1)
	palette_index = i
	EventBus.palette_changed.emit(ThemePalette.PAINT_PALETTES[i]["name"])


## Colour from the current palette that differs from `avoid`.
func _pick_color(avoid: Color) -> Color:
	var colors: Array = ThemePalette.PAINT_PALETTES[maxi(palette_index, 0)]["colors"]
	var c: Color = colors.pick_random()
	while c == avoid and colors.size() > 1:
		c = colors.pick_random()
	return c
