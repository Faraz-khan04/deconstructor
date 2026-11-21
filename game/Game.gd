extends Node2D
## Game loop. Each level is a JOB (see Job.gd): a few objects arrive 1-2 at
## a time against the clock; one of them hides the golden part. As soon as the
## current objects start falling apart the next ones fly in (no empty screen).
## The job ends on the result screen: NEXT JOB or RETRY. Every 5th: a boss.
## Desktop debug keys: C = clear paint, N = next group now, R = reset save, 1/2/3 = test switches.

const SPAWN_GAP := 0.25        # next group follows the breaking one this fast
const BOSS_WARN := 1.0
const FIRST_SPAWN := 0.55      # objects fly in right behind the title card
const MID_WIPE_SPLASHES := 60  # mid-job squeegee once the page is this messy
const BIG_K := 1.4             # test switch BIG ONE: max scale, centre height, fit box, boss
const BIG_Y := 790.0
const BIG_W := 720.0; const BIG_H := 780.0; const BIG_BOSS := 1.15

@onready var _things: Node2D = $Things
@onready var _paint = $PaintLayer   # untyped: calls PaintLayer.splash_count()
@onready var _job: Job = $Job

var level: int = 1

var _total: int = 0
var _spawned: int = 0
var _gold_at: int = 0          # which object of the job carries the gold
var _pending := {}             # instance id -> true: current group, still whole
var _recent: Array = []
var _boss_level: bool = false
var _spawn_queued: bool = false
var _wiping: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(ThemePalette.PAPER)
	level = maxi(1, int(Save.data["level"]))
	EventBus.wipe_finished.connect(func(): _wiping = false)
	EventBus.job_finished.connect(_on_job_finished)
	EventBus.job_next.connect(_on_job_next)
	add_child(TestSwitches.new())
	_start_level.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C: EventBus.paint_clear_requested.emit()
			KEY_N: _spawn_group()


## Jobs grow slowly: 1 object to learn on, then 2-4 (+ the boss every 5th).
func _start_level() -> void:
	_boss_level = level % 5 == 0
	_total = (1 if level == 1 else clampi(1 + int(level / 3.0) + 1, 2, 4)) + (1 if _boss_level else 0)
	Save.data["level"] = level
	Save.save_game()
	_spawned = 0
	_gold_at = _total - 1 if _boss_level else randi() % _total
	_pending.clear()
	_job.begin(level, _total)
	EventBus.level_started.emit(level)
	EventBus.level_progress.emit(0, _total)
	var sub := "SAVE POWER · FREE THE GOLD · DON'T CUT BATTERIES" if level >= 3 \
		else "CUT THE RED DASHED PARTS · EVERY CUT USES POWER"
	if TestSwitches.on("free"):
		sub = "CUT ANYTHING · RED DASHED PARTS DROP BIG CHUNKS"
	EventBus.title_card_requested.emit("LEVEL %d" % level, sub,
		ThemePalette.RED if _boss_level else ThemePalette.COBALT)
	_spawn_queued = true
	get_tree().create_timer(FIRST_SPAWN).timeout.connect(_spawn_group)


## Brings in the next 1-2 objects of this job.
func _spawn_group() -> void:
	_spawn_queued = false
	var left := _total - _spawned
	if left <= 0 or not _job.running():
		return
	var w := get_viewport_rect().size.x
	if _boss_level and left == 1:
		var boss: String = ObjectLibrary.BOSSES.pick_random()
		for b in ObjectLibrary.BOSSES:           # one you haven't smashed yet first
			if not Save.is_smashed(b):
				boss = b
		_add(boss, Vector2(w * 0.5, 820.0), BIG_BOSS if TestSwitches.on("big") else 1.0, true)
		EventBus.impact.emit(Vector2(w * 0.5, 820.0), 0.9)
		return
	var normal_left := left - (1 if _boss_level else 0)
	if TestSwitches.on("big"):              # test: one big object, centre stage
		_add(_pick(1)[0], Vector2(w * 0.5, BIG_Y), -1.0, false)
		return
	var count := 1 if level < 4 or normal_left == 1 or randf() < 0.4 else 2
	var slots: Array = []
	var k := 1.0
	if count == 1:
		slots.append(Vector2(randf_range(w * 0.4, w * 0.6), randf_range(690.0, 820.0)))
	else:
		k = 0.72
		var top := Vector2(randf_range(w * 0.36, w * 0.64), randf_range(470.0, 520.0))
		var bottom := Vector2(randf_range(w * 0.36, w * 0.64), randf_range(950.0, 1010.0))
		slots = [top, bottom] if randf() < 0.5 else [bottom, top]
	var names := _pick(count)
	for i in count:
		_add(names[i], slots[i], k, false)


