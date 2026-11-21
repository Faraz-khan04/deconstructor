class_name PartGraph
## How an object's parts hold each other up, and where its weak points are.
## Parts connect to touching parts; anchors hold the object in the air.
## A small part sitting on top of others (a key, a screen, a gear) hangs on
## exactly ONE host part, so cutting that host drops everything on it.
## A weak point = a part whose loss drops a big chunk of the object.

## Keep each top part (inlay) linked only to the base part it sits on most.
static func single_host(nb: Array, inlays: Array, polys: Array) -> Array:
	var out: Array = []
	for i in nb.size():
		out.append([])
	for i in nb.size():
		for j in nb[i]:
			if not inlays[i] and not inlays[j] and j > i:
				out[i].append(j)
				out[j].append(i)
	for i in nb.size():
		if not inlays[i]:
			continue
		var c := _center(polys[i])
		var best := -1
		var best_d := INF
		for j in nb[i]:
			if inlays[j]:
				continue
			var dd := c.distance_squared_to(_center(polys[j]))
			if dd < best_d:
				best_d = dd
				best = j
		if best >= 0:
			out[i].append(best)
			out[best].append(i)
	return out


## Parts still connected to an attached anchor. `alive[i]` = part i attached.
## `removed` = pretend that part is gone.
static func reach(nb: Array, anchors: PackedInt32Array, alive: PackedByteArray,
		removed: int = -1) -> Dictionary:
	var seen := {}
	var q: Array[int] = []
	for a in anchors:
		if a != removed and alive[a] == 1:
			seen[a] = true
			q.append(a)
	while not q.is_empty():
		var i: int = q.pop_back()
		for n in nb[i]:
			if n != removed and alive[n] == 1 and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen


## How many other parts fall if part i is cut (0 for parts that can't be cut).
static func drops(nb: Array, anchors: PackedInt32Array, alive: PackedByteArray,
		cuttable: PackedByteArray) -> PackedInt32Array:
	var base := reach(nb, anchors, alive).size()
	var out := PackedInt32Array()
	out.resize(alive.size())
	for i in alive.size():
		if alive[i] == 1 and cuttable[i] == 1:
			out[i] = maxi(0, base - 1 - reach(nb, anchors, alive, i).size())
	return out


## A good player's number of cuts: keep cutting the biggest weak point until
## the object falls apart (crumble rule: <= `crumble_at` parts left holding).
## Locked parts (shell while screws remain, gold) can't be picked.
## Returns Vector2(cuts, hp of the parts cut).
static func par(nb: Array, anchors: PackedInt32Array, alive_in: PackedByteArray,
		hp: PackedFloat32Array, screw: PackedByteArray, armor: PackedByteArray,
		locked: PackedByteArray, crumble_at: int) -> Vector2:
	var alive := alive_in.duplicate()
	var screws := 0
	for s in screw:
		screws += s
	var cuts := 0
	var cut_hp := 0.0
	while cuts < 60:
		var held := reach(nb, anchors, alive)
		if screws == 0 and held.size() <= crumble_at:
			break
		var can := PackedByteArray()
		can.resize(alive.size())
		for i in alive.size():
			var ok := held.has(i) and locked[i] == 0 and not (armor[i] == 1 and screws > 0)
			can[i] = 1 if ok else 0
		var d := drops(nb, anchors, alive, can)
		var pick := -1
		for i in alive.size():
			if can[i] == 1 and (pick < 0 or _better(i, pick, d, screw, hp, screws)):
				pick = i
		if pick < 0:
			break
		alive[pick] = 0
		var still := reach(nb, anchors, alive)
		for i in alive.size():          # what that cut dropped is gone too
			if alive[i] == 1 and not still.has(i):
				alive[i] = 0
		screws -= screw[pick]
		cuts += 1
		cut_hp += hp[pick]
	return Vector2(cuts, cut_hp)


static func _better(i: int, j: int, d: PackedInt32Array, screw: PackedByteArray,
		hp: PackedFloat32Array, screws: int) -> bool:
	if screws > 0 and screw[i] != screw[j]:
		return screw[i] == 1                  # bosses: screws first
	if d[i] != d[j]:
		return d[i] > d[j]
	return hp[i] < hp[j]


static func _center(p: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for q in p:
		c += q
	return c / maxf(p.size(), 1.0)
