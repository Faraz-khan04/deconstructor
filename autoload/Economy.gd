extends Node
## Cash + upgrades. Money arrives via EventBus.score_added and is spent on
## upgrades; everything else listens to EventBus.cash_changed and
## EventBus.upgrades_changed. Both are kept in the save file.
##
## Balance in one place:
##  - Every level pays more: part prices x LEVEL_GROWTH per level.
##  - Upgrade prices grow gently (x1.18-1.4 per buy) so the next one is always
##    close; new upgrades unlock at levels 4, 7, 10 and 13 to keep things fresh.

const LEVEL_GROWTH := 1.15
const UPGRADES := {
	"rpm": {"label": "POWER", "base": 40, "growth": 1.18, "max": 80, "unlock": 1},
	"value": {"label": "MONEY", "base": 60, "growth": 1.2, "max": 100, "unlock": 1},
	"size": {"label": "SIZE", "base": 100, "growth": 1.4, "max": 12, "unlock": 1},
	"cool": {"label": "BATTERY", "base": 400, "growth": 1.3, "max": 15, "unlock": 4},
	"gates": {"label": "BUCKET", "base": 2500, "growth": 2.2, "max": 6, "unlock": 7},
	"pegs": {"label": "GOLD PEGS", "base": 6000, "growth": 1.55, "max": 14, "unlock": 10},
	"orbit": {"label": "MINI SAWS", "base": 25000, "growth": 4.0, "max": 3, "unlock": 13},
}
const ORDER := ["rpm", "value", "size", "cool", "gates", "pegs", "orbit"]
const CORE := ["rpm", "value"]           # always on the bar
const EXTRA_SLOTS := 2                   # + the two cheapest of the rest

var cash: int = 0
var levels := {}


func _ready() -> void:
	reload()
	EventBus.score_added.connect(earn)
	EventBus.level_started.connect(func(_l: int): EventBus.upgrades_changed.emit())
	EventBus.frenzy_changed.connect(func(_on: bool): EventBus.upgrades_changed.emit())


## Read cash + upgrade levels from the save (also used after a reset).
func reload() -> void:
	cash = int(Save.data["cash"])
	for id in ORDER:
		levels[id] = int(Save.data["upgrades"].get(id, 0))
	_announce.call_deferred()


func _announce() -> void:
	EventBus.cash_changed.emit(cash, 0)
	EventBus.upgrades_changed.emit()


func _store() -> void:
	Save.data["cash"] = cash
	Save.data["upgrades"] = levels.duplicate()
	Save.mark_dirty()


func earn(amount: int) -> void:
	if amount == 0:
		return
	cash += amount
	_store()
	EventBus.cash_changed.emit(cash, amount)


func cost(id: String) -> int:
	var u: Dictionary = UPGRADES[id]
	return int(round(float(u["base"]) * pow(float(u["growth"]), levels[id])))


func is_unlocked(id: String) -> bool:
	return int(Save.data["level"]) >= int(UPGRADES[id]["unlock"])


func is_maxed(id: String) -> bool:
	return levels[id] >= int(UPGRADES[id]["max"])


func can_buy(id: String) -> bool:
	return is_unlocked(id) and not is_maxed(id) and cash >= cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	var price := cost(id)
	cash -= price
	levels[id] += 1
	_store()
	EventBus.cash_changed.emit(cash, -price)
	EventBus.upgrades_changed.emit()
	return true


## The buttons on the bar: POWER + MONEY, then the two cheapest other
## upgrades that are unlocked and not maxed (maxed ones drop off the bar).
func shown() -> Array:
	var extra: Array = []
	for id in ORDER:
		if not id in CORE and is_unlocked(id) and not is_maxed(id):
			extra.append(id)
	extra.sort_custom(func(a: String, b: String) -> bool: return cost(a) < cost(b))
	extra = extra.slice(0, EXTRA_SLOTS)
	var out: Array = CORE.duplicate()
	for id in ORDER:
		if id in extra:
			out.append(id)
	return out


## Plain words for what an upgrade does at its current level.
func effect_text(id: String) -> String:
	var l: int = levels[id]
	match id:
		"rpm": return "CUTS %d%% FASTER" % (12 * l)
		"value":
			var m := pow(1.12, l)
			return "EVERYTHING PAYS x%s" % (("%.2f" % m) if m < 100.0 else NumFmt.short(m))
		"size": return "SAW %d%% BIGGER" % (6 * l)
		"cool": return "BATTERY LASTS %d%% LONGER" % int(round((1.0 / drain_mult() - 1.0) * 100.0))
		"gates": return "BUCKET PAYS x%d" % (3 + l)
		"pegs": return "%d GOLD PEGS (x2 PIECES)" % l
		"orbit": return "%d MINI SAW%s CIRCLE YOURS" % [l, "S" if l > 1 else ""]
	return ""


# --- Effects -----------------------------------------------------------------

## Everything in level N pays LEVEL_GROWTH^(N-1) times what level 1 pays.
func level_mult() -> float:
	return pow(LEVEL_GROWTH, maxi(0, int(Save.data["level"]) - 1))


func damage_mult() -> float:
	return 1.0 + 0.12 * levels["rpm"]


func size_mult() -> float:
	return (1.0 + 0.06 * levels["size"]) * (1.25 if Frenzy.active else 1.0)


## MONEY upgrade (x1.12 per level, compounding), FRENZY x2, full catalog x2.
func value_mult() -> float:
	var m := pow(1.12, levels["value"])
	if Frenzy.active:
		m *= 2.0
	if bool(Save.data.get("catalog_done", false)):
		m *= 2.0
	return m


func drain_mult() -> float:
	return pow(0.93, levels["cool"])


func refill_mult() -> float:
	return 1.0 + 0.07 * levels["cool"]


func gate_bonus() -> int:
	return levels["gates"]


func gold_pegs() -> int:
	return levels["pegs"]


func mini_saws() -> int:
	return levels["orbit"]
