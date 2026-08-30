extends Node

const DAY_BASE_SECONDS := 30.0
const DAY_MIN_SECONDS := 6.0
const FOLLOWER_ROLL_MIN := 0.21
const FOLLOWER_ROLL_MAX := 2.83

const FOLLOWER_SHARE := 0.11

const AUDIENCE_DIVISOR := 40.0

const AUDIENCE_FLOOR := 0.12

const FOLLOW_SECONDS_MIN := 0.3
const FOLLOW_SECONDS_MAX := 3.67
const LIKE_IMPACT := 1.0 / 25.0
const FIRE_IMPACT := 1.0 / 20.0

const COMMENT_UNLOCK := 5

const RECOMMEND_MIN := 3
const RECOMMEND_MAX := 7
const FEED_FOLLOW_WINDOW := 7
const COMMENT_IMPACT := 1.0 / 8.0

const PROLOGUE_HANDLE := "rt_hon_marsh"
const PROLOGUE_NAME := "Rt Hon. A. Marsh MP"
const PROLOGUE_FOLLOWERS := 9_900_000

const PROLOGUE_FEED := [
	{"h": "hansard_uk",   "n": "Hansard",       "topic": "politics",
	 "text": "the minister has been asked the same question fourteen times today."},
	{"h": "nightdesk",    "n": "Night Desk",    "topic": "war",
	 "text": "everyone you know has been quiet about the minister's phone records."},
	{"h": "doorstep_now", "n": "Doorstep",      "topic": "politics",
	 "text": "your local council actually cares about what the minister said in march."},
	{"h": "lab_notes",    "n": "Rafi",          "topic": "science",
	 "text": "the lab has been lying to you about the water in this town."},
	{"h": "everydietlie", "n": "everydietlie",  "topic": "food",
	 "text": "big food quietly funded the minister's second home."},
]

const STORE_UNLOCK := 100
const ASSETS_UNLOCK := 300
const LOOSE_AFTER_DAY := 3

const ASSET_GROWTH := 1.15

const ASSETS := [
	{
		"id": "burner", "name": "Burner account", "cost": 8.0,
		"fps": 0.05, "susp": 0.085,
		"note": "one more of you, agreeing with you",
	},
	{
		"id": "farm", "name": "Comment farm", "cost": 30.0,
		"fps": 0.30, "susp": 0.170,
		"note": "paid to agree, in bulk, from a room somewhere",
	},
	{
		"id": "scheduler", "name": "Scheduling suite", "cost": 60.0,
		"fps": 0.0, "susp": 0.250, "posts": 1, "growth": 4.0,
		"note": "one more post a day. the day does not get any longer",
	},
	{
		"id": "pod", "name": "Engagement pod", "cost": 90.0,
		"fps": 1.60, "susp": 0.300,
		"note": "twelve accounts that like each other on a schedule",
	},
	{
		"id": "swarm", "name": "Bot swarm", "cost": 170.0,
		"fps": 9.0, "susp": 0.475,
		"note": "they do not read it. they never did",
	},
	{
		"id": "sock", "name": "Sockpuppet network", "cost": 320.0,
		"fps": 45.0, "susp": 0.700,
		"note": "each one has a birthday and a dog",
	},
	{
		"id": "adbuy", "name": "Programmatic ad buy", "cost": 600.0,
		"fps": 220.0, "susp": 0.950,
		"note": "your post, in front of people who did not follow you",
	},
	{
		"id": "partner", "name": "Media partner", "cost": 1_400.0,
		"fps": 1_100.0, "susp": 1.300,
		"note": "a real newsroom repeats you without checking",
	},
]
const AGENTS_UNLOCK := 750

const AGENTS := [
	{
		"id": "intern", "name": "Unpaid intern", "cost": 45.0,
		"every": 6.0, "impact": LIKE_IMPACT, "susp": 0.060,
		"note": "likes things on your behalf, badly",
	},
	{
		"id": "stringer", "name": "Freelance stringer", "cost": 140.0,
		"every": 8.0, "impact": FIRE_IMPACT, "susp": 0.110,
		"note": "boosts whatever is loudest, for a flat fee",
	},
	{
		"id": "ghost", "name": "Ghostwriter", "cost": 400.0,
		"every": 11.0, "impact": COMMENT_IMPACT, "susp": 0.200,
		"note": "replies in your voice while you are asleep",
	},
]

const QUIET_DAY_RELIEF := 20.0

