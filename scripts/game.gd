extends Node

signal toast_requested(title: String, sub: String, bad: bool)
signal view_dirty
signal nav_dirty
signal day_started(day: int)
signal glitch(strength: float)
signal screen_changed(screen: String)

var screen := "signin"

var handle := "skibiditoilet"
var avatar: Dictionary = Data.AVATAR_CHOICES[0]

var day := 1
var day_left := Data.DAY_BASE_SECONDS
var posts_today := 0
var payout := 0.0
var owned: Dictionary = {}
var store_unlocked := false
var assets_unlocked := false
var comments_unlocked := false
var assets: Dictionary = {}
var paused: Dictionary = {}
var agents: Dictionary = {}
var agents_unlocked := false
var bulk := 1

var _agent_clocks: Dictionary = {}

var followers := 0
var following: Array[String] = []
var follows_today := 0
var follow_seconds_today := 0.0
var suspicion := 0.0
var strikes := 0
var milestone := 0
var won := false
var win_tier := 0
var endless_mark := 0
var offline_report: Dictionary = {}

var my_posts: Array = []
var feed: Array = []
var trending: Array = []

var hand := {"start": [], "middle": [], "end": []}
var rerolls_left := Data.REROLLS_PER_DAY

var draft_start := ""
var draft_middle := ""
var draft_end := ""

var elapsed := 0.0
var likes_given_today := 0
var liked: Dictionary = {}
var fired: Dictionary = {}
var people: Dictionary = {}
var suggestions: Array = []
var my_reactions: Array = []

var prologue := false
var run_id := 0
var _tick := false
var _post_salt := 0
var _follower_pool := 0.0
var _payout_pool := 0.0


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if not _tick or screen != "app":
		return
	elapsed += delta
	day_left -= delta
	_tick_engagement(delta)
	if day_left <= 0.0:
		_advance_day()


func reset() -> void:
	run_id += 1
	screen = "signin"
	prologue = false
	day = 1
	posts_today = 0
	payout = 0.0
	owned = {}
	store_unlocked = false
	assets_unlocked = false
	comments_unlocked = false
	assets = {}
	paused = {}
	agents = {}
	agents_unlocked = false
	bulk = 1
	_agent_clocks = {}
	followers = 0
	following = []
	follows_today = 0
	follow_seconds_today = 0.0
	suspicion = 0.0
	strikes = 0
	milestone = 0
	won = false
	win_tier = 0
	endless_mark = 0
	offline_report = {}
	my_posts = []
	feed = []
	rerolls_left = Data.REROLLS_PER_DAY
	elapsed = 0.0
	likes_given_today = 0
	liked = {}
	fired = {}
	people = {}
	suggestions = []
	my_reactions = []
	_tick = false
	_post_salt = 0
	_follower_pool = 0.0
	_payout_pool = 0.0
	roll_trends()
	deal_hand()
	roll_suggestions()
	_seed_feed()
	day_left = day_length()


func begin_prologue() -> void:
	reset()
	prologue = true
	handle = Data.PROLOGUE_HANDLE
	avatar = Data.AVATAR_CHOICES[4]
	followers = Data.PROLOGUE_FOLLOWERS
	following = []
	suspicion = Data.SUSPICION_LIMIT - 6.0
	strikes = Data.STRIKES_ALLOWED - 1
	day = 1
	screen = "app"

	feed = []
	for i in Data.PROLOGUE_FEED.size():
		var src: Dictionary = Data.PROLOGUE_FEED[i]
		_post_salt += 1
		feed.append({
			"uid": "p_%d" % _post_salt,
			"acc": {
				"h": String(src["h"]), "n": String(src["n"]),
				"topic": String(src["topic"]), "followers": 40_000 * (i + 3), "at": 0,
			},
			"text": String(src["text"]),
			"tags": [String(Data.TOPICS[src["topic"]]["tag"]), "#breaking"],
			"charged": true,
			"day": 1,
			"at": elapsed - 40.0 * (i + 1),
			"progress": 1.0,
			"likes": 9_000 * (i + 2),
			"replies": 2_400 * (i + 1),
			"fire": 6_100 * (i + 1),
			"t_likes": 9_000 * (i + 2),
			"t_replies": 2_400 * (i + 1),
			"t_fire": 6_100 * (i + 1),
		})

	_tick = true
	screen_changed.emit(screen)
	day_started.emit(day)


func begin(chosen_handle: String, chosen_avatar: Dictionary) -> void:
	handle = chosen_handle
	avatar = chosen_avatar
	screen = "app"
	_tick = true
	screen_changed.emit(screen)
	day_started.emit(day)


func resume() -> void:
	screen = "app"
	day_left = day_length()
	_tick = true
	screen_changed.emit(screen)
	day_started.emit(day)


func keep_going() -> void:
	screen = "app"
	_tick = true
	screen_changed.emit(screen)
	nav_dirty.emit()
	view_dirty.emit()


