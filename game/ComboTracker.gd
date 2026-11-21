extends Node
## Feedback for breaking things, kept calm so the big moments stand out:
##  - A part breaking: a crunch (sound + small shake). Fruit splats juice.
##    No price tag per part: the coins flying to your cash already show it.
##  - A CLEAN CUT (one cut drops a whole section): freeze, shake, paint burst,
##    "CLEAN CUT! x12" and a bonus. A huge one goes slow-motion for a moment.
##  - Combos: the badge counts; chains of 15+ pay a bonus in the banner strip.

const COMBO_WINDOW := 1.1     # seconds between breaks to keep a combo alive
const COMBO_BONUS_MIN := 15

var _combo: int = 0
var _combo_timer: float = 0.0


func _ready() -> void:
	EventBus.block_shattered.connect(_on_block_shattered)
	EventBus.clean_cut.connect(_on_clean_cut)


func _process(delta: float) -> void:
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_end_combo()


func _end_combo() -> void:
	if _combo >= COMBO_BONUS_MIN:
		var bonus := int(round(pow(_combo, 1.2) * 3.0 * Economy.level_mult() * Economy.value_mult()))
		EventBus.banner_requested.emit("COMBO x%d!" % _combo, "BONUS +" + NumFmt.money(bonus),
			ThemePalette.TANGERINE if _combo < 20 else ThemePalette.RED)
		EventBus.score_added.emit(bonus)
	_combo = 0
	EventBus.combo_changed.emit(0)


## `value` already includes the level boost (set when the object was built).
func _on_block_shattered(pos: Vector2, color: Color, value: int, vel: Vector2, mat: int) -> void:
	EventBus.score_added.emit(int(round(value * Economy.value_mult())))
	if pos.y >= PinField.BOARD_TOP:          # eaten by the shredder: no fuss
		return
	_combo += 1
	_combo_timer = COMBO_WINDOW
	EventBus.combo_changed.emit(_combo)
	EventBus.impact.emit(pos, 0.45 + minf(_combo * 0.03, 0.3))
	if Materials.PAINT[mat] > 0.0:
		EventBus.splash.emit(pos, vel, Materials.PAINT[mat], color)


func _on_clean_cut(pos: Vector2, count: int, share: float) -> void:
	var bonus := int(round(count * 6.0 * Economy.level_mult() * Economy.value_mult()))
	EventBus.score_added.emit(bonus)
	EventBus.impact.emit(pos, 1.0)
	EventBus.splash.emit(pos, Vector2.from_angle(randf() * TAU) * 500.0, 0.35 + share * 0.4,
		Color(0, 0, 0, 0))
	# Big words only for big moments: small drops just thud and pay.
	if share >= 0.3:
		var title := "HUGE CUT!" if share >= 0.55 else "CLEAN CUT!"
		EventBus.popup_requested.emit("%s x%d" % [title, count], pos, ThemePalette.RED, 1.0)
	if share >= 0.5:
		JuiceManager.slowmo(pos, 300, 0.45)
	Sfx.play("thud", 1.0 - share * 0.3)
	Sfx.play("whoosh")
