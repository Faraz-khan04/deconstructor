class_name WeakPoints
## Per-object planning for Structure: which parts glow as weak points right
## now, and the job goals it brings (par cuts + a fair amount of time).


## Par cuts + a fair time: travel per cut, plus sawing time at starting power.
static func plan(s: Structure) -> void:
	var n := s._blocks.size()
	var hp := PackedFloat32Array()
	var screw := PackedByteArray()
	var armor := PackedByteArray()
	var locked := PackedByteArray()
	for b in s._blocks:
		hp.append(b.max_hp)
		screw.append(1 if b.screw else 0)
		armor.append(1 if b.armor else 0)
		locked.append(1 if b.golden or b.hazard else 0)
	var p := PartGraph.par(s._neighbors, s._anchors, alive_mask(s), hp, screw, armor, locked,
		maxi(2, int(n * s.crumble_at)))
	s.par_cuts = int(p.x) + 1                                   # one spare cut
	var total := 0.0
	for v in hp:
		total += v
	# Smart cuts x1.7, plus a third of "cut everything", so sloppy play survives
	# small objects but runs dry on big ones.
	var tight := maxf(0.6, 1.0 - 0.015 * (Save.data["level"] - 1))   # later jobs: less slack
	s.power_budget = (p.y * 1.7 + total * 0.3 + 1.0) * tight


## Mark the (up to 3) cuts that would drop the most, if they drop enough.
static func refresh(s: Structure) -> void:
	var alive := alive_mask(s)
	var can := PackedByteArray()
	var attached := 0
	for b in s._blocks:
		var ok: bool = b != null and b.state == Block.State.ATTACHED and not s.is_locked(b) and not b.hazard
		can.append(1 if ok else 0)
	for v in alive:
		attached += v
	var d := PartGraph.drops(s._neighbors, s._anchors, alive, can)
	var need := maxi(Structure.CLEAN_CUT_MIN, int(attached * 0.12))
	var order: Array = range(s._blocks.size())
	order.sort_custom(func(a: int, c: int) -> bool: return d[a] > d[c])
	for rank in order.size():
		var b = s._blocks[order[rank]]
		if b != null:
			b.set_weak(rank < 3 and d[order[rank]] >= need, d[order[rank]])


static func alive_mask(s: Structure) -> PackedByteArray:
	var m := PackedByteArray()
	for b in s._blocks:
		m.append(1 if b != null and b.state == Block.State.ATTACHED else 0)
	return m
