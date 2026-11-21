class_name FloatingTextPool
extends Node2D
## Pooled world-space popups styled as die-cut stickers: heavy Montserrat in an
## accent colour, thick white border, soft offset shadow, slapped on at a tilt.
## All Labels are created once in _ready; spawn() only recycles.

const POOL_SIZE := 32
const RISE := 160.0      # px travelled upward
const LIFETIME := 0.9    # seconds
const EDGE := 24.0       # min gap to the screen edge
const TOP_SAFE := 520.0  # HUD + banner strip live above this (screen px)

var _pool: Array[Label] = []
var _settings: Array[LabelSettings] = []
var _tweens: Array[Tween] = []
var _next: int = 0


func _ready() -> void:
	z_index = 100  # above gameplay, still in world space (follows camera shake)

	for i in POOL_SIZE:
		var ls := LabelSettings.new()
		ls.font = ThemePalette.display_font
		ls.font_size = 76
		ls.outline_size = 20
		ls.outline_color = ThemePalette.STICKER
		ls.shadow_size = 20
		ls.shadow_color = ThemePalette.SHADOW
		ls.shadow_offset = Vector2(6.0, 9.0)

		var label := Label.new()
		label.label_settings = ls
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.visible = false
		add_child(label)

		_pool.append(label)
		_settings.append(ls)
		_tweens.append(null)


func spawn(text: String, world_pos: Vector2, color: Color, size_mult: float = 1.0) -> void:
	# Ring buffer: if all 32 are on screen, the oldest one gets recycled.
	var i := _next
	_next = (_next + 1) % POOL_SIZE
	var label := _pool[i]
	if _tweens[i] != null and _tweens[i].is_valid():
		_tweens[i].kill()

	_settings[i].font_color = color
	label.text = text
	label.reset_size()
	world_pos = _keep_on_screen(world_pos, label.size, size_mult)
	world_pos = _keep_on_screen(_find_room(i, world_pos, label.size * size_mult), label.size, size_mult)
	if label.size.x * size_mult > _visible().size.x - EDGE * 2.0:   # too wide: shrink to fit
		size_mult = (_visible().size.x - EDGE * 2.0) / label.size.x
	label.pivot_offset = label.size * 0.5
	label.position = world_pos - label.pivot_offset
	label.modulate = Color.WHITE
	label.scale = Vector2.ONE * 0.3
	var rest_tilt := randf_range(-0.12, 0.12)  # stickers never land perfectly straight
	label.rotation = rest_tilt + randf_range(-0.35, 0.35)
	label.visible = true

	var end_y := label.position.y - RISE
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "scale", Vector2.ONE * size_mult, 0.32) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "rotation", rest_tilt, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "position:y", end_y, LIFETIME) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", Vector2.ONE * size_mult * 0.6, 0.25) \
		.set_delay(LIFETIME - 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(LIFETIME - 0.25)
	t.chain().tween_callback(label.hide)
	_tweens[i] = t


## Step down (then up) out of the way of stickers that are still fresh, so
## a burst of tags reads as a neat stack instead of a pile.
func _find_room(me: int, p: Vector2, sz: Vector2) -> Vector2:
	var step := maxf(sz.y * 0.8, 60.0)
	for attempt in 6:
		var hit := false
		for j in POOL_SIZE:
			var o := _pool[j]
			if j == me or not o.visible or o.modulate.a < 0.6:
				continue
			var oc := o.position + o.pivot_offset
			if absf(oc.x - p.x) < (o.size.x * o.scale.x + sz.x) * 0.45 \
					and absf(oc.y - p.y) < (o.size.y * o.scale.y + sz.y) * 0.4:
				hit = true
				break
		if not hit:
			return p
		p.y += step * (1.0 if attempt < 4 else -3.0)
	return p


## The part of the world the camera currently shows.
func _visible() -> Rect2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()


## Keep the whole sticker (at its final size, tilt and rise) 24 px+ inside the
## screen, and below the HUD + banner strip at the top.
func _keep_on_screen(p: Vector2, label_size: Vector2, size_mult: float) -> Vector2:
	var vis := _visible()
	var half := minf(label_size.x * size_mult * 0.5 + 20.0, vis.size.x * 0.5 - EDGE)
	p.x = clampf(p.x, vis.position.x + EDGE + half, vis.end.x - EDGE - half)
	p.y = clampf(p.y, vis.position.y + TOP_SAFE + RISE, vis.end.y - 520.0)
	return p
