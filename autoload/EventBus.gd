extends Node
## Global signal bus. Systems emit here and never hold references to each other.
## Physics -> EventBus -> Juice / Paint / Audio / UI.

# --- Juice requests -------------------------------------------------------
## strength 0..1. Everything >= 0.8 also triggers a hit-stop.
@warning_ignore("unused_signal")
signal impact(world_pos: Vector2, strength: float)

@warning_ignore("unused_signal")
signal shake_requested(trauma: float)

@warning_ignore("unused_signal")
signal hitstop_requested(duration_ms: int)

@warning_ignore("unused_signal")
signal popup_requested(text: String, world_pos: Vector2, color: Color, size_mult: float)

## Tiny, very frequent feedback while the saw grinds a tile.
@warning_ignore("unused_signal")
signal grind_tick(world_pos: Vector2, mat: int)

## Current combo count (0 = combo ended). Drives the combo badge.
@warning_ignore("unused_signal")
signal combo_changed(count: int)

## Big news in the reserved strip under the progress squares (queued, never
## overlaps the combo badge). Same title again = update in place.
@warning_ignore("unused_signal")
signal banner_requested(title: String, sub: String, color: Color)

## Full-width title card across the middle ("LEVEL 16", "FRENZY!").
@warning_ignore("unused_signal")
signal title_card_requested(title: String, sub: String, color: Color)

# --- Paint ----------------------------------------------------------------
## direction = where the juice flies (usually blade velocity). strength 0..1.
## color.a == 0 -> PaintLayer picks a random colour.
@warning_ignore("unused_signal")
signal splash(world_pos: Vector2, direction: Vector2, strength: float, color: Color)

@warning_ignore("unused_signal")
signal paint_clear_requested()

@warning_ignore("unused_signal")
signal palette_changed(palette_name: String)

# --- Structures & fragments -------------------------------------------------
@warning_ignore("unused_signal")
signal block_shattered(world_pos: Vector2, color: Color, value: int, velocity: Vector2, mat: int)

## The saw finished off a part that was still attached (one "cut" for the job).
@warning_ignore("unused_signal")
signal part_cut(world_pos: Vector2, was_weak: bool)

## One cut dropped `count` parts at once (share = fraction of the object).
@warning_ignore("unused_signal")
signal clean_cut(world_pos: Vector2, count: int, share: float)

## RUSH: a bomb got sliced.
@warning_ignore("unused_signal")
signal bomb_hit(world_pos: Vector2)

## A shard bounced off peg number `index` (for the pinball pings).
@warning_ignore("unused_signal")
signal peg_hit(index: int)

# --- Jobs (each level is a job: clock, gold, few cuts -> 1-3 stars) ----------
@warning_ignore("unused_signal")
signal job_finished(won: bool, stars: int)

## Result screen buttons: retry = same job again, else the next one.
@warning_ignore("unused_signal")
signal job_next(retry: bool)

## A new object arrived and brought its own time with it.
@warning_ignore("unused_signal")
signal time_added(seconds: float)

@warning_ignore("unused_signal")
signal fragments_requested(world_pos: Vector2, color: Color, count: int, size: float, velocity: Vector2, value_each: int)

## A shard reached the shredder. amount already includes gate multipliers.
@warning_ignore("unused_signal")
signal fragment_collected(world_pos: Vector2, color: Color, amount: int)

## Squeegee: request a wipe; progress reports the blade's world y each frame.
@warning_ignore("unused_signal")
signal wipe_requested()

@warning_ignore("unused_signal")
signal wipe_progress(world_y: float)

@warning_ignore("unused_signal")
signal wipe_finished()

@warning_ignore("unused_signal")
signal level_started(level: int)

## Objects smashed / objects in this level (drives the top progress bar).
@warning_ignore("unused_signal")
signal level_progress(done: int, total: int)

# --- Collection, tools ------------------------------------------------------
## A golden part was sliced free (found) or fell in the shredder (missed).
@warning_ignore("unused_signal")
signal golden_found(gadget: String, slot: int, world_pos: Vector2)

@warning_ignore("unused_signal")
signal golden_missed(world_pos: Vector2)

## 0..2 golden parts toward the next FRENZY (3 = frenzy starts, meter resets).
@warning_ignore("unused_signal")
signal gold_meter_changed(count: int)

@warning_ignore("unused_signal")
signal frenzy_changed(active: bool)

## An object was fully smashed. first_time = new in the catalog.
@warning_ignore("unused_signal")
signal gadget_smashed(gadget: String, first_time: bool)

@warning_ignore("unused_signal")
signal tool_changed(tool_id: String)

## Laser cutter scorch line from a to b (drawn onto the paper).
@warning_ignore("unused_signal")
signal burn(a: Vector2, b: Vector2)

# --- Economy --------------------------------------------------------------
## Anything that earns money emits this; Economy turns it into cash.
@warning_ignore("unused_signal")
signal score_added(amount: int)

@warning_ignore("unused_signal")
signal cash_changed(cash: int, delta: int)

@warning_ignore("unused_signal")
signal upgrades_changed()