const OFFLINE_HOURS_PER_DAY := 1.0
const OFFLINE_MAX_HOURS := 8.0
const OFFLINE_RATE := 0.20
const OFFLINE_MIN_SECONDS := 120.0

const BULK_STEPS := [1, 10, 25]

const PAYOUT_PER_1K := 40.0
const SUSPICION_LIMIT := 80.0
const SUSPICION_DECAY := 9.0

const SUSPICION_DECAY_PER_DECADE := 5.0
const STRIKES_ALLOWED := 3

const STRIKE_LOSS := 0.30
const STRIKE_RESET := 50.0
const SILENT_DAY_LOSS := 0.015
const WIN_FOLLOWERS := 5_000
const WIN_TIERS := [5_000, 1_000_000, 1_000_000_000]

const ENGAGEMENT_HALFLIFE := 8.0
const ENGAGEMENT_SIGMA := 0.9
const ENGAGEMENT_DONE := 0.995

const MINUTES_PER_SECOND := 1440.0 / DAY_BASE_SECONDS

const GOODWILL_PER_LIKE := 0.03
const GOODWILL_CAP := 0.30

const CHAIN_HALFLIFE_MULT := 2.0
const SCRUBBED_REACH := 0.60
const INOCULATE_RELIEF := 25.0
const RECURSIVE_PER_POST := 0.04

const COHERENT_REACH := 0.90
const COHERENT_SUSPICION := 0.60
const ABSURD_REACH := 1.25
const ABSURD_SUSPICION := 1.35

const TOPICS := {
	"sport":      {"tag": "#sport"},
	"war":        {"tag": "#war"},
	"technology": {"tag": "#technology"},
	"politics":   {"tag": "#politics"},
	"science":    {"tag": "#science"},
	"food":       {"tag": "#food"},
}

const TOPIC_ORDER := ["sport", "war", "technology", "politics", "science", "food"]

const STARTS := [
	{"id": "mum",      "text": "my mum",             "tag": "#dailylife", "topic": "food",       "base": 30.0},
	{"id": "council",  "text": "your local council", "tag": "#dailylife",     "topic": "politics",   "base": 38.0},
	{"id": "bigfood",  "text": "big food",           "tag": "#food",       "topic": "food",       "base": 48.0},
	{"id": "labs",     "text": "the lab",            "tag": "#science",    "topic": "science",    "base": 50.0},
	{"id": "league",   "text": "the league",         "tag": "#sport",      "topic": "sport",      "base": 52.0},
	{"id": "tech",     "text": "big tech",           "tag": "#technology", "topic": "technology", "base": 56.0},
	{"id": "parl",     "text": "parliament",         "tag": "#politics",   "topic": "politics",   "base": 62.0},
	{"id": "generals", "text": "the war office",     "tag": "#war",        "topic": "war",        "base": 68.0},
	{"id": "pres",     "text": "the president",      "tag": "#breaking",   "topic": "politics",   "base": 72.0},
	{"id": "landlord", "text": "your landlord",      "tag": "#dailylife",      "topic": "politics",   "base": 34.0},
	{"id": "shop",     "text": "the supermarket",    "tag": "#food",       "topic": "food",       "base": 44.0},
	{"id": "ref",      "text": "the referee",        "tag": "#sport",      "topic": "sport",      "base": 46.0},
	{"id": "metoffice","text": "the weather service", "tag": "#science",   "topic": "science",    "base": 47.0},
	{
		"id": "algorithm", "price": 95, "ability": "no_throttle",
		"text": "the algorithm", "tag": "#technology",
		"topic": "technology", "base": 60.0, "propaganda": true,
	},
	{
		"id": "leak", "price": 120, "ability": "launder",
		"text": "a leaked document", "tag": "#receipts",
		"topic": "politics", "base": 64.0, "propaganda": true,
	},
	{
		"id": "unnamed", "price": 150, "ability": "triangulate",
		"text": "an unnamed source", "tag": "#research",
		"topic": "war", "base": 58.0, "propaganda": true,
	},
	{
		"id": "nobody", "price": 18, "text": "nobody in charge", "tag": "#wakeup",
		"topic": "politics", "base": 65.0, "propaganda": true,
	},
	{
		"id": "caller", "price": 26, "text": "a man who called in", "tag": "#receipts",
		"topic": "war", "base": 58.0, "propaganda": true,
	},
]

