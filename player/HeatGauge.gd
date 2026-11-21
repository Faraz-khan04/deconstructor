class_name HeatGauge
extends Node2D
## The saw's battery ring (drawn over the hub). It drains while the saw cuts
## and refills when it isn't cutting (faster with your thumb lifted).
## Empty = OVERHEAT: the saw stalls for a moment, then restarts half charged.
## Cutting where pieces meet hits several at once for the same drain, so
## aiming beats scribbling. Fair by design: no rigged near-misses.
## BATTERY upgrade: drains slower, refills faster. FRENZY: never drains.
## In JOBS the ring shows the job's POWER instead (Job.gd): it never refills,
## and when it's empty the saw stops.

const DRAIN := 0.24          # per second of cutting (~4 s from full to empty)
const REFILL_HELD := 0.3     # per second, thumb down but not cutting
const REFILL_LIFTED := 0.9   # per second, thumb lifted
const STALL_TIME := 1.3

var radius: float = 90.0
var heat: float = 0.0        # 0 = full battery, 1 = empty / overheated

var _stall: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	EventBus.golden_found.connect(func(_g: String, _s: int, _p: Vector2): refill())


func can_cut() -> bool:
	if Job.cur:
		return Job.cur.can_cut()
	return _stall <= 0.0


func tick(delta: float, cutting: bool, held: bool) -> void:
	_t += delta
	if Job.cur:
		heat = 1.0 - Job.cur.fraction()        # the job's power is spent by the parts themselves
		_stall = 0.0 if Job.cur.can_cut() else 1.0   # empty: blink red
		queue_redraw()
		return
	if _stall > 0.0:
		_stall -= delta
		if _stall <= 0.0:
			heat = 0.5
	elif cutting and not Frenzy.active:
		heat += DRAIN * Economy.drain_mult() * delta
		if heat >= 1.0:
			_overheat()
	elif not cutting:
		heat -= (REFILL_HELD if held else REFILL_LIFTED) * Economy.refill_mult() * delta
	heat = clampf(heat, 0.0, 1.0)
	queue_redraw()


## Instant refill (golden parts will use this later).
func refill() -> void:
	heat = 0.0
	_stall = 0.0


func _overheat() -> void:
	heat = 1.0
	_stall = STALL_TIME
	EventBus.popup_requested.emit("TOO HOT! LIFT TO COOL", global_position + Vector2(0.0, -radius - 90.0),
		ThemePalette.RED, 0.7)
	EventBus.impact.emit(global_position, 0.5)
	JuiceManager.buzz(70, 1.0)


func _draw() -> void:
	var g := Batch.new(self)    # v14: one draw call for all of this
	var r := radius * 0.58
	g.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, ThemePalette.CREAM, 12.0, true)     # empty track
	if _stall > 0.0:
		var blink := ThemePalette.RED if int(_t * 10.0) % 2 == 0 else ThemePalette.INK
		g.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, blink, 12.0, true)
		g.flush()
		return
	var charge := 1.0 - heat
	if Frenzy.active:
		g.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, ThemePalette.BUTTER if int(_t * 10.0) % 2 == 0
			else ThemePalette.RED, 12.0, true)
		g.flush()
		return
	var col := ThemePalette.COBALT.lerp(ThemePalette.TANGERINE, smoothstep(0.35, 0.7, heat))
	col = col.lerp(ThemePalette.RED, smoothstep(0.7, 0.95, heat))
	if heat > 0.75 and int(_t * 6.0) % 2 == 0:
		col = col.lightened(0.35)                                   # low-battery blink
	if charge > 0.01:
		g.draw_arc(Vector2.ZERO, r, -PI * 0.5, -PI * 0.5 + TAU * charge, 48, col, 12.0, true)
	g.draw_arc(Vector2.ZERO, r + 6.0, 0.0, TAU, 48, ThemePalette.INK, 2.0, true)
	g.draw_arc(Vector2.ZERO, r - 6.0, 0.0, TAU, 48, ThemePalette.INK, 2.0, true)
	g.flush()
