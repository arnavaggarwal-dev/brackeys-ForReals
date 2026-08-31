extends Node

const PATH := "user://forreals.save"
const VERSION := 2
const AUTOSAVE_SECONDS := 5.0
const HEARTBEAT_SECONDS := 60.0

var persistent := true
var _dirty := false
var _since := 0.0
var _heartbeat := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persistent = OS.is_userfs_persistent()
	if not persistent:
		push_warning("Save: user:// is not persistent on this platform")
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		write()
		get_tree().quit()
	elif (
		what == NOTIFICATION_WM_GO_BACK_REQUEST
		or what == NOTIFICATION_APPLICATION_FOCUS_OUT
		or what == NOTIFICATION_APPLICATION_PAUSED
	):
		write()


func _process(delta: float) -> void:
	if Game.screen == "app":
		_heartbeat += delta
		if _heartbeat >= HEARTBEAT_SECONDS:
			_heartbeat = 0.0
			write()
			return
	if not _dirty:
		return
	_since += delta
	if _since >= AUTOSAVE_SECONDS:
		write()


func mark() -> void:
	_dirty = true


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func clear() -> void:
	_dirty = false
	_since = 0.0
	if not FileAccess.file_exists(PATH):
		return
	DirAccess.remove_absolute(PATH)
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.WRITE)
		if f != null:
			f.store_string("")
			f.close()


func write() -> void:
	_dirty = false
	_since = 0.0
	_heartbeat = 0.0
	if Game.screen != "app":
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Save: could not open %s for writing" % PATH)
		return
	f.store_string(JSON.stringify(_snapshot()))
	f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	if text.strip_edges() == "":
		return false

	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != VERSION:
		return false
	_restore(data)
	return true


func _snapshot() -> Dictionary:
	return {
		"version": VERSION,
		"at_wall": Time.get_unix_time_from_system(),
		"run_id": Game.run_id,
		"post_salt": Game._post_salt,
		"handle": Game.handle,
		"avatar": Game.avatar,
		"day": Game.day,
		"day_left": Game.day_left,
		"elapsed": Game.elapsed,
		"posts_today": Game.posts_today,
		"followers": Game.followers,
		"following": Game.following,
		"follows_today": Game.follows_today,
		"follow_seconds_today": Game.follow_seconds_today,
		"suspicion": Game.suspicion,
		"strikes": Game.strikes,
		"milestone": Game.milestone,
		"won": Game.won,
		"win_tier": Game.win_tier,
		"endless_mark": Game.endless_mark,
		"payout": Game.payout,
		"owned": Game.owned,
		"store_unlocked": Game.store_unlocked,
		"assets_unlocked": Game.assets_unlocked,
		"comments_unlocked": Game.comments_unlocked,
		"assets": Game.assets,
		"paused": Game.paused,
		"agents": Game.agents,
		"agents_unlocked": Game.agents_unlocked,
		"bulk": Game.bulk,
		"likes_given_today": Game.likes_given_today,
		"liked": Game.liked,
		"fired": Game.fired,
		"people": Game.people,
		"suggestions": Game.suggestions,
		"reactions": Game.my_reactions.filter(
			func(r: Dictionary) -> bool: return String(r.get("kind", "")) != "comment"
		),
		"rerolls_left": Game.rerolls_left,
		"trending": Game.trending,
		"draft": [Game.draft_start, Game.draft_middle, Game.draft_end],
		"my_posts": Game.my_posts.map(_strip),
		"feed": Game.feed.map(_strip),
	}


func _strip(post: Dictionary) -> Dictionary:
	var out := post.duplicate(true)
	if out.has("acc") and not Game.account_by_handle(String(out["acc"]["h"])).is_empty():
		out["acc_h"] = String(out["acc"]["h"])
		out.erase("acc")
	return out


func _rehydrate(post: Dictionary) -> Dictionary:
	var out := post.duplicate(true)
	if out.has("acc_h"):
		var handle := String(out["acc_h"])
		var acc := Game.account_by_handle(handle)
		if acc.is_empty():
			acc = {"h": handle, "n": handle, "topic": "politics", "followers": 0, "at": 0}
		out["acc"] = acc
		out.erase("acc_h")
	return out


func _restore(d: Dictionary) -> void:
	Game.run_id = int(d.get("run_id", Game.run_id))
	Game._post_salt = int(d.get("post_salt", 0))
	Game.handle = String(d.get("handle", "someone"))
	Game.avatar = d.get("avatar", Data.AVATAR_CHOICES[0])
	Game.day = int(d.get("day", 1))
	Game.day_left = float(d.get("day_left", Data.DAY_BASE_SECONDS))
	Game.elapsed = float(d.get("elapsed", 0.0))
	Game.posts_today = int(d.get("posts_today", 0))
	Game.followers = int(d.get("followers", 0))
	Game.follows_today = int(d.get("follows_today", 0))
	Game.follow_seconds_today = float(d.get("follow_seconds_today", 0.0))
	Game.suspicion = float(d.get("suspicion", 0.0))
	Game.strikes = int(d.get("strikes", 0))
	Game.milestone = int(d.get("milestone", 0))
	Game.won = bool(d.get("won", false))
	Game.win_tier = int(d.get("win_tier", 1 if Game.won else 0))
	Game.endless_mark = int(d.get("endless_mark", 0))
	Game.payout = float(d.get("payout", 0.0))
	Game.owned = d.get("owned", {})
	Game.store_unlocked = bool(d.get("store_unlocked", false))
	Game.assets_unlocked = bool(d.get("assets_unlocked", false))
	Game.comments_unlocked = bool(d.get("comments_unlocked", false))
	Game.assets = d.get("assets", {})
	Game.paused = d.get("paused", {})
	Game.agents = d.get("agents", {})
	Game.agents_unlocked = bool(d.get("agents_unlocked", false))
	Game.bulk = int(d.get("bulk", 1))
	Game.likes_given_today = int(d.get("likes_given_today", 0))
	Game.liked = d.get("liked", {})
	Game.fired = d.get("fired", {})
	Game.people = d.get("people", {})
	Game.suggestions = d.get("suggestions", [])
	Game.rerolls_left = int(d.get("rerolls_left", Data.REROLLS_PER_DAY))
	Game.trending = d.get("trending", Game.trending)

	Game.following.clear()
	for h: String in d.get("following", []):
		Game.following.append(h)

	Game.my_posts = (d.get("my_posts", []) as Array).map(_rehydrate)
	Game.feed = (d.get("feed", []) as Array).map(_rehydrate)

	var away := Time.get_unix_time_from_system() - float(d.get("at_wall", 0.0))
	Game.offline_report = Game.apply_offline(away) if away > 0.0 else {}

	Game.my_reactions = []
	for r: Dictionary in d.get("reactions", []):
		Game.my_reactions.append(r)
	for post: Dictionary in Game.feed + Game.my_posts:
		for c: Dictionary in post.get("comments", []):
			if bool(c.get("mine", false)):
				Game.my_reactions.append(c)

	Game.deal_hand()
	var draft: Array = d.get("draft", [])
	if draft.size() == 3:
		Game.draft_start = String(draft[0])
		Game.draft_middle = String(draft[1])
		Game.draft_end = String(draft[2])
