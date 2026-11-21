extends CanvasLayer
## Editorial HUD: stacked lowercase logo top-left, DM Mono caption + chunky
## counting score top-right, bobbing "drag to spin" hint at the bottom that
## springs away on first touch. Built entirely in code.

const MARGIN := 56.0
const TOP := 90.0  # clears notches / status bar

var _score: int = 0
var _shown: float = 0.0
var _score_label: Label
var _hint: Label
var _level_label: Label
var _spend: Label
var _spend_sum: int = 0
var _spend_tween: Tween
var _count_tween: Tween
var _punch_tween: Tween
var _hint_tween: Tween


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var logo := _make_label("decon\nstructor", ThemePalette.display_font, 50, ThemePalette.INK)
	logo.label_settings.line_spacing = -20.0
	logo.position = Vector2(MARGIN, TOP)
	root.add_child(logo)

	var caption := _make_label("CASH", ThemePalette.mono_font, 24, ThemePalette.INK_SOFT)
	_anchor_right(caption, TOP)
	root.add_child(caption)

	_score_label = _make_label("$0", ThemePalette.display_font, 84, ThemePalette.INK)
	_anchor_right(_score_label, TOP + 26.0)
	root.add_child(_score_label)

	_level_label = _make_label("LEVEL 1", ThemePalette.display_font, 32, ThemePalette.INK)
	_anchor_right(_level_label, TOP + 118.0)
	root.add_child(_level_label)

	_spend = _make_label("", ThemePalette.display_font, 40, ThemePalette.RED)   # "-$13K"
	_anchor_right(_spend, TOP + 118.0)
	_spend.offset_right = -MARGIN - 210.0     # left of "LEVEL n", clear of the gold chip
	_spend.modulate.a = 0.0
	root.add_child(_spend)

	_hint = _make_label("DRAG TO CUT", ThemePalette.mono_font, 30, ThemePalette.INK)
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -300.0
	_hint.offset_right = 300.0
	_hint.offset_top = -1280.0         # just above the peg board
	_hint.offset_bottom = -1230.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)
	_start_hint_bob.call_deferred()

	# Level progress squares, top centre
	var pips := preload("res://ui/ProgressPips.gd").new() as Control
	pips.anchor_left = 0.5
	pips.anchor_right = 0.5
	pips.offset_left = -170.0
	pips.offset_right = 170.0
	pips.offset_top = TOP + 18.0
	pips.offset_bottom = TOP + 60.0
	root.add_child(pips)
	var combo := preload("res://ui/ComboBadge.gd").new() as Control
	combo.anchor_left = 0.5
	combo.anchor_right = 0.5
	combo.offset_left = -170.0
	combo.offset_right = 170.0
	combo.offset_top = TOP + 195.0      # under the job clock, clear of the catalog button
	combo.offset_bottom = TOP + 265.0
	root.add_child(combo)
	root.add_child(MenuScreen.menu_button(Vector2(MARGIN, TOP + 200.0)))   # back to the modes

	EventBus.cash_changed.connect(_on_cash_changed)
	EventBus.level_started.connect(_on_level_started)


func _input(event: InputEvent) -> void:
	if _hint.visible and event is InputEventScreenTouch and event.pressed:
		_dismiss_hint()


func _on_cash_changed(cash: int, delta: int) -> void:
	_score = cash

	if _count_tween and _count_tween.is_valid():
		_count_tween.kill()
	_count_tween = create_tween()
	_count_tween.tween_method(_set_shown, _shown, float(_score), 0.45) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	if delta < 0:
		_show_spend(delta)                 # spending: show where the money went
		return
	if delta == 0:
		return
	if _punch_tween and _punch_tween.is_valid():
		_punch_tween.kill()
	_score_label.pivot_offset = Vector2(_score_label.size.x, _score_label.size.y * 0.5)
	_score_label.scale = Vector2.ONE * 1.22
	_score_label.rotation = randf_range(-0.08, 0.08)
	_punch_tween = create_tween().set_parallel(true)
	_punch_tween.tween_property(_score_label, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(_score_label, "rotation", 0.0, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_level_started(level: int) -> void:
	_level_label.text = "LEVEL %d" % level
	_level_label.pivot_offset = Vector2(_level_label.size.x, _level_label.size.y * 0.5)
	_level_label.scale = Vector2.ONE * 1.6
	_level_label.create_tween().tween_property(_level_label, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)



func _show_spend(delta: int) -> void:
	_spend_sum = (_spend_sum if _spend.modulate.a > 0.05 else 0) + delta   # quick buys add up
	_spend.text = NumFmt.money(_spend_sum)
	_spend.modulate.a = 1.0
	_spend.position.x = _spend_x()
	if _spend_tween and _spend_tween.is_valid():
		_spend_tween.kill()
	var t := _spend.create_tween().set_parallel(true)
	_spend_tween = t
	t.tween_property(_spend, "position:x", _spend_x() - 50.0, 0.9).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(_spend, "modulate:a", 0.0, 0.4).set_delay(0.5)


func _spend_x() -> float:
	return _spend.get_parent_control().size.x - 480.0


func _set_shown(v: float) -> void:
	_shown = v
	_score_label.text = NumFmt.money(round(v))


func _start_hint_bob() -> void:
	var y := _hint.position.y
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_hint, "position:y", y - 12.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_tween.tween_property(_hint, "position:y", y, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _dismiss_hint() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint.pivot_offset = _hint.size * 0.5
	var t := create_tween().set_parallel(true)
	t.tween_property(_hint, "scale", Vector2.ZERO, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_hint, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(_hint.hide)


func _make_label(text: String, font: Font, size: int, color: Color) -> Label:
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = color
	var l := Label.new()
	l.text = text
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _anchor_right(l: Label, top: float) -> void:
	l.anchor_left = 1.0
	l.anchor_right = 1.0
	l.offset_left = -480.0
	l.offset_right = -MARGIN
	l.offset_top = top
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