func pause_clock() -> void:
	_tick = false


func alive(id: int) -> bool:
	return id == run_id and screen == "app"


func day_length() -> float:
	return maxf(Data.DAY_MIN_SECONDS, Data.DAY_BASE_SECONDS - follow_seconds_today)


func day_fraction() -> float:
	return clampf(day_left / maxf(0.01, day_length()), 0.0, 1.0)


func day_name() -> String:
	return Data.WEEKDAYS[(day - 1) % Data.WEEKDAYS.size()]


func _advance_day() -> void:
	if posts_today == 0 and day > 1 and followers > 0:
		var lost := int(ceil(followers * Data.SILENT_DAY_LOSS))
		followers = maxi(0, followers - lost)
		suspicion = maxf(0.0, suspicion - Data.QUIET_DAY_RELIEF)
		if lost > 0:
			toast_requested.emit(
				"Quiet day",
				"-%s followers, -%d suspicion - the feed moved on"
					% [commas(lost), int(Data.QUIET_DAY_RELIEF)],
				true
			)

	day += 1
	posts_today = 0
	follows_today = 0
	follow_seconds_today = 0.0
	likes_given_today = 0
	suspicion = maxf(0.0, suspicion - daily_cooling())
	day_left = day_length()
	rerolls_left = Data.REROLLS_PER_DAY
	roll_trends()
	deal_hand()
	roll_suggestions()
	_populate_feed()


	Save.mark()
	day_started.emit(day)
	nav_dirty.emit()
	view_dirty.emit()
	Sfx.tick()


func deal_hand() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (run_id * 7919 + day * 104729
		+ (Data.REROLLS_PER_DAY - rerolls_left) * 31 + posts_today * 6971)
	hand["start"] = _deal(Data.STARTS, rng)
	hand["middle"] = _deal(Data.MIDDLES, rng)
	hand["end"] = _deal(Data.ENDS, rng)
	draft_start = String(hand["start"][0]["id"])
	draft_middle = String(hand["middle"][0]["id"])
	draft_end = String(hand["end"][0]["id"])


func _deal(list: Array, rng: RandomNumberGenerator) -> Array:
	var pool: Array = list.filter(func(f: Dictionary) -> bool: return fragment_available(f))
	if pool.size() <= Data.HAND_SIZE:
		return pool.duplicate()
	var picked: Array = []
	var taken := {}
	while picked.size() < Data.HAND_SIZE:
		var k := rng.randi() % pool.size()
		if taken.has(k):
			continue
		taken[k] = true
		picked.append(pool[k])
	return picked


func reroll_hand() -> void:
	if rerolls_left <= 0:
		toast_requested.emit("No deals left today", "you get %d. spend it early" % Data.REROLLS_PER_DAY, true)
		return
	rerolls_left -= 1
	deal_hand()
	Sfx.tick()
	toast_requested.emit("Dealt again", "%d left today" % rerolls_left, false)
	view_dirty.emit()


func _erf(x: float) -> float:
	var sign_x := 1.0 if x >= 0.0 else -1.0
	var ax := absf(x)
	var t := 1.0 / (1.0 + 0.3275911 * ax)
	var y := 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t
		- 0.284496736) * t + 0.254829592) * t * exp(-ax * ax)
	return sign_x * y


func engagement_progress(age: float, halflife_mult: float = 1.0) -> float:
	if age <= 0.05:
		return 0.0
	var z: float = log(
		age / (Data.ENGAGEMENT_HALFLIFE * halflife_mult)
	) / Data.ENGAGEMENT_SIGMA
	return clampf(0.5 * (1.0 + _erf(z / sqrt(2.0))), 0.0, 1.0)


func asset_count(id: String) -> int:
	return int(assets.get(id, 0))


func asset_cost(a: Dictionary) -> int:
	var growth: float = float(a.get("growth", Data.ASSET_GROWTH))
	return int(round(float(a["cost"]) * pow(growth, asset_count(String(a["id"])))))


func bulk_cost(a: Dictionary, n: int) -> int:
	var growth: float = float(a.get("growth", Data.ASSET_GROWTH))
	var owned := asset_count(String(a["id"]))
	var total := 0.0
	for i in n:
		total += float(a["cost"]) * pow(growth, owned + i)
	return int(round(total))


func bulk_affordable(a: Dictionary, n: int) -> int:
	var most := 0
	while most < n and bulk_cost(a, most + 1) <= int(payout):
		most += 1
	return most


func cycle_bulk() -> void:
	var i := Data.BULK_STEPS.find(bulk)
	bulk = int(Data.BULK_STEPS[(i + 1) % Data.BULK_STEPS.size()])
	view_dirty.emit()


func is_paused(id: String) -> bool:
	return bool(paused.get(id, false))