## Random objects, nudged toward ones still missing from the catalog.
func _pick(count: int) -> Array:
	var names := ObjectLibrary.pick_names(count, _recent)
	var missing: Array = []
	for n in ObjectLibrary.NAMES:
		if not Save.is_smashed(n) and not n in names:
			missing.append(n)
	if not missing.is_empty() and randf() < 0.5:
		names[0] = missing.pick_random()
	_recent = names
	return names


func _add(gadget: String, at: Vector2, k: float, boss: bool) -> void:
	var s := Structure.new()
	_things.add_child(s)
	s.cleared.connect(_on_object_breaking)
	s.breaking.connect(_on_object_breaking)
	s.stripped.connect(_on_object_stripped)
	var def := ObjectLibrary.build(gadget)
	if k < 0.0:
		k = TestSwitches.fit_scale(def, BIG_K, BIG_W, BIG_H)   # BIG ONE: as big as fits
	if level >= 3 and not boss and randf() < 0.5:
		Hazard.add(def["parts"])                 # a lithium battery to cut around
	s.build(def, at, k, level, boss, 1.0 if _spawned == _gold_at else 0.0)
	_pending[s.get_instance_id()] = true
	_spawned += 1
	_job.add_object(s)


func _on_object_breaking(s: Structure) -> void:
	if _pending.erase(s.get_instance_id()) and _pending.is_empty():
		_queue_next()


func _queue_next() -> void:
	if _spawn_queued or _spawned >= _total or not _job.running():
		return
	_spawn_queued = true
	var boss_next := _boss_level and _total - _spawned == 1
	if boss_next:
		EventBus.title_card_requested.emit("BIG ONE COMING!", "CUT THE SCREWS, THEN THE SHELL",
			ThemePalette.RED)
	get_tree().create_timer(BOSS_WARN if boss_next else SPAWN_GAP).timeout.connect(_spawn_group)


## Nothing left attached: the object is smashed.
func _on_object_stripped(s: Structure) -> void:
	_on_object_breaking(s)
	if not _job.running():
		return
	var c := s.global_position
	var bonus := int(round(150.0 * (4.0 if s.is_boss else 1.0) * Economy.level_mult()
		* Economy.value_mult()))
	if s.is_boss:
		EventBus.popup_requested.emit("BOSS SMASHED!", c, ThemePalette.COBALT, 1.4)
	EventBus.score_added.emit(bonus)
	EventBus.gadget_smashed.emit(s.gadget, Save.mark_smashed(s.gadget))
	_job.object_done()
	EventBus.level_progress.emit(_job.done, _total)
	if _job.running() and _paint.splash_count() >= MID_WIPE_SPLASHES:
		_wipe()


## Out of time: whatever is left falls apart into the shredder.
func _on_job_finished(won: bool, _stars: int) -> void:
	if won:
		return
	for st in _things.get_children():
		for b in st.get_children():
			if b is Block and b.state == Block.State.ATTACHED:
				b.set_loose(Vector2(randf_range(-150.0, 150.0), -120.0))


func _on_job_next(retry: bool) -> void:
	_wipe()
	for st in _things.get_children():
		st.queue_free()
	if not retry:
		level += 1
	get_tree().create_timer(0.2).timeout.connect(_start_level)


## Squeegee time: every splash on the page is worth a little bonus.
func _wipe() -> void:
	if _wiping:
		return
	_wiping = true
	var bonus := int(round(_paint.splash_count() * 3 * Economy.level_mult() * Economy.value_mult()))
	if bonus > 0:
		EventBus.popup_requested.emit("CLEAN PAGE +" + NumFmt.money(bonus),
			Vector2(get_viewport_rect().size.x * 0.5, 1250.0), ThemePalette.TEAL, 0.8)
		EventBus.score_added.emit(bonus)
	EventBus.wipe_requested.emit()
