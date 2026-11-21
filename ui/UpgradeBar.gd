extends CanvasLayer
## Thumb-friendly upgrade bar at the bottom: POWER + MONEY are always there,
## plus the two cheapest of the other unlocked upgrades (maxed ones drop off,
## new ones slide in as they unlock). Tap to buy; hold to keep buying.
## Can afford: cream, blue border, gold dot, gentle pulse.
## Can't afford yet: grey, price still readable. Maxed: gold "MAX".
## Every purchase shows a banner saying exactly what you got.

const BAR_H := 136.0
const MARGIN := 30.0
const HOLD_START := 0.35      # hold this long, then auto-buy...
const HOLD_REPEAT := 0.09     # ...this often

var _buttons := {}        # id -> Button
var _names := {}          # id -> Label
var _prices := {}         # id -> Label
var _badges := {}         # id -> gold "you can buy this" dot
var _row: HBoxContainer
var _styles: Array = []   # can't afford / can afford / maxed (shared, built once)
var _bob_t: float = 0.0
var _held: String = ""
var _held_t: float = 0.0


func _ready() -> void:
	layer = 11
	_styles = [_sticker_style(ThemePalette.STONE, ThemePalette.INK, 4),
		_sticker_style(ThemePalette.CREAM, ThemePalette.COBALT, 6),
		_sticker_style(ThemePalette.BUTTER, ThemePalette.INK, 4)]
	_row = HBoxContainer.new()
	_row.anchor_right = 1.0
	_row.anchor_top = 1.0
	_row.anchor_bottom = 1.0
	_row.offset_left = MARGIN
	_row.offset_right = -MARGIN
	_row.offset_top = -BAR_H - 100.0     # room for the phone's gesture bar
	_row.offset_bottom = -100.0
	_row.add_theme_constant_override("separation", 16)
	add_child(_row)
	for id in Economy.ORDER:
		var b := _make_button(id)
		_row.add_child(b)
		_buttons[id] = b
	EventBus.cash_changed.connect(func(_c: int, _d: int): _refresh())
	EventBus.upgrades_changed.connect(_refresh)
	_refresh.call_deferred()


func _process(delta: float) -> void:
	_bob_t += delta
	for id in _buttons:
		var b: Button = _buttons[id]
		if b.visible and Economy.can_buy(id) and id != _held:
			b.pivot_offset = b.size * 0.5
			b.scale = Vector2.ONE * (1.0 + 0.025 * sin(_bob_t * 4.0 + b.get_index()))
	if _held != "":
		_held_t += delta / maxf(Engine.time_scale, 0.01)
		if _held_t >= HOLD_START:
			_held_t -= HOLD_REPEAT
			_try_buy(_held, true)


func _make_button(id: String) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0.0, BAR_H)
	b.focus_mode = Control.FOCUS_NONE
	b.button_down.connect(_on_down.bind(id))
	b.button_up.connect(_on_up)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_names[id] = _label(Economy.UPGRADES[id]["label"], ThemePalette.display_font, 28, ThemePalette.INK)
	_prices[id] = _label("", ThemePalette.display_font, 38, ThemePalette.INK)
	box.add_child(_names[id])
	box.add_child(_prices[id])
	b.add_child(box)
	var badge := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemePalette.BUTTER
	sb.border_color = ThemePalette.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	badge.add_theme_stylebox_override("panel", sb)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -26.0
	badge.offset_right = 6.0
	badge.offset_top = -6.0
	badge.offset_bottom = 26.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(badge)
	_badges[id] = badge
	return b


func _on_down(id: String) -> void:
	_held = id
	_held_t = 0.0
	_try_buy(id, false)


func _on_up() -> void:
	_held = ""


func _try_buy(id: String, repeat: bool) -> void:
	var b: Button = _buttons[id]
	b.pivot_offset = b.size * 0.5
	if Economy.buy(id):
		b.scale = Vector2.ONE * 0.88
		var t := b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		EventBus.banner_requested.emit("%s  LV %d" % [Economy.UPGRADES[id]["label"], Economy.levels[id]],
			Economy.effect_text(id), ThemePalette.COBALT)
		JuiceManager.buzz(25 if repeat else 35, 0.7)
		Sfx.play("buy", 1.0 + minf(Economy.levels[id] * 0.01, 0.5))
	elif not repeat:
		_held = ""
		Sfx.play("tick", 0.5)
		b.rotation = 0.0
		var t := b.create_tween()
		t.tween_property(b, "rotation", 0.06, 0.05)
		t.tween_property(b, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		_held = ""                              # ran out of cash while holding


func _refresh() -> void:
	var shown: Array = Economy.shown()
	for id in _buttons:
		var b: Button = _buttons[id]
		var was := b.visible
		b.visible = id in shown
		if b.visible and not was and is_inside_tree():  # a new upgrade slides in
			b.scale = Vector2(0.2, 0.2)
			b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.5) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not b.visible:
			if _held == id:
				_held = ""
			continue
		var maxed := Economy.is_maxed(id)
		var ok := Economy.can_buy(id)
		var price: Label = _prices[id]
		price.text = "MAX" if maxed else NumFmt.money(Economy.cost(id))
		var style: StyleBoxFlat = _styles[2 if maxed else (1 if ok else 0)]
		if b.get_theme_stylebox("normal") != style:
			for state in ["normal", "hover", "pressed", "disabled"]:
				b.add_theme_stylebox_override(state, style)
		price.label_settings.font_color = ThemePalette.COBALT if ok else ThemePalette.INK
		(_names[id] as Label).label_settings.font_color = ThemePalette.INK if ok or maxed \
			else ThemePalette.INK_SOFT
		(_badges[id] as Control).visible = ok
		if not ok and _held != id:
			b.scale = Vector2.ONE


func _sticker_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(26)
	sb.shadow_color = ThemePalette.SHADOW
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(5.0, 8.0)
	return sb


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = color
	var l := Label.new()
	l.text = text
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
