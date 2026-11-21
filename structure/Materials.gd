class_name Materials
## What a part is made of decides how it cuts, breaks, sounds and splashes.
##   PLASTIC  clacky chips (the default)
##   METAL    tough, showers of sparks, clangs (screws, shells, grills, hubs)
##   GLASS    quick to cut, bursts into many tiny shards, tinkles (screens, lenses)
##   FRUIT    soft, splats juice that paints the page (watermelon, donut)
##   ELECTRO  circuit boards inside the big ones: blue zaps

##   RUBBER   bouncy, squeaks (rubber duck)
##   CERAMIC  bright clinks, shatters into many pieces (piggy bank)

enum { PLASTIC, METAL, GLASS, FRUIT, ELECTRO, RUBBER, CERAMIC }

## Per material: cut toughness, shard count, shard size, paint on break.
const HP := [1.0, 1.5, 0.6, 0.7, 1.0, 1.1, 0.8]
const SHARDS := [1.0, 0.7, 2.2, 1.2, 1.0, 0.6, 1.6]
const SIZE := [1.0, 0.9, 0.55, 0.85, 0.8, 1.1, 0.8]
const PAINT := [0.0, 0.0, 0.0, 0.9, 0.0, 0.0, 0.0]
## How hard the saw drags while biting into it (lower = heavier).
const DRAG := [0.2, 0.06, 0.5, 0.45, 0.16, 0.12, 0.35]
## Saw grind pitch: metal growls low, glass and fruit hiss high.
const PITCH := [0.95, 0.72, 1.2, 1.1, 0.85, 0.8, 1.25]

const FOOD := ["watermelon", "donut"]
const SCREENS := ["camera", "tv", "arcade", "gameboy", "cassette"]   # glossy = glass here


## Picks the material for one part from its object and its details.
static func for_part(gadget: String, d: Dictionary, boss: bool) -> int:
	var detail: int = int(d.get("detail", ObjectLibrary.Detail.NONE))
	if d.has("mat"):
		return int(d["mat"])
	if d.get("hazard", false):
		return ELECTRO
	if d.get("armor", false) or d.get("screw", false) or d.get("golden", false):
		return METAL
	if gadget in FOOD:
		return FRUIT
	if detail == ObjectLibrary.Detail.DOTS or detail == ObjectLibrary.Detail.HUB:
		return METAL
	if detail == ObjectLibrary.Detail.LINES:
		return ELECTRO
	if detail == ObjectLibrary.Detail.GLOSS and gadget in SCREENS:
		return GLASS
	if boss and not d.get("inlay", false):
		return ELECTRO            # the boards hiding under a boss's shell
	return PLASTIC
