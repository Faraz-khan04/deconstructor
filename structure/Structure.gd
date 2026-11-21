class_name Structure
extends Node2D
## A real-world object made of cuttable parts: flies in, bobs, sways (round ones spin).
## Weak points glow: cut one and everything it holds falls off ("CLEAN CUT!").
## Bosses: shell locked until the screws are out. Golden parts: locked until loose.
## `power_budget`: power a careful player needs for it (Jobs). Batteries: Hazard.gd.

signal cleared(structure: Structure)        # every part gone (shredded)
signal stripped(structure: Structure)       # nothing left attached: object done
signal breaking(structure: Structure)       # mostly apart: bring in the next

const NEIGHBOR_GROW := 4.0
const BREAKING_AT := 0.4
const CLEAN_CUT_MIN := 3

var gadget: String = ""
var display_name: String = ""
var is_boss: bool = false
var par_cuts: int = 1; var power_budget: float = 10.0
var has_gold: bool = false

var _blocks: Array = []                # index -> Block (or null once gone)
var _neighbors: Array = []
var _anchors := PackedInt32Array()
var _alive: int = 0
var _screws_left: int = 0
var _spinner: bool = false
var _t: float = 0.0
var _phase: float = 0.0
var _angle: float = 0.0
var _spin: float = 0.0
var _tag_y: float = 200.0
var _tag_alpha: float = 0.0
var _active: bool = false
var _broke: bool = false
var _done: bool = false; var _jolt: float = 0.0
var fly_in: bool = true          # Thrown (Rush) objects skip the fly-in
var crumble_at: float = 0.25     # this few parts left holding = the rest falls


## def: from ObjectLibrary.build(). target: resting position. k: scale.
func build(def: Dictionary, target: Vector2, k: float, level: int, boss: bool, gold_chance: float) -> void:
	gadget = def["name"]
	is_boss = boss
	display_name = ObjectLibrary.DISPLAY.get(gadget, gadget.to_upper())
	_spinner = def["spin"]
	_spin = randf_range(0.35, 0.6) * (1.0 if randf() < 0.5 else -1.0)
	_phase = randf() * TAU
	var parts: Array = def["parts"]
	ObjectLibrary.add_golden(parts, gadget, gold_chance)
	var hp_k := pow(1.055, level - 1) * (1.5 if boss else 1.0)
	var value_k := Economy.level_mult() * (2.0 if boss else 1.0)   # later levels pay more
	var polys: Array = []; var inlays: Array = []; var max_y := 0.0
	for i in parts.size():
		var d: Dictionary = parts[i].duplicate()
		var poly := PackedVector2Array()
		for q in d["poly"]:
			poly.append(q * k)
		d["poly"] = poly
		d["mat"] = Materials.for_part(gadget, d, boss)
		d["hp"] = float(d["hp"]) * hp_k * Materials.HP[d["mat"]]
		d["value"] = maxi(1, int(round(int(d["value"]) * value_k)))
		var pos: Vector2 = d["pos"] * k
		var b := Block.new()
		b.setup(i, d)
		b.rest_pos = pos
		b.locked_look = b.armor
		add_child(b)
		b.destroyed.connect(_on_block_destroyed)
		_blocks.append(b)
		if d["anchor"]: _anchors.append(i)
		_screws_left += int(b.screw); has_gold = has_gold or b.golden
		var wp := PackedVector2Array()
		for q in poly:
			wp.append(q + pos)
			max_y = maxf(max_y, q.y + pos.y)
		polys.append(wp)
		inlays.append(d["inlay"])
	Depth.sort(self, _blocks)
	_neighbors = PartGraph.single_host(ShapeUtil.neighbors(polys, inlays, NEIGHBOR_GROW), inlays, polys)
	if _anchors.is_empty(): _anchors.append(0)
	_alive = parts.size(); _tag_y = max_y + 56.0
	_plan(); _refresh_weak()

	# Fly in from a random side, settle with a springy overshoot (Thrown: no).
	var from := [Vector2(-900, 0), Vector2(900, 0), Vector2(0, -1300)].pick_random() as Vector2
	global_position = target + (from if fly_in else Vector2.ZERO)
	_angle = randf_range(-0.8, 0.8)
	_active = true
	var t := create_tween().set_parallel(true)
	if fly_in: t.tween_property(self, "global_position", target, 0.9) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_tag_alpha", 1.0, 0.4).set_delay(0.6)
	_place_blocks()