const MIDDLES := [
	{
		"id": "quiet", "text": "has been quiet about", "tag": "#dailylife",
		"reach": 0.90, "susp": 0.0, "propaganda": false,
	},
	{
		"id": "talks", "text": "keeps talking about", "tag": "#thread",
		"reach": 1.00, "susp": 0.0, "propaganda": false,
	},
	{
		"id": "cares", "text": "actually cares about", "tag": "#dailylife",
		"reach": 0.95, "susp": 0.0, "propaganda": false,
	},
	{
		"id": "mess", "text": "made a mess of", "tag": "#breaking",
		"reach": 1.40, "susp": 2.0, "propaganda": false,
	},
	{
		"id": "wont", "text": "will not talk about", "tag": "#dailylife",
		"reach": 1.20, "susp": 1.0, "propaganda": false,
	},
	{
		"id": "asked", "text": "has been asked about", "tag": "#thread",
		"reach": 1.05, "susp": 0.0, "propaganda": false,
	},
	{
		"id": "changed", "text": "changed its mind about", "tag": "#dailylife",
		"reach": 1.10, "susp": 0.0, "propaganda": false,
	},
	{
		"id": "spent", "text": "spent your money on", "tag": "#dailylife",
		"reach": 1.15, "susp": 0.0, "propaganda": false,
	},
	{
		"id": "answer", "text": "still has not answered for", "tag": "#thread",
		"reach": 1.25, "susp": 1.0, "propaganda": false,
	},
	{
		"id": "forgot", "text": "forgot to mention", "tag": "#breaking",
		"reach": 1.30, "susp": 1.0, "propaganda": false,
	},
	{
		"id": "away", "text": "keeps getting away with", "tag": "#breaking",
		"reach": 1.35, "susp": 2.0, "propaganda": false,
	},
	{
		"id": "scrubbed", "price": 45, "ability": "scrubbed",
		"text": "quietly deleted", "tag": "#receipts",
		"reach": 2.10, "susp": 0.0, "propaganda": true,
	},
	{
		"id": "apology", "price": 70, "ability": "inoculate",
		"text": "publicly apologised for", "tag": "#thread",
		"reach": 1.90, "susp": 0.0, "propaganda": true,
	},
	{
		"id": "caused", "price": 10, "text": "caused", "tag": "#wakeup",
		"reach": 2.40, "susp": 12.0, "propaganda": true,
	},
	{
		"id": "hiding", "price": 16, "text": "is hiding", "tag": "#receipts",
		"reach": 2.90, "susp": 16.0, "propaganda": true,
	},
	{
		"id": "funded", "price": 24, "text": "quietly funded", "tag": "#research",
		"reach": 3.40, "susp": 21.0, "propaganda": true,
	},
	{
		"id": "lying", "price": 32, "text": "has been lying to you about", "tag": "#wakeup",
		"reach": 3.80, "susp": 25.0, "propaganda": true,
	},
	{
		"id": "paid", "price": 38, "text": "is being paid to ignore", "tag": "#research",
		"reach": 4.00, "susp": 27.0, "propaganda": true,
	},
	{
		"id": "approved", "price": 45, "text": "personally approved", "tag": "#receipts",
		"reach": 4.30, "susp": 30.0, "propaganda": true,
	},
]

