extends CanvasLayer
## The CATALOG button (top-left, under the logo) and the blueprint screen it
## opens. While the screen is open the game is paused. Works while paused.
## One gadget left: the button turns gold, says "1 LEFT!" and wiggles.

const TOP := 90.0

var _button: Button
var _panel: Control
var _nudge: bool = false
var _t: float = 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	_button.position = Vector2(52.0, TOP + 118.0)
	_button.custom_minimum_size = Vector2(250.0, 60.0)
	_button.add_theme_font_override("font", ThemePalette.mono_font)
	_button.add_theme_font_size_override("font_size", 22)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		_button.add_theme_color_override(c, ThemePalette.INK)
	_button.pressed.connect(open)
	add_child(_button)

	_panel = preload("res://ui/CatalogPanel.gd").new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	_panel.connect("closed", close)
	add_child(_panel)

	EventBus.golden_found.connect(func(_g: String, _s: int, _p: Vector2): _refresh_button())
	EventBus.level_started.connect(func(_l: int): _refresh_button())
	EventBus.tool_changed.connect(func(_t: String): _refresh_button())
	EventBus.gadget_smashed.connect(func(_g: String, _f: bool): _refresh_button())
	_refresh_button()


func open() -> void:
	if _panel.visible:
		return
	get_tree().paused = true
	_panel.call("refresh")
	_panel.visible = true
	_panel.position.y = _panel.size.y
	var t := create_tween()
	t.tween_property(_panel, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	var t := create_tween()
	t.tween_property(_panel, "position:y", _panel.size.y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(_after_close)


func _after_close() -> void:
	_panel.visible = false
	get_tree().paused = false
	_refresh_button()


func _process(delta: float) -> void:
	_t += delta
	if _nudge and not _panel.visible:
		_button.rotation = sin(_t * 9.0) * 0.06 * maxf(0.0, sin(_t * 1.6))   # wiggle bursts


func _refresh_button() -> void:
	var left := ObjectLibrary.ALL.size() - Save.smashed_count()
	_nudge = left == 1
	_button.text = "CATALOG  1 LEFT!" if _nudge else "CATALOG  %d/%d" % [Save.smashed_count(),
		ObjectLibrary.ALL.size()]
	for state in ["normal", "hover", "pressed"]:
		_button.add_theme_stylebox_override(state, _style(ThemePalette.BUTTER if _nudge else ThemePalette.STICKER))
	if not _nudge:
		_button.rotation = 0.0
	_button.pivot_offset = _button.size * 0.5
	_button.scale = Vector2.ONE * 1.12
	create_tween().tween_property(_button, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _style(fill: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = ThemePalette.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.shadow_color = ThemePalette.SHADOW
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(4.0, 6.0)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	return sb
