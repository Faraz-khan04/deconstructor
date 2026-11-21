class_name TestSwitches
extends CanvasLayer
## v14 TEST BUILD: three switches on the JOBS screen to feel the new direction
## against the old one, mid-game. Tap a chip (or press 1 / 2 / 3 on desktop).
##   FREE CUT  on: cutting costs no power (no budget, no "LOW POWER").
##   BIG ONE   on: one object at a time, bigger and centred (next object).
##   CHEW      on: the saw eats parts bit by bit (v13). off: parts break whole.
## Saved, so a choice sticks between runs.

const KEYS := ["free", "big", "chew"]
const LABELS := ["FREE CUT", "BIG ONE", "CHEW"]
const CHIP := Vector2(176.0, 54.0)
const TOP := 400.0
const GAP := 70.0

var _box: Control


static func on(key: String) -> bool:
	var t = Save.data.get("test", {})
	return bool(t.get(key, true)) if t is Dictionary else true


static func flip(key: String) -> void:
	var t: Dictionary = Save.data.get("test", {}).duplicate()
	t[key] = not on(key)
	Save.data["test"] = t
	Save.mark_dirty()
	EventBus.banner_requested.emit("%s %s" % [LABELS[KEYS.find(key)], "ON" if t[key] else "OFF"],
		_explain(key, t[key]), ThemePalette.COBALT)


## BIG ONE: largest scale (up to max_k) at which the object fits in w x h.
static func fit_scale(def: Dictionary, max_k: float, w: float, h: float) -> float:
	var box := Rect2()
	for p in def["parts"]:
		for q in p["poly"]:
			box = box.expand(p["pos"] + q)
	return minf(max_k, minf(w / maxf(box.size.x, 1.0), h / maxf(box.size.y, 1.0)))


static func _explain(key: String, value: bool) -> String:
	match key:
		"free": return "CUTTING IS FREE" if value else "EVERY CUT USES POWER"
		"big": return "NEXT OBJECT: ONE BIG ONE" if value else "NEXT OBJECTS: NORMAL SIZE"
		_: return "THE SAW EATS PARTS BIT BY BIT" if value else "PARTS BREAK IN WHOLE CHUNKS"


func _ready() -> void:
	layer = 6
	_box = Control.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.draw.connect(_draw_chips)
	add_child(_box)
	for i in KEYS.size():
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(16.0, TOP + i * GAP)
		b.size = CHIP
		b.modulate.a = 0.0                     # invisible hit area; _draw_chips paints it
		var key: String = KEYS[i]
		b.pressed.connect(func(): flip(key); _box.queue_redraw())
		add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var i: int = [KEY_1, KEY_2, KEY_3].find(event.keycode)
		if i >= 0:
			flip(KEYS[i])
			_box.queue_redraw()


func _draw_chips() -> void:
	var g := Batch.new(_box)
	for i in KEYS.size():
		var r := Rect2(Vector2(16.0, TOP + i * GAP), CHIP)
		var lit := on(KEYS[i])
		g.draw_rect(Rect2(r.position + Vector2(3, 5), r.size), ThemePalette.SHADOW)
		g.draw_rect(r, ThemePalette.MINT if lit else ThemePalette.CREAM)
		g.draw_rect(r, ThemePalette.INK, false, 3.0)
		g.draw_circle(r.position + Vector2(28.0, CHIP.y * 0.5), 11.0, ThemePalette.TEAL if lit else ThemePalette.STONE)
		g.draw_string(ThemePalette.display_font, r.position + Vector2(48.0, 39.0), LABELS[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 23, ThemePalette.INK)
	g.draw_string(ThemePalette.mono_font, Vector2(18.0, TOP - 12.0), "TEST SWITCHES",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ThemePalette.INK_SOFT)
	g.flush()
