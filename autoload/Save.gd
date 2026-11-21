extends Node
## Saves progress to the phone so players pick up where they left off:
## cash, upgrades, level, which gadgets they've smashed, golden parts found,
## unlocked tools and the tool in use. Plain JSON in user://save.json.
## Saves every few seconds when something changed, and when the app is
## closed or sent to the background. Desktop debug: R = wipe progress.

const PATH := "user://save.json"
const GOLDEN_SLOTS := 3          # golden parts to find per gadget

const VERSION := 3                # older saves (old economy) start fresh once
const DEFAULTS := {
	"version": VERSION,
	"cash": 0,
	"upgrades": {},              # upgrade id -> level
	"level": 1,
	"smashed": {},               # gadget name -> times smashed
	"golden": {},                # gadget name -> [slot, slot...]
	"tools": ["saw"],
	"tool": "saw",
	"gold_meter": 0,             # golden parts toward the next FRENZY
	"catalog_done": false,       # all 12 found: cash x2 forever
	"stars": {},                 # level (as text) -> best stars 0..3
	"test": {"free": true, "big": true, "chew": true},   # v14 test switches
}

var data: Dictionary = DEFAULTS.duplicate(true)

var _dirty: bool = false
var _timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func _process(delta: float) -> void:
	_timer += delta
	if _dirty and _timer > 5.0:
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_R:
		reset()


## Start over from nothing (debug).
func reset() -> void:
	data = DEFAULTS.duplicate(true)
	save_game()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Economy.reload()
	get_tree().reload_current_scene()


func best_stars(level: int) -> int:
	return int(data["stars"].get(str(level), 0))


func set_stars(level: int, stars: int) -> void:
	if stars > best_stars(level):
		data["stars"][str(level)] = stars
		mark_dirty()


func total_stars() -> int:
	var n := 0
	for k in data["stars"]:
		n += int(data["stars"][k])
	return n


func mark_dirty() -> void:
	_dirty = true


func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
	_dirty = false
	_timer = 0.0


func load_game() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and int(parsed.get("version", 0)) >= VERSION:   # old economy: fresh start
		for key in data.keys():
			if parsed.has(key):
				data[key] = parsed[key]


# --- Catalog -----------------------------------------------------------------

## Returns true the first time this gadget is smashed (new in the catalog).
func mark_smashed(gadget: String) -> bool:
	var s: Dictionary = data["smashed"]
	var first := int(s.get(gadget, 0)) == 0
	s[gadget] = int(s.get(gadget, 0)) + 1
	mark_dirty()
	return first


func is_smashed(gadget: String) -> bool:
	return int(data["smashed"].get(gadget, 0)) > 0


func smashed_count() -> int:
	var n := 0
	for g in ObjectLibrary.ALL:
		if is_smashed(g):
			n += 1
	return n


func golden_found(gadget: String) -> Array:
	return data["golden"].get(gadget, [])


func has_golden(gadget: String, slot: int) -> bool:
	for s in golden_found(gadget):
		if int(s) == slot:
			return true
	return false


## First golden slot still missing for this gadget, or -1 if all found.
func next_golden_slot(gadget: String) -> int:
	for slot in GOLDEN_SLOTS:
		if not has_golden(gadget, slot):
			return slot
	return -1


func add_golden(gadget: String, slot: int) -> void:
	if has_golden(gadget, slot):
		return
	var list: Array = golden_found(gadget).duplicate()
	list.append(slot)
	data["golden"][gadget] = list
	mark_dirty()


# --- Tools -------------------------------------------------------------------

func has_tool(id: String) -> bool:
	return id in data["tools"]


func unlock_tool(id: String) -> void:
	if not has_tool(id):
		(data["tools"] as Array).append(id)
		mark_dirty()


func set_tool(id: String) -> void:
	if has_tool(id):
		data["tool"] = id
		mark_dirty()
		EventBus.tool_changed.emit(id)