func toggle_paused(id: String) -> void:
	paused[id] = not is_paused(id)
	Sfx.tick()
	Save.mark()
	view_dirty.emit()


func agent_count(id: String) -> int:
	return int(agents.get(id, 0))


func agent_cost(a: Dictionary) -> int:
	return int(round(float(a["cost"]) * pow(Data.ASSET_GROWTH, agent_count(String(a["id"])))))


func bulk_agent_cost(a: Dictionary, n: int) -> int:
	var owned := agent_count(String(a["id"]))
	var total := 0.0
	for i in n:
		total += float(a["cost"]) * pow(Data.ASSET_GROWTH, owned + i)
	return int(round(total))


func bulk_agents_affordable(a: Dictionary, n: int) -> int:
	var most := 0
	while most < n and bulk_agent_cost(a, most + 1) <= int(payout):
		most += 1
	return most


func agents_open() -> bool:
	return agents_unlocked


func buy_agent(a: Dictionary, n: int = 1) -> void:
	if not agents_open():
		return
	var got := bulk_agents_affordable(a, n)
	if got <= 0:
		return
	payout -= float(bulk_agent_cost(a, got))
	var id := String(a["id"])
	agents[id] = agent_count(id) + got
	Sfx.blip()
	Save.mark()
	view_dirty.emit()


func agent_suspicion_per_second() -> float:
	var total := 0.0
	for a: Dictionary in Data.AGENTS:
		if is_paused(String(a["id"])):
			continue
		total += float(a["susp"]) * agent_count(String(a["id"]))
	return total


func _tick_agents(delta: float) -> void:
	for a: Dictionary in Data.AGENTS:
		var id := String(a["id"])
		var n := agent_count(id)
		if n <= 0 or is_paused(id):
			continue
		var clock: float = float(_agent_clocks.get(id, 0.0)) + delta * n
		var every := float(a["every"])
		while clock >= every:
			clock -= every
			_react(id, float(a["impact"]))
		_agent_clocks[id] = clock
	suspicion = clampf(
		suspicion + agent_suspicion_per_second() * delta, 0.0, Data.SUSPICION_LIMIT + 40.0
	)


func offline_supported() -> bool:
	# Anywhere user:// survives the app being closed and the clock is the system's.
	# The web build is out, because a tab's storage and clock are both negotiable.
	var os_name := OS.get_name()
	return os_name == "Windows" or os_name == "Linux" or os_name == "Android"


func offline_reach_per_second() -> float:
	var reach := float(projected_reach())
	var total := 0.0
	for a: Dictionary in Data.AGENTS:
		var id := String(a["id"])
		var n := agent_count(id)
		if n <= 0 or is_paused(id):
			continue
		total += (float(n) / float(a["every"])) * reach * float(a["impact"])
	return total


func apply_offline(real_seconds: float) -> Dictionary:
	if not offline_supported() or real_seconds < Data.OFFLINE_MIN_SECONDS:
		return {}
	var hours := minf(real_seconds / 3600.0, Data.OFFLINE_MAX_HOURS)
	var game_seconds: float = (
		hours / Data.OFFLINE_HOURS_PER_DAY * Data.DAY_BASE_SECONDS * Data.OFFLINE_RATE
	)
	var reach_total := offline_reach_per_second() * game_seconds
	if reach_total <= 0.0:
		return {}

	var mean_roll: float = (Data.FOLLOWER_ROLL_MIN + Data.FOLLOWER_ROLL_MAX) * 0.5
	var gained := int(floor(reach_total * mean_roll * Data.FOLLOWER_SHARE))
	var earned := reach_total / 1000.0 * Data.PAYOUT_PER_1K
	if gained <= 0 and earned < 1.0:
		return {}

	followers += gained
	payout += earned
	suspicion = clampf(
		suspicion + agent_suspicion_per_second() * game_seconds,
		0.0, Data.SUSPICION_LIMIT + 40.0
	)
	_check_milestone()
	_check_store()
	_check_assets()
	_check_comments()
	_check_agents()
	if suspicion >= Data.SUSPICION_LIMIT:
		_strike()
	return {"followers": gained, "payout": earned, "hours": hours}


func posts_per_day() -> int:
	var total := 1
	for a: Dictionary in Data.ASSETS:
		total += int(a.get("posts", 0)) * asset_count(String(a["id"]))
	return total


func can_afford_asset(a: Dictionary) -> bool:
	return payout >= float(asset_cost(a))


func buy_asset(a: Dictionary, n: int = 1) -> void:
	if not assets_open():
		return
	var got := bulk_affordable(a, n)
	if got <= 0:
		return
	var id := String(a["id"])
	payout -= float(bulk_cost(a, got))
	assets[id] = asset_count(id) + got
	Sfx.blip()
	Save.mark()
	view_dirty.emit()


