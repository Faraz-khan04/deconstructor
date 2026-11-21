extends Node
## Rewards and unlocks, so the game loop stays simple:
##  - Golden parts: slow-motion zoom, cash, catalog progress, +1 on the gold
##    meter (top-right chip). 3 gold = FRENZY.
##  - Catalog: new gadgets get a banner, "1 LEFT!" when one is missing, and
##    finding all 12 doubles all cash forever.
##  - New tools and upgrades unlocking as levels are reached.

const GOLDEN_BONUS := 100.0
const METER_FULL := 3


func _ready() -> void:
	EventBus.golden_found.connect(_on_golden_found)
	EventBus.golden_missed.connect(_on_golden_missed)
	EventBus.gadget_smashed.connect(_on_gadget_smashed)
	EventBus.level_started.connect(_on_level_started)


func _on_golden_found(gadget: String, slot: int, at: Vector2) -> void:
	var new_slot := slot >= 0 and not Save.has_golden(gadget, slot)
	if new_slot:
		Save.add_golden(gadget, slot)
	var bonus := int(round(GOLDEN_BONUS * Economy.level_mult() * Economy.value_mult()))
	EventBus.score_added.emit(bonus)
	JuiceManager.slowmo(at, 450, 0.3)
	EventBus.impact.emit(at, 0.8)
	EventBus.splash.emit(at, Vector2.ZERO, 1.0, ThemePalette.BUTTER)
	EventBus.popup_requested.emit("+" + NumFmt.money(bonus), at + Vector2(0.0, -80.0),
		ThemePalette.TANGERINE, 0.9)
	var sub := "%s  %d/%d IN THE CATALOG" % [ObjectLibrary.DISPLAY.get(gadget, gadget.to_upper()),
		Save.golden_found(gadget).size(), Save.GOLDEN_SLOTS] if new_slot else "BONUS GOLD"
	EventBus.banner_requested.emit("GOLDEN PART!", sub, ThemePalette.BUTTER)

	var meter := int(Save.data.get("gold_meter", 0)) + 1
	if meter >= METER_FULL:
		meter = 0
		EventBus.frenzy_changed.emit(true)
	Save.data["gold_meter"] = meter
	Save.mark_dirty()
	EventBus.gold_meter_changed.emit(METER_FULL if meter == 0 else meter)
	if meter == 0:                                  # show the full meter, then empty it
		get_tree().create_timer(1.2).timeout.connect(func(): EventBus.gold_meter_changed.emit(0))


func _on_golden_missed(at: Vector2) -> void:
	EventBus.popup_requested.emit("MISSED THE GOLD!", Vector2(at.x, at.y - 160.0),
		ThemePalette.INK_SOFT, 0.8)


func _on_gadget_smashed(gadget: String, first_time: bool) -> void:
	if not first_time:
		return
	var found := Save.smashed_count()
	var total := ObjectLibrary.ALL.size()
	if found >= total and not bool(Save.data.get("catalog_done", false)):
		Save.data["catalog_done"] = true
		Save.mark_dirty()
		EventBus.title_card_requested.emit("CATALOG DONE!", "ALL %d FOUND · ALL CASH x2 FOREVER" % ObjectLibrary.ALL.size(),
			ThemePalette.BUTTER)
		EventBus.impact.emit(Vector2(540.0, 900.0), 1.0)
		return
	var sub := "1 LEFT TO FIND!" if total - found == 1 else "%d/%d IN THE CATALOG" % [found, total]
	EventBus.banner_requested.emit("NEW: %s" % ObjectLibrary.DISPLAY.get(gadget, gadget.to_upper()),
		sub, ThemePalette.COBALT)


func _on_level_started(level: int) -> void:
	for id in ToolKit.ORDER:
		var unlock: int = ToolKit.TOOLS[id]["unlock"]
		if level >= unlock and not Save.has_tool(id):
			Save.unlock_tool(id)
			EventBus.banner_requested.emit("NEW TOOL: %s" % ToolKit.TOOLS[id]["name"],
				"OPEN THE CATALOG TO USE IT", ThemePalette.COBALT)
	for id in Economy.ORDER:
		if int(Economy.UPGRADES[id]["unlock"]) == level and level > 1:
			EventBus.banner_requested.emit("NEW UPGRADE: %s" % Economy.UPGRADES[id]["label"],
				_upgrade_pitch(id), ThemePalette.TEAL)
	var left := ObjectLibrary.ALL.size() - Save.smashed_count()
	if left == 1:
		EventBus.banner_requested.emit("1 LEFT!", "ONE GADGET MISSING FROM YOUR CATALOG",
			ThemePalette.TANGERINE)


func _upgrade_pitch(id: String) -> String:
	match id:
		"cool": return "YOUR BATTERY LASTS LONGER"
		"gates": return "THE BUCKET PAYS MORE PER PIECE"
		"pegs": return "GOLD PEGS DOUBLE ANY PIECE THAT HITS THEM"
		"orbit": return "LITTLE SAWS CIRCLE YOUR SAW"
	return ""
