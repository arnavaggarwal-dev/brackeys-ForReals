class_name People
extends RefCounted


const PARTS := {
	"sport": {
		"heads": ["boxscore", "matchday", "terrace", "offside", "fulltime", "backpage"],
		"tails": ["_pete", "_daily", "_watch", "_takes", "82", "_uk"],
		"names": ["Pete", "Dev", "Marco", "Terrace Talk", "Full Time", "Ash"],
		"bios": [
			"watched every minute so you did not have to",
			"the referee has questions to answer",
			"i do not care about the sport, i care about the table",
		],
	},
	"war": {
		"heads": ["frontline", "nightdesk", "convoy", "redline", "openmap", "situation"],
		"tails": ["_map", "_desk", "_intl", "_ops", "watch", "_room"],
		"names": ["Frontline Map", "Night Desk", "Convoy", "Redline", "OSINT Dad", "Situation"],
		"bios": [
			"maps, timestamps, no sources",
			"posting through it since tuesday",
			"i am not a journalist and i will not be corrected",
		],
	},
	"technology": {
		"heads": ["clip", "buildlog", "shipit", "latency", "rootcause", "coldboot"],
		"tails": ["_farm", "_dev", "99", "_eng", "_io", "_beta"],
		"names": ["clipfarm", "buildlog", "ship it", "Latency", "root cause", "coldboot"],
		"bios": [
			"i have opinions about a phone i do not own",
			"early access to everything, understanding of nothing",
			"the update is fine. the update is not fine.",
		],
	},
	"politics": {
		"heads": ["policywonk", "thesignal", "backbench", "doorstep", "greenpaper", "hansard"],
		"tails": ["_uk", "_now", "_live", "_daily", "_desk", "24"],
		"names": ["D. Osei", "SIGNAL", "Backbench", "Doorstep", "Green Paper", "Hansard"],
		"bios": [
			"reading the bill so nobody has to",
			"neutral, obviously",
			"asking the question everybody is thinking",
		],
	},
	"science": {
		"heads": ["labnotes", "unmarked", "peerreview", "coldchain", "datapoint", "prelim"],
		"tails": ["_van", "_notes", "_lab", "_data", "_phd", "_pre"],
		"names": ["Rafi", "unmarked van", "Peer Review", "Cold Chain", "Data Point", "prelim"],
		"bios": [
			"preprint enjoyer. correlation appreciator.",
			"i read the abstract and that is enough",
			"the study says what i need it to say",
		],
	},
	"food": {
		"heads": ["morning", "everydiet", "cleanplate", "seedoil", "batchcook", "markup"],
		"tails": ["_kate", "lie", "_uk", "_truth", "_daily", "_now"],
		"names": ["Kate", "everydietlie", "Clean Plate", "Seed Oil Guy", "Batch Cook", "Markup"],
		"bios": [
			"what they put in it and why",
			"the supermarket knows exactly what it is doing",
			"i have not eaten bread since march and i will tell you about it",
		],
	},
}

const BANDS := [
	{"min": 40, "max": 900, "at": 0},
	{"min": 900, "max": 9_000, "at": 60},
	{"min": 9_000, "max": 80_000, "at": 900},
	{"min": 80_000, "max": 600_000, "at": 15_000},
	{"min": 600_000, "max": 4_000_000, "at": 150_000},
]


static func recommend(run_id: int, day: int, taken: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_id * 15_485_863 + day * 32_452_843
	var count := rng.randi_range(Data.RECOMMEND_MIN, Data.RECOMMEND_MAX)

	var out: Array = []
	var used: Dictionary = {}
	for h: String in taken:
		used[h] = true

	var guard := 0
	while out.size() < count and guard < count * 12:
		guard += 1
		var acc := _one(rng)
		if used.has(String(acc["h"])):
			continue
		used[String(acc["h"])] = true
		out.append(acc)
	return out


static func _one(rng: RandomNumberGenerator) -> Dictionary:
	var topic: String = Data.TOPIC_ORDER[rng.randi() % Data.TOPIC_ORDER.size()]
	var parts: Dictionary = PARTS[topic]

	var head: String = parts["heads"][rng.randi() % parts["heads"].size()]
	var tail: String = parts["tails"][rng.randi() % parts["tails"].size()]
	var handle := head + tail

	var band: Dictionary = BANDS[rng.randi() % BANDS.size()]
	var followers := rng.randi_range(int(band["min"]), int(band["max"]))

	return {
		"h": handle,
		"n": String(parts["names"][rng.randi() % parts["names"].size()]),
		"topic": topic,
		"bio": String(parts["bios"][rng.randi() % parts["bios"].size()]),
		"followers": followers,
		"at": int(band["at"]),
		"made": true,
	}