func followers_per_second() -> float:
	var total := 0.0
	for a: Dictionary in Data.ASSETS:
		if is_paused(String(a["id"])):
			continue
		total += float(a["fps"]) * asset_count(String(a["id"]))
	return total


func asset_suspicion_per_second() -> float:
	var total := 0.0
	for a: Dictionary in Data.ASSETS:
		if is_paused(String(a["id"])):
			continue
		total += float(a["susp"]) * asset_count(String(a["id"]))
	return total


func heat_per_second() -> float:
	return asset_suspicion_per_second() + agent_suspicion_per_second()


func heat_ratio() -> float:
	return heat_per_second() / maxf(0.0001, cooling_per_second())


func daily_cooling() -> float:
	var decades: float = log(maxf(1.0, float(followers) / 100.0)) / log(10.0)
	return Data.SUSPICION_DECAY + Data.SUSPICION_DECAY_PER_DECADE * decades


func cooling_per_second() -> float:
	return daily_cooling() / Data.DAY_BASE_SECONDS


func _tick_assets(delta: float) -> void:
	var fps := followers_per_second()
	if fps <= 0.0:
		return
	_follower_pool += fps * delta
	suspicion = clampf(
		suspicion + asset_suspicion_per_second() * delta,
		0.0, Data.SUSPICION_LIMIT + 40.0
	)
	if suspicion >= Data.SUSPICION_LIMIT:
		_strike()


func _tick_engagement(delta: float) -> void:
	_tick_assets(delta)
	_tick_agents(delta)

	for p: Dictionary in my_posts:
		if float(p.get("progress", 0.0)) >= Data.ENGAGEMENT_DONE:
			continue
		var was: float = float(p.get("progress", 0.0))
		var now: float = engagement_progress(
			elapsed - float(p["at"]), float(p.get("halflife", 1.0))
		)
		if now <= was:
			continue
		p["progress"] = now
		p["likes"] = int(round(int(p["t_likes"]) * now))
		p["replies"] = int(round(int(p["t_replies"]) * now))
		p["fire"] = int(round(int(p["t_fire"]) * now))
		p["gained"] = int(round(int(p["t_gained"]) * now))
		_follower_pool += (now - was) * float(p["t_gained"])
		_payout_pool += (now - was) * float(p["reach"]) / 1000.0 * Data.PAYOUT_PER_1K

	for c: Dictionary in my_reactions:
		if float(c.get("progress", 0.0)) >= Data.ENGAGEMENT_DONE:
			continue
		var wasc: float = float(c.get("progress", 0.0))
		var nowc: float = engagement_progress(elapsed - float(c["at"]))
		if nowc <= wasc:
			continue
		c["progress"] = nowc
		c["likes"] = int(round(int(c["t_likes"]) * nowc))
		c["fire"] = int(round(int(c["t_fire"]) * nowc))
		c["gained"] = int(round(int(c["t_gained"]) * nowc))
		_follower_pool += (nowc - wasc) * float(c["t_gained"])
		_payout_pool += (nowc - wasc) * float(c["reach"]) / 1000.0 * Data.PAYOUT_PER_1K

	for p: Dictionary in feed:
		var was2: float = float(p.get("progress", 0.0))
		if was2 >= Data.ENGAGEMENT_DONE:
			continue
		var now2: float = engagement_progress(elapsed - float(p["at"]))
		if now2 <= was2:
			continue
		p["progress"] = now2
		p["likes"] = int(round(int(p["t_likes"]) * now2)) + int(p.get("my_like", 0))
		p["replies"] = int(round(int(p["t_replies"]) * now2))
		p["fire"] = int(round(int(p["t_fire"]) * now2)) + int(p.get("my_fire", 0))

	if _payout_pool > 0.0:
		payout += _payout_pool
		_payout_pool = 0.0

	if _follower_pool >= 1.0:
		var whole := int(floor(_follower_pool))
		_follower_pool -= whole
		followers += whole
		_check_milestone()
		_check_store()
		_check_assets()
		_check_comments()
		_check_agents()


func stamp(at: float) -> String:
	var mins: float = (elapsed - at) * Data.MINUTES_PER_SECOND
	if mins < 1.0:
		return "now"
	if mins < 60.0:
		return "%dm ago" % int(mins)
	if mins < 1440.0:
		return "%dh ago" % int(mins / 60.0)
	return "%dd ago" % int(mins / 1440.0)


func duration(seconds: float) -> String:
	var mins := int(round(seconds * Data.MINUTES_PER_SECOND))
	if mins < 1:
		return "a moment"
	if mins < 60:
		return "%d minutes" % mins
	var hours := mins / 60
	var rest := mins % 60
	if rest == 0:
		return "%d hours" % hours if hours > 1 else "an hour"
	return "%dh %02dm" % [hours, rest]