func is_locked(b: Block) -> bool:
	return (b.armor and _screws_left > 0) or (b.golden and b.state == Block.State.ATTACHED)


func jolt() -> void:   # parts call this while being sawed: a quick judder
	_jolt = minf(1.0, _jolt + 0.5)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_jolt = maxf(0.0, _jolt - delta * 6.0)
	if _spinner:
		_angle += _spin * delta
	else:
		_angle = lerpf(_angle, 0.09 * sin(_t * 0.55 + _phase), 1.0 - exp(-3.0 * delta))
	_place_blocks()


func _process(_delta: float) -> void:
	if _tag_alpha > 0.01: queue_redraw()


func _place_blocks() -> void:
	var bob := Vector2(sin(_t * 0.7 + _phase) * 14.0, sin(_t * 1.1 + _phase * 1.7) * 10.0)
	var shake := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 6.0 * _jolt
	var center := global_position + bob + shake
	for b in _blocks:
		if b != null and b.state == Block.State.ATTACHED:
			var xf := Transform2D(_angle, center + b.rest_pos.rotated(_angle))
			b.global_transform = xf
			PhysicsServer2D.body_set_state(b.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, xf)


func _on_block_destroyed(b: Block, _shattered: bool) -> void:
	if b.index >= 0 and b.index < _blocks.size() and _blocks[b.index] == b:
		_blocks[b.index] = null
	_alive -= 1
	if b.screw:
		_screws_left -= 1
		if _screws_left == 0:
			EventBus.popup_requested.emit("SHELL OPEN!", global_position, ThemePalette.TEAL, 1.2)
			EventBus.impact.emit(global_position, 0.7)
			for o in _blocks:
				if o != null and o.armor:
					o.locked_look = false
	if b.hazard: Hazard.on_destroyed(self, b)
	if b.golden:
		if b.was_chewed: EventBus.golden_missed.emit(b.global_position)
		else: EventBus.golden_found.emit(gadget, b.golden_slot, b.global_position)
	_update_connectivity(b.global_position)
	if _alive <= 0 and _active:
		_active = false
		var t := create_tween()
		t.tween_property(self, "_tag_alpha", 0.0, 0.3)
		cleared.emit(self)
		t.tween_callback(queue_free)


## Flood-fill from the anchors; unreached parts fall (all of them when almost gone).
func _update_connectivity(cut_at: Vector2) -> void:
	var held := PartGraph.reach(_neighbors, _anchors, _alive_mask())
	var crumble := _screws_left == 0 and held.size() <= maxi(2, int(_blocks.size() * crumble_at))
	if not _broke and (crumble or held.size() <= int(_blocks.size() * BREAKING_AT)):
		_broke = true
		breaking.emit(self)
	var fell := 0
	for i in _blocks.size():
		if _is_attached(i) and (crumble or not held.has(i)):
			var b: Block = _blocks[i]
			var r := b.global_position - global_position
			var fling := r.normalized() * randf_range(60.0, 200.0) + Vector2(0.0, -140.0)
			if _spinner:
				fling += Vector2(-r.y, r.x) * _spin
			b.set_loose(fling)
			fell += 1
	if fell >= CLEAN_CUT_MIN:
		EventBus.clean_cut.emit(cut_at, fell, float(fell) / _blocks.size())
	if not _done and (crumble or held.is_empty()):
		_done = true
		stripped.emit(self)
	elif not _done:
		_refresh_weak()


## Weak points + par/time live in WeakPoints.gd (keeps this file short).
func _plan() -> void: WeakPoints.plan(self)
func _refresh_weak() -> void: WeakPoints.refresh(self)
func _alive_mask() -> PackedByteArray: return WeakPoints.alive_mask(self)


func _is_attached(i: int) -> bool:
	var b = _blocks[i]
	return b != null and b.state == Block.State.ATTACHED


func _draw() -> void:
	if _tag_alpha <= 0.01:
		return
	var label := display_name + ("  ·  CUT THE SCREWS FIRST" if _screws_left > 0 else "")
	draw_string(ThemePalette.mono_font, Vector2(-400.0, _tag_y), label, HORIZONTAL_ALIGNMENT_CENTER,
		800.0, 22, ThemePalette.with_alpha(ThemePalette.INK_SOFT, _tag_alpha))
