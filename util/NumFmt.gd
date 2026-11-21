class_name NumFmt
## Short, glanceable numbers: 950 -> "950", 12500 -> "12.5K", 837412 -> "837K",
## 1200000 -> "1.2M". Used for every price, payout and the cash counter.

const UNITS := ["", "K", "M", "B", "T", "Q"]


static func short(n: float) -> String:
	var neg := n < 0.0
	var v := absf(n)
	var u := 0
	while v >= 1000.0 and u < UNITS.size() - 1:
		v /= 1000.0
		u += 1
	var s: String
	if u == 0:
		s = "%d" % int(round(v))
	elif v >= 100.0:
		s = "%d%s" % [int(v), UNITS[u]]
	elif v >= 10.0:
		s = "%s%s" % [_trim("%.1f" % (floorf(v * 10.0) / 10.0)), UNITS[u]]
	else:
		s = "%s%s" % [_trim("%.2f" % (floorf(v * 100.0) / 100.0)), UNITS[u]]
	return ("-" if neg else "") + s


## "$12.5K"
static func money(n: float) -> String:
	return ("-$" + short(-n)) if n < 0.0 else ("$" + short(n))


static func _trim(s: String) -> String:
	if s.contains("."):
		s = s.rstrip("0").rstrip(".")
	return s