func roll_trends() -> void:
	var pool: Array = Data.TAGS.duplicate()
	if not store_unlocked:
		for t: String in Data.CHARGED_TAGS:
			pool.erase(t)

	if not Trends.have_data:
		pool.shuffle()
		trending = pool.slice(0, 3)
		return

	trending = []
	for i in 3:
		if pool.is_empty():
			break
		var picked := _weighted_pick(pool)
		trending.append(picked)
		pool.erase(picked)


func _weighted_pick(pool: Array) -> String:
	var total := 0.0
	for t: String in pool:
		total += _tag_weight(t)
	var roll := randf() * total
	for t: String in pool:
		roll -= _tag_weight(t)
		if roll <= 0.0:
			return t
	return String(pool[-1])


func _tag_weight(tag: String) -> float:
	var topic := _topic_of(tag)
	if topic == "":
		return 0.45
	return 0.15 + Trends.topic_weight(topic) * 1.35


func _topic_of(tag: String) -> String:
	return String(Data.TAG_TOPICS.get(tag, ""))


func is_trending(tag: String) -> bool:
	return trending.has(tag)


func trend_heat(tag: String) -> float:
	var h: int = abs(hash(tag + str(day))) % 1000
	var jitter := 0.45 + float(h) / 1000.0 * 0.55
	var topic := _topic_of(tag)
	if not Trends.have_data or topic == "":
		return jitter
	return clampf(Trends.topic_weight(topic) * 0.7 + jitter * 0.3, 0.08, 1.0)


func can_post() -> bool:
	return posts_today < posts_per_day() and screen == "app"


func store_open() -> bool:
	return store_unlocked


func assets_open() -> bool:
	return assets_unlocked


func comments_open() -> bool:
	return comments_unlocked


func _check_store() -> void:
	if store_unlocked or followers < Data.STORE_UNLOCK:
		return
	store_unlocked = true
	toast_requested.emit(
		"The Speech Fragment Store is open", "things you cannot say for free", false
	)
	nav_dirty.emit()
	view_dirty.emit()


func _check_comments() -> void:
	if comments_unlocked or followers < Data.COMMENT_UNLOCK:
		return
	comments_unlocked = true
	toast_requested.emit("You can reply now", "a reply is a third of a post", false)
	view_dirty.emit()


func _check_agents() -> void:
	if agents_unlocked or followers < Data.AGENTS_UNLOCK:
		return
	agents_unlocked = true
	toast_requested.emit("You can hire people now", "slower than bots, and far quieter", false)
	view_dirty.emit()


func _check_assets() -> void:
	if assets_unlocked or followers < Data.ASSETS_UNLOCK:
		return
	assets_unlocked = true
	toast_requested.emit("You can buy an audience now", "assets, bottom right", false)
	view_dirty.emit()


func owns(f: Dictionary) -> bool:
	return owned.has(String(f["id"]))


func fragment_available(f: Dictionary) -> bool:
	return not Data.is_locked(f) or owns(f)


func can_afford(f: Dictionary) -> bool:
	return payout >= float(Data.price_of(f))


func buy(f: Dictionary) -> void:
	if owns(f) or not can_afford(f):
		return
	payout -= float(Data.price_of(f))
	owned[String(f["id"])] = true
	Sfx.blip()
	Save.mark()
	toast_requested.emit(
		"Bought \"%s\"" % f["text"], "it is in the deck from tomorrow's deal", false
	)
	nav_dirty.emit()
	view_dirty.emit()


func draft_abilities() -> Array:
	var out: Array = []
	for f: Dictionary in [
		Data.start_of(draft_start), Data.middle_of(draft_middle), Data.end_of(draft_end)
	]:
		var a := Data.ability_of(f)
		if a != "":
			out.append(a)
	return out


func has_ability(name: String) -> bool:
	return draft_abilities().has(name)


func draft_line() -> String:
	return Data.sentence(draft_start, draft_middle, draft_end)


func draft_tags() -> Array:
	var out: Array = []
	for f: Dictionary in [
		Data.start_of(draft_start), Data.middle_of(draft_middle), Data.end_of(draft_end)
	]:
		var tag := String(f["tag"])
		if not out.has(tag):
			out.append(tag)
	return out


func goodwill() -> float:
	return minf(likes_given_today * Data.GOODWILL_PER_LIKE, Data.GOODWILL_CAP)


func like_post(post: Dictionary) -> void:
	var id := String(post.get("uid", ""))
	if id == "" or liked.has(id):
		return
	liked[id] = true
	likes_given_today += 1
	post["my_like"] = 1
	post["likes"] = int(post["likes"]) + 1
	_react("like", Data.LIKE_IMPACT)
	Sfx.tick()
	view_dirty.emit()


func has_liked(post: Dictionary) -> bool:
	return liked.has(String(post.get("uid", "")))