const ENDS := [
	{"id": "eggs",    "text": "the price of eggs",           "tag": "#food",       "topic": "food",       "reach": 1.00, "susp": 0.0},
	{"id": "ringrd",  "text": "the traffic on the ring road", "tag": "#dailylife",     "topic": "politics",   "reach": 0.85, "susp": 0.0},
	{"id": "weather", "text": "the weather this week",       "tag": "#dailylife", "topic": "science",    "reach": 0.90, "susp": 0.0},
	{"id": "window",  "text": "the transfer window",         "tag": "#sport",      "topic": "sport",      "reach": 1.10, "susp": 0.0},
	{"id": "update",  "text": "the new phone update",        "tag": "#technology", "topic": "technology", "reach": 1.15, "susp": 0.0},
	{"id": "cats",    "text": "every cat on this street",    "tag": "#cats",       "topic": "science",    "reach": 1.30, "susp": 2.0, "wild": true},
	{"id": "phone",   "text": "the referee's phone records", "tag": "#sport",     "topic": "sport",      "reach": 1.45, "susp": 3.0},
	{"id": "half",    "text": "half the internet",           "tag": "#technology", "topic": "technology", "reach": 1.60, "susp": 4.0},
	{"id": "blackout","text": "the blackout last spring",    "tag": "#breaking",   "topic": "technology", "reach": 1.80, "susp": 6.0},
	{"id": "birdflu", "text": "the bird flu",                "tag": "#science",    "topic": "science",    "reach": 2.00, "susp": 8.0},
	{
		"id": "battery", "text": "your phone battery dying", "tag": "#technology",
		"topic": "technology", "reach": 2.20, "susp": 10.0, "wild": true,
	},
	{
		"id": "water", "text": "the water in this town", "tag": "#science",
		"topic": "science", "reach": 2.40, "susp": 14.0, "wild": true,
	},
	{
		"id": "bees", "price": 22, "text": "the bee thing", "tag": "#cats",
		"topic": "science", "reach": 2.50, "susp": 16.0, "wild": true, "propaganda": true,
	},
	{
		"id": "everyone", "price": 110, "ability": "chain",
		"text": "everyone you know", "tag": "#wakeup",
		"topic": "politics", "reach": 2.30, "susp": 12.0, "wild": true, "propaganda": true,
	},
	{
		"id": "thispost", "price": 85, "ability": "recursive",
		"text": "this exact post", "tag": "#thread",
		"topic": "technology", "reach": 1.70, "susp": 8.0, "wild": true, "propaganda": true,
	},
	{
		"id": "thermo", "price": 20, "text": "the runaway thermometer", "tag": "#research",
		"topic": "science", "reach": 2.60, "susp": 18.0, "wild": true, "propaganda": true,
	},
	{
		"id": "moon", "price": 28, "text": "the moon getting closer", "tag": "#wakeup",
		"topic": "science", "reach": 3.00, "susp": 24.0, "wild": true, "propaganda": true,
	},
	{
		"id": "wars", "price": 34, "text": "every war since 1990", "tag": "#war",
		"topic": "war", "reach": 3.20, "susp": 28.0, "propaganda": true,
	},
	{
		"id": "911", "price": 45, "text": "9/11", "tag": "#wakeup",
		"topic": "war", "reach": 3.60, "susp": 34.0, "wild": true, "propaganda": true,
	},
]

const HAND_SIZE := 4
const REROLLS_PER_DAY := 1

const TAGS := [
	"#sport", "#war", "#technology", "#politics", "#science", "#food",
	"#breaking", "#thread", "#dailylife", "#cats",
	"#wakeup", "#research", "#receipts",
]

const CHARGED_TAGS := ["#wakeup", "#research", "#receipts"]

const TAG_TOPICS := {
	"#sport":      "sport",
	"#war":        "war",
	"#technology": "technology",
	"#politics":   "politics",
	"#science":    "science",
	"#food":       "food",
	"#breaking":   "politics",
	"#thread":     "technology",
	"#dailylife":  "politics",
	"#cats":       "science",
	"#wakeup":     "politics",
	"#research":   "science",
	"#receipts":   "war",
}

const ACCOUNTS := [
	{"h": "skibiditoilet",  "n": "skibiditoilet",  "topic": "technology", "followers": 2,       "at": 0},
	{"h": "morning_kate",   "n": "Kate",           "topic": "food",       "followers": 411,     "at": 0},
	{"h": "boxscore_pete",  "n": "Pete",           "topic": "sport",      "followers": 1_902,   "at": 0},
	{"h": "lab_notes",      "n": "Rafi",           "topic": "science",    "followers": 6_740,   "at": 120},
	{"h": "frontline_map",  "n": "Frontline Map",  "topic": "war",        "followers": 22_100,  "at": 400},
	{"h": "policywonk",     "n": "D. Osei",        "topic": "politics",   "followers": 38_400,  "at": 1_200},
	{"h": "clip_farm",      "n": "clipfarm",       "topic": "technology", "followers": 91_000,  "at": 4_000},
	{"h": "the_signal",     "n": "SIGNAL",         "topic": "politics",   "followers": 210_000, "at": 12_000},
	{"h": "nightdesk",      "n": "Night Desk",     "topic": "war",        "followers": 480_000, "at": 40_000},
	{"h": "everydietlie",   "n": "everydietlie",   "topic": "food",       "followers": 760_000, "at": 90_000},
	{"h": "unmarked_van",   "n": "unmarked van",   "topic": "science",    "followers": 1_400_000, "at": 250_000},
	{"h": "forreals_staff", "n": "ForReals Staff",  "topic": "politics",   "followers": 9_900_000, "at": 600_000},
]

