extends Node
## Art direction: "Paper & Sticker". Warm graph paper, ink lines, die-cut
## stickers with soft shadows, retro-hardware accent colours.
## Single source of truth for every colour and font. Never hard-code either.

# --- Surfaces -------------------------------------------------------------
const PAPER := Color("#ECE6D9")        # warm graph-paper base
const PAPER_LIGHT := Color("#F3EEE3")
const CREAM := Color("#F0F0E4")        # hardware body plastic
const STICKER := Color("#FCFCFC")      # die-cut sticker border
const STONE := Color("#D9D2C3")        # light grey plastic (pads, panels)
const CHARCOAL := Color("#2A2A28")     # dark plastic (screens, speakers)
const SHADOW := Color(0.07, 0.06, 0.05, 0.22)

# --- Ink ------------------------------------------------------------------
const INK := Color("#111110")
const INK_SOFT := Color("#716E69")

# --- Retro-hardware accents ----------------------------------------------
const RED := Color("#CC2418")          # sampler-pad red
const COBALT := Color("#00249C")       # keyboard-key blue
const PINK := Color("#FF8B9D")
const BUTTER := Color("#F0CC78")
const TEAL := Color("#154D6B")

# --- Juice paint (splashes on the paper) ----------------------------------
const TANGERINE := Color("#FF7A3D")
const MINT := Color("#6FD3B0")
const LILAC := Color("#A78BFA")
const PAINT := [PINK, BUTTER, COBALT, RED, TEAL, TANGERINE, MINT, LILAC]

## Curated 4-colour sets. One per canvas, so overlaps stay harmonious.
## Index 0 is the default full-range set; the rest are themed sets kept for
## later (e.g. unlockable palettes).
const PAINT_PALETTES := [
	{"name": "FULL SPECTRUM", "colors": PAINT},
	{"name": "SORBET", "colors": [PINK, TANGERINE, BUTTER, LILAC]},
	{"name": "POOLSIDE", "colors": [COBALT, MINT, BUTTER, TEAL]},
	{"name": "CHERRY", "colors": [RED, PINK, TANGERINE, BUTTER]},
	{"name": "BERRY FIZZ", "colors": [LILAC, COBALT, PINK, MINT]},
	{"name": "MARIGOLD", "colors": [TANGERINE, BUTTER, RED, TEAL]},
]

## Strong enough to read as text on paper.
const TEXT_ACCENTS := [RED, COBALT, TEAL, INK]
## Pastel washes: highlighter strokes, backgrounds.
const SOFT_ACCENTS := [PINK, BUTTER]

# --- Fonts (loaded in _ready, with system fallbacks) ----------------------
var display_font: Font   # Montserrat Black: headlines, scores, popups
var mono_font: Font      # DM Mono: small labels


func _ready() -> void:
	display_font = _variable_font("res://fonts/Montserrat-Variable.ttf", 900,
		["Montserrat", "Arial Black", "Helvetica"])
	mono_font = _static_font("res://fonts/DMMono-Medium.ttf",
		["DM Mono", "Courier New", "monospace"])


static func with_alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


func random_text_accent() -> Color:
	return TEXT_ACCENTS.pick_random()


## Highlighter-style trail: transparent tail -> translucent colour at the head.
static func trail_gradient(c: Color, head_alpha: float = 0.6) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, with_alpha(c, 0.0))
	g.set_color(1, with_alpha(c, head_alpha))
	return g


func _variable_font(path: String, weight: int, fallbacks: Array) -> Font:
	if not ResourceLoader.exists(path):
		return _system_font(fallbacks, weight)
	var fv := FontVariation.new()
	fv.base_font = load(path)
	var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {wght: weight}
	return fv


func _static_font(path: String, fallbacks: Array) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return _system_font(fallbacks, 500)


func _system_font(names: Array, weight: int) -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(names)
	sf.font_weight = weight
	return sf