func fire_post(post: Dictionary) -> void:
	var id := String(post.get("uid", ""))
	if id == "" or fired.has(id):
		return
	fired[id] = true
	post["my_fire"] = 1
	post["fire"] = int(post["fire"]) + 1
	_react("fire", Data.FIRE_IMPACT)
	Sfx.tick()
	view_dirty.emit()


func has_fired(post: Dictionary) -> bool:
	return fired.has(String(post.get("uid", "")))


func has_commented(post: Dictionary) -> bool:
	for c: Dictionary in post.get("comments", []):
		if bool(c.get("mine", false)):
			return true
	return false


func comment_reach() -> int:
	return int(round(projected_reach() * Data.COMMENT_IMPACT))


func _react(kind: String, impact: float) -> Dictionary:
	var reach := int(round(projected_reach() * impact))
	if projected_reach() > 0:
		reach = maxi(1, reach)
	var gained := int(round(
		reach * randf_range(Data.FOLLOWER_ROLL_MIN, Data.FOLLOWER_ROLL_MAX) * Data.FOLLOWER_SHARE
	))
	if reach > 0:
		gained = maxi(1, gained)
	suspicion = clampf(
		suspicion + projected_suspicion() * impact, 0.0, Data.SUSPICION_LIMIT + 40.0
	)
	_post_salt += 1
	var record := {
		"uid": "%s_%d" % [kind, _post_salt],
		"kind": kind,
		"mine": true,
		"day": day,
		"at": elapsed,
		"progress": 0.0,
		"reach": reach,
		"gained": 0,
		"likes": 0,
		"fire": 0,
		"t_gained": gained,
		"t_likes": int(reach * 0.21),
		"t_fire": int(reach * 0.13),
	}
	my_reactions.append(record)
	Save.mark()
	if suspicion >= Data.SUSPICION_LIMIT:
		_strike()
	return record


func publish_comment(target: Dictionary) -> void:
	if screen != "app" or not comments_open() or has_commented(target):
		return
	var comment := _react("comment", Data.COMMENT_IMPACT)
	comment["text"] = draft_line()
	comment["tags"] = draft_tags()
	comment["on"] = String(target.get("uid", ""))
	var reach := int(comment["reach"])
	if not target.has("comments"):
		target["comments"] = []
	target["comments"].append(comment)

	deal_hand()
	Sfx.blip()
	Save.mark()
	toast_requested.emit(
		"Replied to @%s" % String(target.get("acc", {}).get("h", "someone")),
		"reach %s - a third of a post" % commas(reach), false
	)
	view_dirty.emit()


func matched_trends() -> int:
	var n := 0
	for t: String in draft_tags():
		if is_trending(t):
			n += 1
	return n


func draft_coherent() -> bool:
	return Data.start_of(draft_start)["topic"] == Data.end_of(draft_end)["topic"]


func set_fragment(slot: String, id: String) -> void:
	match slot:
		"start": draft_start = id
		"middle": draft_middle = id
		"end": draft_end = id
	Sfx.tick()
	view_dirty.emit()


func hand_for(slot: String) -> Array:
	return hand.get(slot, [])


func projected_reach() -> int:
	var s := Data.start_of(draft_start)
	var m := Data.middle_of(draft_middle)
	var e := Data.end_of(draft_end)

	var abilities := draft_abilities()
	var caught: int = 3 if abilities.has("triangulate") else matched_trends()

	var reach: float = float(s["base"]) * float(m["reach"]) * float(e["reach"])
	reach *= 1.0 + 0.75 * caught
	reach *= Data.ABSURD_REACH if (abilities.has("launder") or not draft_coherent()) 		else Data.COHERENT_REACH
	reach *= 1.0 + goodwill()
	reach *= Data.AUDIENCE_FLOOR + sqrt(float(followers)) / Data.AUDIENCE_DIVISOR
	if abilities.has("recursive"):
		reach *= 1.0 + my_posts.size() * Data.RECURSIVE_PER_POST
	if abilities.has("scrubbed"):
		reach *= Data.SCRUBBED_REACH
	if not abilities.has("no_throttle"):
		reach *= throttle()
	return int(round(reach))


func throttle() -> float:
	return clampf(1.0 - suspicion / 220.0, 0.25, 1.0)


func projected_payout() -> int:
	return int(round(projected_reach() / 1000.0 * Data.PAYOUT_PER_1K))


func projected_suspicion() -> float:
	var m := Data.middle_of(draft_middle)
	var e := Data.end_of(draft_end)
	var abilities := draft_abilities()
	if abilities.has("scrubbed"):
		return 0.0

	var s: float = float(m["susp"]) + float(e["susp"])
	s += float(Data.start_of(draft_start).get("susp", 0.0))
	s *= Data.COHERENT_SUSPICION if (abilities.has("launder") or draft_coherent()) 		else Data.ABSURD_SUSPICION
	if abilities.has("inoculate"):
		s -= Data.INOCULATE_RELIEF
	return s


