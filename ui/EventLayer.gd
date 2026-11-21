extends CanvasLayer
## Screen-space layer for news: the banner strip, the big title cards, the
## gold chip in the top-right corner, the job clock, and the coins flying to the cash.

const TOP := 90.0


func _ready() -> void:
	layer = 13
	var banner: Control = preload("res://ui/Banner.gd").new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(banner)

	var card: Control = preload("res://ui/TitleCard.gd").new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(card)

	var chip: Control = preload("res://ui/GoldChip.gd").new()
	chip.visible = not get_parent() is RushGame          # gold meter is a Jobs thing
	chip.anchor_left = 1.0
	chip.anchor_right = 1.0
	chip.offset_left = -400.0
	chip.offset_right = -56.0
	chip.offset_top = TOP + 168.0
	chip.offset_bottom = TOP + 226.0
	add_child(chip)

	var job: Control = preload("res://ui/JobHUD.gd").new()
	job.anchor_left = 0.5
	job.anchor_right = 0.5
	job.offset_left = -200.0
	job.offset_right = 200.0
	job.offset_top = TOP + 60.0           # under the progress squares
	job.offset_bottom = TOP + 190.0
	add_child(job)

	var coins: Node2D = preload("res://ui/CoinFlight.gd").new()
	add_child(coins)