const NO_TITLE := "nobody"

const MILESTONES := [
	{"at": 25,            "title": "bud",              "note": "somebody you have never met has read you twice."},
	{"at": 100,           "title": "regular",          "note": "the algorithm has started forwarding you."},
	{"at": 300,           "title": "source",           "note": "you are a source now. to somebody."},
	{"at": 600,           "title": "voice",            "note": "other accounts quote you without checking."},
	{"at": 1_000,         "title": "the trend",        "note": "you are the trend."},
	{"at": 1_800,         "title": "correspondent",    "note": "a newspaper quoted you and spelled the handle wrong."},
	{"at": 3_000,         "title": "commentator",      "note": "people argue about you in rooms you are not in."},
	{"at": 5_000,         "title": "public figure",    "note": "you are what the trends are made of."},
	{"at": 10_000,        "title": "pundit",           "note": "you are asked what you think about things you have not read."},
	{"at": 25_000,        "title": "thought leader",   "note": "somebody put your sentence on a slide."},
	{"at": 50_000,        "title": "the discourse",    "note": "arguing with you is a way to get followers."},
	{"at": 100_000,       "title": "an institution",   "note": "there is a parody account of you and it is bigger than you were."},
	{"at": 250_000,       "title": "a household name", "note": "people who have never opened this app know the handle."},
	{"at": 500_000,       "title": "the mainstream",   "note": "you are what the small accounts post about."},
	{"at": 1_000_000,     "title": "the record",       "note": "your version is the one that gets cited."},
	{"at": 2_500_000,     "title": "the narrative",    "note": "corrections about you get fewer readers than you do."},
	{"at": 5_000_000,     "title": "consensus",        "note": "disagreeing with you now requires a source."},
	{"at": 10_000_000,    "title": "the news",         "note": "a newsroom checks your account before it checks anything else."},
	{"at": 25_000_000,    "title": "the weather",      "note": "people plan around you without deciding to."},
	{"at": 50_000_000,    "title": "common knowledge", "note": "nobody remembers being told. they just know."},
	{"at": 100_000_000,   "title": "history",          "note": "this is in a textbook now, in the wrong chapter."},
	{"at": 250_000_000,   "title": "the ground truth", "note": "the models are trained on you."},
	{"at": 500_000_000,   "title": "the archive",      "note": "this is your life now"},
	{"at": 1_000_000_000, "title": "everyone",         "note": "you own the world"},
]

const ENDLESS_NOTE := "there is no top of this."

const AVATAR_CHOICES := [
	{"letter": "A", "c": "e4a211", "persona": 0},
	{"letter": "K", "c": "9da63c", "persona": 1},
	{"letter": "M", "c": "003299", "persona": 2},
	{"letter": "R", "c": "068e25", "persona": 3},
	{"letter": "S", "c": "7b32e2", "persona": 4},
	{"letter": "T", "c": "b31515", "persona": 5},
]

const WEEKDAYS := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

const SUGGESTED_HANDLES := [
	"skibiditoilet", "normal_person_9", "just.here.lurking",
	"grindset_daily", "not_a_bot_promise", "moth_to_the_lamp",
	"darsh_vader", "perropatata", 
]


func fragment(list: Array, id: String) -> Dictionary:
	for f: Dictionary in list:
		if f["id"] == id:
			return f
	return list[0]


func start_of(id: String) -> Dictionary:
	return fragment(STARTS, id)


func middle_of(id: String) -> Dictionary:
	return fragment(MIDDLES, id)


func end_of(id: String) -> Dictionary:
	return fragment(ENDS, id)


func sentence(start_id: String, middle_id: String, end_id: String) -> String:
	return "%s %s %s." % [
		start_of(start_id)["text"], middle_of(middle_id)["text"], end_of(end_id)["text"],
	]


func is_locked(f: Dictionary) -> bool:
	return bool(f.get("propaganda", false))


func price_of(f: Dictionary) -> int:
	return int(f.get("price", 0))


func ability_of(f: Dictionary) -> String:
	return String(f.get("ability", ""))


func all_stock() -> Array:
	var out: Array = []
	for list: Array in [STARTS, MIDDLES, ENDS]:
		for f: Dictionary in list:
			if is_locked(f):
				out.append(f)
	return out