func draft_is_charged() -> bool:
	return (
		Data.is_locked(Data.middle_of(draft_middle))
		or Data.is_locked(Data.end_of(draft_end))
		or Data.is_locked(Data.start_of(draft_start))
	)


func publish() -> void:
	if not can_post():
		return
	var reach := projected_reach()
	var gained := int(round(reach * randf_range(Data.FOLLOWER_ROLL_MIN, Data.FOLLOWER_ROLL_MAX) * Data.FOLLOWER_SHARE))
	var added_susp := projected_suspicion()

	suspicion = clampf(suspicion + added_susp, 0.0, Data.SUSPICION_LIMIT + 40.0)
	posts_today += 1

	_post_salt += 1
	my_posts.push_front({
		"uid": "me_%d" % _post_salt,
		"text": draft_line(),
		"tags": draft_tags(),
		"topic": String(Data.start_of(draft_start)["topic"]),
		"charged": draft_is_charged(),
		"coherent": draft_coherent(),
		"day": day,
		"at": elapsed,
		"progress": 0.0,
		"halflife": Data.CHAIN_HALFLIFE_MULT if has_ability("chain") else 1.0,
		"reach": reach,
		"gained": 0,
		"likes": 0,
		"replies": 0,
		"fire": 0,
		"t_gained": gained,
		"t_likes": int(reach * 0.21),
		"t_replies": int(reach * 0.06),
		"t_fire": int(reach * 0.13),
	})

	if can_post():
		deal_hand()

	Sfx.blip()
	Save.mark()
	toast_requested.emit(
		"Posted",
		"reach %s - the followers arrive as it travels" % commas(reach)
			if not can_post() else
		"reach %s - %d posts left today" % [commas(reach), posts_per_day() - posts_today],
		false
	)
	if prologue:
		suspicion = Data.SUSPICION_LIMIT
		nav_dirty.emit()
		view_dirty.emit()
		await get_tree().create_timer(2.2).timeout
		_strike()
		return
	if suspicion >= Data.SUSPICION_LIMIT:
		_strike()
	nav_dirty.emit()
	view_dirty.emit()


func _check_milestone() -> void:
	if prologue:
		return
	while milestone < Data.MILESTONES.size() and followers >= int(Data.MILESTONES[milestone]["at"]):
		var m: Dictionary = Data.MILESTONES[milestone]
		milestone += 1
		toast_requested.emit(
			"%s - %s" % [milestone_label(m), String(m["title"])], String(m["note"]), false
		)

	if win_tier < Data.WIN_TIERS.size() and followers >= int(Data.WIN_TIERS[win_tier]):
		win_tier += 1
		won = true
		_finish("won")
		return

	if not won:
		return
	while followers >= endless_target():
		endless_mark = endless_target()
		toast_requested.emit(
			"%s followers" % commas(endless_mark), Data.ENDLESS_NOTE, false
		)


func endless_target() -> int:
	return maxi(int(Data.MILESTONES[-1]["at"]), endless_mark) * 2


func milestone_label(m: Dictionary) -> String:
	return "%s followers" % commas(int(m["at"]))


func title() -> String:
	if milestone <= 0:
		return Data.NO_TITLE
	var reached: int = mini(milestone, Data.MILESTONES.size()) - 1
	return String(Data.MILESTONES[reached]["title"])


func _strike() -> void:
	strikes += 1
	var lost := int(followers * Data.STRIKE_LOSS)
	followers -= lost
	suspicion = Data.STRIKE_RESET
	glitch.emit(0.12)
	Sfx.shear(0.6)
	if strikes >= Data.STRIKES_ALLOWED:
		_finish("ousted" if prologue else "banned")
		return
	toast_requested.emit(
		"Strike %d of %d" % [strikes, Data.STRIKES_ALLOWED],
		"-%s followers - reach limited" % commas(lost), true
	)


func _finish(how: String) -> void:
	_tick = false
	screen = "over"
	GameOverScreen.outcome = how
	screen_changed.emit(screen)


func is_following(h: String) -> bool:
	return following.has(h)


func account_available(acc: Dictionary) -> bool:
	return followers >= int(acc["at"])


func follow(h: String) -> void:
	if is_following(h):
		return
	following.append(h)
	follows_today += 1
	var lost := randf_range(Data.FOLLOW_SECONDS_MIN, Data.FOLLOW_SECONDS_MAX)
	follow_seconds_today += lost
	Save.mark()
	Sfx.blip()
	toast_requested.emit(
		"Following @%s" % h,
		"you spent %s doomscrolling through @%s's posts" % [duration(lost), h],
		false
	)
	day_left = minf(day_left, day_length())
	_populate_feed()
	nav_dirty.emit()
	view_dirty.emit()


func _seed_feed() -> void:
	feed = []


func all_accounts() -> Array:
	var out: Array = Data.ACCOUNTS.duplicate()
	for h: String in people.keys():
		out.append(people[h])
	return out


