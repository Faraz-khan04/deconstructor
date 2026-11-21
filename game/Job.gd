class_name Job
extends Node
## Every level is a JOB: a precision puzzle, not a race. You get a POWER
## budget; every bit of material the saw cuts spends it (tough stuff costs
## more). Cutting a weak point drops whole sections for the price of one
## part, and a CLEAN CUT refunds a little. Scribbling burns power.
## Out of power with things still attached = job failed.
## Stars: 1. smash everything  2. free the golden part  3. finish with 35%+ power.
## Each object brings its own power (Structure.power_budget). POWER upgrade
## stretches it; FRENZY: cutting is free.

enum Phase { IDLE, RUNNING, WON, LOST }

const PAY := 250.0              # x level boost x MONEY x stars
const GOLD_WAIT := 3.0          # after the last object, how long a falling gold may take
const STAR_POWER := 0.35        # fraction of the budget left for the 3rd star
const REFUND_PER_PART := 0.02   # clean cut: this share of one object's budget per part dropped
const REFUND_MAX := 0.2         # ...at most this much per clean cut

static var cur: Job = null

var phase: Phase = Phase.IDLE
var level: int = 1
var power: float = 0.0          # left, in "hp at starting POWER"
var capacity: float = 0.0       # everything this job has brought so far
var total: int = 0
var done: int = 0
var gold: int = 0               # 0 = still to free, 1 = freed, -1 = lost
var stars: int = 0
var pay: int = 0
var _wait: float = 0.0
var _last_obj: float = 1.0
var _warned: bool = false


func _ready() -> void:
	cur = self
	EventBus.golden_found.connect(_on_gold_found)
	EventBus.golden_missed.connect(_on_gold_missed)
	EventBus.clean_cut.connect(_on_clean_cut)


func _exit_tree() -> void:
	if cur == self:
		cur = null


func _on_gold_found(_g: String, _s: int, _p: Vector2) -> void:
	if gold == 0:
		gold = 1


func _on_gold_missed(_p: Vector2) -> void:
	if gold == 0:
		gold = -1


func _on_clean_cut(_p: Vector2, count: int, _share: float) -> void:
	if phase == Phase.RUNNING:
		var back := _last_obj * minf(REFUND_PER_PART * count, REFUND_MAX)
		power = minf(capacity, power + back)
		EventBus.time_added.emit(back / maxf(capacity, 0.01) * 100.0)   # "+12%" by the bar


func begin(lvl: int, objects: int) -> void:
	phase = Phase.RUNNING
	level = lvl
	total = objects
	power = 0.0
	capacity = 0.0
	done = 0
	gold = 0
	stars = 0
	_warned = false


func add_object(s: Structure) -> void:
	if phase != Phase.RUNNING:
		return
	var extra := s.power_budget * (0.5 if level <= 2 else 0.0)     # learning jobs: extra power
	_last_obj = s.power_budget + extra
	power += _last_obj
	capacity += _last_obj


## Called by parts as the saw (or a tool) eats into them.
func spend(hp: float) -> void:
	if phase != Phase.RUNNING or Frenzy.active or capacity <= 0.0 or TestSwitches.on("free"):
		return
	power = maxf(0.0, power - hp / Economy.damage_mult())
	if not _warned and power < capacity * 0.2:
		_warned = true
		EventBus.banner_requested.emit("LOW POWER!", "AIM FOR THE RED DASHED PARTS", ThemePalette.RED)
	if power <= 0.0:
		phase = Phase.LOST
		EventBus.title_card_requested.emit("OUT OF POWER!", "SCRIBBLING BURNS POWER · TRY AGAIN",
			ThemePalette.RED)
		get_tree().create_timer(1.6).timeout.connect(func(): EventBus.job_finished.emit(false, 0))


func can_cut() -> bool:
	return phase != Phase.RUNNING or power > 0.0 or capacity <= 0.0


func fraction() -> float:
	return power / capacity if capacity > 0.0 else 1.0


func object_done() -> void:
	if phase != Phase.RUNNING:
		return
	done += 1
	if done >= total:
		phase = Phase.WON
		_wait = 0.0
		stars = 0


func running() -> bool:
	return phase == Phase.RUNNING


func _process(delta: float) -> void:
	if phase == Phase.WON and stars == 0:
		_wait += delta                       # let a falling gold part land or get caught
		if gold != 0 or _wait >= GOLD_WAIT:
			stars = 1 + (1 if gold == 1 else 0) + (1 if fraction() >= STAR_POWER else 0)
			pay = int(round(PAY * stars * Economy.level_mult() * Economy.value_mult()))
			Save.set_stars(level, stars)
			get_tree().create_timer(0.6).timeout.connect(func(): EventBus.job_finished.emit(true, stars))
