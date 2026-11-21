class_name Hazard
## Lithium batteries: a pulsing red-ringed "LI-ION" part hidden in some gadgets
## (Jobs, level 3+). The saw must NOT cut it:
##   - Cut it (or drop it in the bucket) -> it EXPLODES: everything near it
##     shatters (the golden part too, if it's close), and it costs power.
##   - Cut what holds it so it falls into the shredder -> "SAFE!" + a bonus.

const RADIUS := 260.0
const POWER_COST := 0.2         # share of the job's power budget


## Put a battery on one of the object's base parts (prefers non-anchors).
static func add(parts: Array) -> void:
	var spots: Array = []
	for p in parts:
		if not p["inlay"] and not p["anchor"]:
			spots.append(p["pos"])
	if spots.is_empty():
		for p in parts:
			if not p["inlay"]:
				spots.append(p["pos"])
	if spots.is_empty():
		return
	ObjectLibrary.part(parts, ObjectLibrary.rect(84, 46, 10.0), spots.pick_random(), ThemePalette.MINT,
		{"inlay": true, "hazard": true, "hp": 0.8, "value": 0, "detail": ObjectLibrary.Detail.TEXT,
		"text": "LI-ION"})


static func on_destroyed(s: Structure, b: Block) -> void:
	if b.was_chewed:
		var bonus := int(round(60.0 * Economy.level_mult() * Economy.value_mult()))
		EventBus.score_added.emit(bonus)
		EventBus.popup_requested.emit("BATTERY SAFE! +" + NumFmt.money(bonus), b.global_position,
			ThemePalette.TEAL, 0.8)
		return
	explode(s, b.global_position, b.has_meta("caught"))


static func explode(s: Structure, at: Vector2, in_bucket: bool) -> void:
	for o in s._blocks.duplicate():
		if o == null or o.state == Block.State.DEAD:
			continue
		if o.global_position.distance_to(at) <= RADIUS:
			if o.golden:
				o.was_chewed = true               # the gold is lost in the blast
			o.shatter((o.global_position - at).normalized() * 900.0)
	if Job.cur and Job.cur.running():
		Job.cur.spend(Job.cur.capacity * POWER_COST * Economy.damage_mult())
	EventBus.impact.emit(at, 1.0)
	EventBus.shake_requested.emit(1.0)
	EventBus.splash.emit(at, Vector2.ZERO, 1.0, ThemePalette.CHARCOAL)
	EventBus.popup_requested.emit("BATTERY BLEW!", at, ThemePalette.RED, 1.4)
	EventBus.banner_requested.emit("BOOM! -20% POWER", "KEEP BATTERIES OUT OF THE BUCKET" if in_bucket
		else "DON'T CUT THE LI-ION BATTERY · CUT WHAT HOLDS IT", ThemePalette.RED)
	Sfx.play("boom")
	JuiceManager.buzz(250, 1.0)