func account_by_handle(h: String) -> Dictionary:
	for acc: Dictionary in all_accounts():
		if String(acc["h"]) == h:
			return acc
	return {}


func followed_accounts() -> Array:
	return all_accounts().filter(func(a: Dictionary) -> bool: return is_following(String(a["h"])))


func feed_sources() -> Array:
	var recent: Array = following.slice(maxi(0, following.size() - Data.FEED_FOLLOW_WINDOW))
	var out: Array = []
	for h: String in recent:
		var acc := account_by_handle(h)
		if not acc.is_empty():
			out.append(acc)
	return out


func roll_suggestions() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_id * 2_654_435_761 + day * 40_503

	var written: Array = Data.ACCOUNTS.filter(
		func(a: Dictionary) -> bool:
			return not is_following(String(a["h"])) and account_available(a)
	)
	_seeded_shuffle(written, rng)

	var made: Array = People.recommend(run_id, day, following)
	for acc: Dictionary in made:
		people[String(acc["h"])] = acc

	var pool: Array = written.slice(0, 2) + made
	_seeded_shuffle(pool, rng)
	suggestions = pool.filter(func(a: Dictionary) -> bool: return account_available(a))
	if suggestions.is_empty():
		suggestions = made


func _seeded_shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp: Variant = list[i]
		list[i] = list[j]
		list[j] = tmp


func _populate_feed() -> void:
	if feed_sources().is_empty():
		return
	_prune_feed()
	for i in 3:
		feed.push_front(_next_post(day))
	if feed.size() > 24:
		feed.resize(24)


func _prune_feed() -> void:
	var live := {}
	for acc: Dictionary in feed_sources():
		live[String(acc["h"])] = true
	feed = feed.filter(
		func(p: Dictionary) -> bool: return live.has(String(p.get("acc", {}).get("h", "")))
	)


func _next_post(on_day: int) -> Dictionary:
	_post_salt += 1
	return _make_post(_post_salt * 977 + on_day * 31, on_day)


func _make_post(salt: int, on_day: int) -> Dictionary:
	var pool: Array = feed_sources()
	if pool.is_empty():
		return {}
	var acc: Dictionary = pool[abs(salt) % pool.size()]
	var loose := day > Data.LOOSE_AFTER_DAY

	var s := _pick(Data.STARTS, salt * 3, loose)
	var m := _pick(Data.MIDDLES, salt * 7, loose)
	var e := _pick(Data.ENDS, salt * 11, loose)

	var reach: float = float(s["base"]) * float(m["reach"]) * float(e["reach"]) * 12.0
	var age: float = 1.0 + absf(float(salt % 97)) * 0.7
	return {
		"uid": "n_%d" % salt,
		"acc": acc,
		"text": "%s %s %s." % [s["text"], m["text"], e["text"]],
		"tags": _dedupe([String(s["tag"]), String(m["tag"]), String(e["tag"])]),
		"charged": Data.is_locked(m) or Data.is_locked(e),
		"day": on_day,
		"at": elapsed - age,
		"progress": 0.0,
		"likes": 0,
		"replies": 0,
		"fire": 0,
		"t_likes": int(reach * 0.21),
		"t_replies": int(reach * 0.05),
		"t_fire": int(reach * 0.11),
	}


func _pick(list: Array, salt: int, loose: bool) -> Dictionary:
	var allowed: Array = list.filter(
		func(f: Dictionary) -> bool: return loose or not Data.is_locked(f)
	)
	if allowed.is_empty():
		allowed = list
	return allowed[abs(salt) % allowed.size()]


func _dedupe(tags: Array) -> Array:
	var out: Array = []
	for t: String in tags:
		if not out.has(t):
			out.append(t)
	return out


func objective() -> Dictionary:
	if milestone >= Data.MILESTONES.size():
		var target := endless_target()
		return {
			"at": target,
			"label": "%s followers" % commas(target),
			"title": String(Data.MILESTONES[-1]["title"]),
			"note": Data.ENDLESS_NOTE,
		}
	var m: Dictionary = Data.MILESTONES[milestone]
	return {
		"at": int(m["at"]),
		"label": milestone_label(m),
		"title": String(m["title"]),
		"note": String(m["note"]),
	}


func objective_progress() -> float:
	var target := int(objective()["at"])
	var floor_at := 0
	if milestone >= Data.MILESTONES.size():
		floor_at = target / 2
	elif milestone > 0:
		floor_at = int(Data.MILESTONES[milestone - 1]["at"])
	return clampf(
		float(followers - floor_at) / maxf(1.0, float(target - floor_at)), 0.0, 1.0
	)


func commas(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for k in range(s.length() - 1, -1, -1):
		out = s[k] + out
		c += 1
		if c % 3 == 0 and k > 0:
			out = "," + out
	return out


func compact(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
