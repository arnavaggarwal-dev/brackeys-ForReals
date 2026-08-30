class_name DevTour
extends RefCounted

static func enabled() -> bool:
	return OS.get_cmdline_args().has("--tour")


static func nuke_only() -> bool:
	return OS.get_cmdline_args().has("--nuke")


static func shots_only() -> bool:
	return OS.get_cmdline_args().has("--shots")


static func balance_only() -> bool:
	return OS.get_cmdline_args().has("--balance")


const BALANCE_RUNS := 7
const BALANCE_MAX_DAYS := 400
const BALANCE_REACTS := 3.0


static func run_balance() -> void:
	print("BALANCE: %d runs, win at %s followers, day = %ds" % [
		BALANCE_RUNS, Game.commas(Data.WIN_FOLLOWERS), int(Data.DAY_BASE_SECONDS)
	])

	var shell := AppShell.i
	if Game.view_dirty.is_connected(shell._on_view_dirty):
		Game.view_dirty.disconnect(shell._on_view_dirty)
	if Game.nav_dirty.is_connected(shell._on_view_dirty):
		Game.nav_dirty.disconnect(shell._on_view_dirty)
	if Game.toast_requested.is_connected(shell.show_toast):
		Game.toast_requested.disconnect(shell.show_toast)
	if Game.screen_changed.is_connected(shell._on_screen):
		Game.screen_changed.disconnect(shell._on_screen)
	if Game.glitch.is_connected(shell.shake):
		Game.glitch.disconnect(shell.shake)

	var wins: Array[int] = []
	var banned := 0
	for r in BALANCE_RUNS:
		var out := _simulate(r)
		if String(out["how"]) == "won":
			wins.append(int(out["days"]))
		else:
			banned += 1
		var pace: Dictionary = out["pace"]
		var marks := PackedStringArray()
		for at: int in [100, 600, 3000, 5000]:
			marks.append("%s@d%s" % [Game.compact(at), str(pace.get(at, "-"))])
		print("  run %d: %-6s day %3d  %8s followers  %d strikes   %s" % [
			r + 1, out["how"], int(out["days"]),
			Game.commas(int(out["followers"])), int(out["strikes"]),
			" ".join(marks)
		])

	if wins.is_empty():
		print("BALANCE: no run reached the target - the economy is unwinnable")
		return
	wins.sort()
	var total := 0
	for d in wins:
		total += d
	var mean := float(total) / float(wins.size())
	print("BALANCE: won %d/%d - median day %d, mean %.1f" % [
		wins.size(), BALANCE_RUNS, wins[wins.size() / 2], mean
	])
	print("BALANCE: that is %.1f minutes of play at %ds a day" % [
		mean * Data.DAY_BASE_SECONDS / 60.0, int(Data.DAY_BASE_SECONDS)
	])
	if banned > 0:
		print("BALANCE: %d run(s) hit three strikes first" % banned)


static func _simulate(seed_index: int) -> Dictionary:
	Game.reset()
	Game.run_id = seed_index * 31 + 7
	Game.screen = "app"
	Game.followers = 2
	Game.suspicion = 0.0
	Game.strikes = 0
	var mean_roll: float = (Data.FOLLOWER_ROLL_MIN + Data.FOLLOWER_ROLL_MAX) * 0.5
	var strikes := 0
	var pace: Dictionary = {}

	for day in range(1, BALANCE_MAX_DAYS + 1):
		Game.day = day
		Game.posts_today = 0
		Game.likes_given_today = int(BALANCE_REACTS)
		Game.roll_trends()
		Game.deal_hand()
		_best_draft()

		var posts := Game.posts_per_day()
		var reach := float(Game.projected_reach())
		var susp := Game.projected_suspicion()

		var earned := reach * float(posts)
		var heat := susp * float(posts)

		var frac := Data.LIKE_IMPACT + Data.FIRE_IMPACT
		if Game.comments_open():
			frac += Data.COMMENT_IMPACT
		frac *= BALANCE_REACTS
		var room: float = Data.SUSPICION_LIMIT - Game.suspicion - heat
		if susp * frac > room:
			frac = maxf(0.0, room / maxf(0.01, susp))
		earned += reach * frac
		heat += susp * frac

		Game.followers += int(earned * mean_roll * Data.FOLLOWER_SHARE)
		Game.payout += earned / 1000.0 * Data.PAYOUT_PER_1K

		Game.followers += int(Game.followers_per_second() * Data.DAY_BASE_SECONDS)
		heat += Game.heat_per_second() * Data.DAY_BASE_SECONDS

		Game.suspicion = maxf(0.0, Game.suspicion + heat - Game.daily_cooling())
		if Game.suspicion >= Data.SUSPICION_LIMIT:
			strikes += 1
			Game.followers = int(Game.followers * (1.0 - Data.STRIKE_LOSS))
			Game.suspicion = Data.STRIKE_RESET
			if strikes >= Data.STRIKES_ALLOWED:
				return {
					"how": "banned", "days": day,
					"followers": Game.followers, "strikes": strikes, "pace": pace,
				}

		Game._check_store()
		Game._check_comments()
		Game._check_assets()
		Game._check_agents()
		_buy_greedy()

		for m: Dictionary in Data.MILESTONES:
			var at := int(m["at"])
			if at <= Data.WIN_FOLLOWERS and Game.followers >= at and not pace.has(at):
				pace[at] = day

		if Game.followers >= Data.WIN_FOLLOWERS:
			return {
				"how": "won", "days": day,
				"followers": Game.followers, "strikes": strikes, "pace": pace,
			}

	return {
		"how": "stalled", "days": BALANCE_MAX_DAYS,
		"followers": Game.followers, "strikes": strikes, "pace": pace,
	}


static func _best_draft() -> void:
	var headroom: float = Data.SUSPICION_LIMIT - Game.suspicion

	var spend_mult := float(Game.posts_per_day())
	spend_mult += (Data.LIKE_IMPACT + Data.FIRE_IMPACT) * BALANCE_REACTS
	if Game.comments_open():
		spend_mult += Data.COMMENT_IMPACT * BALANCE_REACTS

	var asset_heat: float = Game.heat_per_second() * Data.DAY_BASE_SECONDS
	var budget: float = maxf(0.0, Game.daily_cooling() - asset_heat + headroom * 0.02)
	budget /= maxf(0.5, spend_mult)

	var best := -1.0
	var pick := ["", "", ""]
	var safest := 1e9
	var fallback := ["", "", ""]

	for s: Dictionary in Game.hand_for("start"):
		for m: Dictionary in Game.hand_for("middle"):
			for e: Dictionary in Game.hand_for("end"):
				Game.set_fragment("start", String(s["id"]))
				Game.set_fragment("middle", String(m["id"]))
				Game.set_fragment("end", String(e["id"]))
				var sp := Game.projected_suspicion()
				var r := float(Game.projected_reach())
				var ids := [String(s["id"]), String(m["id"]), String(e["id"])]
				if sp < safest:
					safest = sp
					fallback = ids
				if sp <= budget and r > best:
					best = r
					pick = ids

	if best < 0.0:
		pick = fallback
	Game.set_fragment("start", pick[0])
	Game.set_fragment("middle", pick[1])
	Game.set_fragment("end", pick[2])


static func _buy_greedy() -> void:
	for pass_i in 8:
		var best: Dictionary = {}
		var best_eff := 0.0
		if Game.assets_open():
			for a: Dictionary in Data.ASSETS:
				if not Game.can_afford_asset(a) or float(a["susp"]) <= 0.0:
					continue
				var fps := float(a.get("fps", 0.0))
				if fps <= 0.0:
					continue
				var eff := fps / float(a["susp"])
				if eff > best_eff:
					best_eff = eff
					best = a
		if best.is_empty():
			return
		if Game.heat_ratio() > 0.60:
			return
		Game.buy_asset(best, 1)


const SHOT_DIR := "res://itchpush/screenshots"
const SHOT_SIZE := Vector2i(1664, 936)


static func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := AppShell.i.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var path := "%s/%s.png" % [SHOT_DIR, name]
	if img.save_png(path) != OK:
		push_error("SHOTS: could not write %s" % path)
		return
	print("SHOT: %s  %dx%d" % [name, img.get_width(), img.get_height()])


static func run_shots() -> void:
	var tree := AppShell.i.get_tree()
	Prefs.set_v("tutorial_seen", true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(SHOT_SIZE)
	await tree.create_timer(0.6).timeout

	Game.begin("skibiditoilet", Data.AVATAR_CHOICES[4])
	Game.day = 6
	Game.followers = 1_284
	Game.payout = 780.0
	Game._check_store()
	Game._check_comments()
	for h: String in [
		"morning_kate", "boxscore_pete", "lab_notes", "frontline_map", "policywonk"
	]:
		Game.follow(h)
	Game.day_left = Data.DAY_BASE_SECONDS
	Game._populate_feed()
	Game.deal_hand()

	Game.owned = {"caused": true, "hiding": true, "leak": true}
	for i in 4:
		Game.posts_today = 0
		Game.deal_hand()
		Game.set_fragment("start", String(Game.hand_for("start")[i % 4]["id"]))
		Game.set_fragment("middle", String(Game.hand_for("middle")[(i + 1) % 4]["id"]))
		Game.set_fragment("end", String(Game.hand_for("end")[(i + 2) % 4]["id"]))
		Game.publish()
		await tree.create_timer(1.2).timeout
	await tree.create_timer(3.0).timeout
	Game.view_dirty.emit()
	await _snap("01-desktop")

	Tutorial.start()
	await tree.create_timer(0.8).timeout
	await _snap("06-tutorial")
	Tutorial.stop()
	await tree.create_timer(0.4).timeout

	Game.posts_today = 0
	Game.deal_hand()
	Composer.open()
	await tree.create_timer(0.4).timeout
	Game.set_fragment("start", String(Game.hand_for("start")[0]["id"]))
	Game.set_fragment("middle", String(Game.hand_for("middle")[1]["id"]))
	Game.set_fragment("end", String(Game.hand_for("end")[2]["id"]))
	Composer.refresh()
	await tree.create_timer(0.8).timeout
	await _snap("02-composer")
	Composer.close()
	await tree.create_timer(0.4).timeout

	Store.open()
	await tree.create_timer(0.8).timeout
	await _snap("03-store")
	Store.close()
	await tree.create_timer(0.4).timeout

	Game.followers = 4_180
	Game.payout = 1_460.0
	Game.assets = {"burner": 6, "farm": 4, "pod": 2, "scheduler": 1}
	Game.agents = {"intern": 3, "stringer": 1}
	Game.assets_unlocked = true
	Game.agents_unlocked = true
	Game.suspicion = 64.0
	Game.strikes = 1
	Game.posts_today = 1
	Game.milestone = 7
	Game.view_dirty.emit()
	Game.glitch.emit(0.45)
	await tree.create_timer(1.0).timeout
	await _snap("04-heat")

	Game.followers = Data.WIN_FOLLOWERS
	Game.milestone = 8
	Game.won = true
	Game._finish("won")
	await tree.create_timer(1.2).timeout
	await _snap("05-ending")

	print("SHOTS: five written to %s" % SHOT_DIR)
	await tree.create_timer(0.5).timeout
	tree.quit()


static func run_nuke() -> void:
	Game.begin("tester", Data.AVATAR_CHOICES[0])
	await AppShell.i.get_tree().create_timer(0.5).timeout
	StartMenu.show_menu()
	await AppShell.i.get_tree().create_timer(2.0).timeout
	StartMenu.close()
	NukeScreen.play()


static func click(node: Control) -> void:
	var tree := AppShell.i.get_tree()
	await tree.process_frame
	if not is_instance_valid(node):
		push_error("TOUR: the button vanished before it could be clicked")
		return
	var at := node.get_global_rect().get_center()
	var over: Control = null
	for attempt in 12:
		if not is_instance_valid(node):
			push_error("TOUR: the button vanished while aiming at it")
			return
		at = node.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = at
		motion.global_position = at
		tree.root.push_input(motion, true)
		await tree.process_frame
		over = AppShell.i.get_viewport().gui_get_hovered_control()
		if over == node or node.is_ancestor_of(over):
			break
	if over != node and not node.is_ancestor_of(over):
		push_error("TOUR: point %s is covered by %s (%s), wanted %s" % [
			at, over, over.get_class() if over else "nothing", node
		])

	for pressed in [true, false]:
		if not is_instance_valid(node):
			push_error("TOUR: the button was destroyed mid-click - the view is rebuilding under the pointer")
			return
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		tree.root.push_input(e, true)
		await tree.process_frame


static func find_named(root: Node, name: String) -> Tappable:
	if root is Tappable and String(root.name) == name:
		return root
	for c in root.get_children():
		var hit := find_named(c, name)
		if hit != null:
			return hit
	return null


static func find_button(root: Node, text: String) -> Tappable:
	if root is Tappable and _has_text(root, text):
		return root
	for c in root.get_children():
		var hit := find_button(c, text)
		if hit != null:
			return hit
	return null


static func _has_text(root: Node, text: String) -> bool:
	if root is Label and String(root.text).findn(text) >= 0:
		return true
	for c in root.get_children():
		if _has_text(c, text):
			return true
	return false


static func _check_titles_and_win() -> void:
	var tree := AppShell.i.get_tree()
	if int(Data.MILESTONES[-1]["at"]) != 1_000_000_000:
		push_error("TOUR: the ladder stops at %d, not a billion" % int(Data.MILESTONES[-1]["at"]))
	var last := 0
	for m: Dictionary in Data.MILESTONES:
		if String(m.get("title", "")) == "":
			push_error("TOUR: the milestone at %d has no title" % int(m["at"]))
		if int(m["at"]) <= last:
			push_error("TOUR: the ladder is not ascending at %d" % int(m["at"]))
		last = int(m["at"])

	Game.followers = 0
	Game.milestone = 0
	Game.won = false
	Game.endless_mark = 0
	if Game.title() != Data.NO_TITLE:
		push_error("TOUR: you start the run as '%s', not nobody" % Game.title())
	Game.followers = 25
	Game._check_milestone()
	if Game.title() != "bud":
		push_error("TOUR: 25 followers made you '%s', not a bud" % Game.title())
	else:
		print("TOUR: 25 followers makes you a bud, %d ranks to a billion" % Data.MILESTONES.size())

	Game.followers = Data.WIN_FOLLOWERS
	Game._check_milestone()
	await tree.create_timer(0.8).timeout
	if not Game.won or Game.screen != "over":
		push_error("TOUR: %d followers did not win the run (screen=%s)" % [
			Data.WIN_FOLLOWERS, Game.screen
		])
		return
	print("TOUR: %s followers wins the run as '%s'" % [
		Game.commas(Game.followers), Game.title()
	])

	var stay := find_button(AppShell.i, "Keep the account")
	if stay == null:
		push_error("TOUR: the ending offers no way back into the run")
		return
	await click(stay)
	await tree.create_timer(0.8).timeout
	if Game.screen != "app":
		push_error("TOUR: Keep the account did not resume (screen=%s)" % Game.screen)
		return
	print("TOUR: the win is a door, not a wall - the run carries on")

	var before := int(Game.objective()["at"])
	Game.followers = 10_000
	Game._check_milestone()
	if int(Game.objective()["at"]) <= before:
		push_error("TOUR: the objective did not advance past the win")
	else:
		print("TOUR: next up %s - %s" % [
			String(Game.objective()["label"]), String(Game.objective()["title"])
		])


static func _check_offline() -> void:
	if not Game.offline_supported():
		print("TOUR: offline earnings are off on %s, as intended" % OS.get_name())
		return

	Game.agents = {"intern": 4}
	Game.paused = {}
	Game._agent_clocks = {}
	var before := Game.followers
	var away: Dictionary = Game.apply_offline(4.0 * 3600.0)
	if away.is_empty() or Game.followers <= before:
		push_error("TOUR: four hours away with four interns earned nothing")
	else:
		print("TOUR: four hours away earned %s followers and £%d on %s" % [
			Game.commas(int(away["followers"])), int(away["payout"]), OS.get_name()
		])

	if not Game.apply_offline(30.0).is_empty():
		push_error("TOUR: half a minute away paid out")
	if not Game.apply_offline(-5_000.0).is_empty():
		push_error("TOUR: a clock running backwards paid out")

	var capped: Dictionary = Game.apply_offline(400.0 * 3600.0)
	if not capped.is_empty() and float(capped["hours"]) > Data.OFFLINE_MAX_HOURS:
		push_error("TOUR: offline earnings are not capped at %d hours" % int(Data.OFFLINE_MAX_HOURS))
	else:
		print("TOUR: a fortnight away still only pays %d hours" % int(Data.OFFLINE_MAX_HOURS))
	Game.agents = {}
	Game._agent_clocks = {}


static func _check_menu_at_signin() -> void:
	var tree := AppShell.i.get_tree()
	Game.reset()
	SignInScreen.show_signin()
	await tree.create_timer(0.5).timeout
	if find_button(AppShell.i, "community guidelines") == null:
		push_error("TOUR: sign-in did not come up")
		return

	StartMenu.show_menu()
	await tree.create_timer(0.5).timeout
	if not StartMenu.is_open():
		push_error("TOUR: the Start menu will not open at the sign-in screen")
		return
	if find_button(AppShell.i, "Quit") == null:
		push_error("TOUR: no way to quit from the sign-in screen")
		return
	if find_button(AppShell.i, "community guidelines") == null:
		push_error("TOUR: opening the Start menu destroyed the sign-in screen")
		return
	print("TOUR: the Start menu opens over sign-in without eating it")

	StartMenu.close()
	await tree.create_timer(0.4).timeout
	if StartMenu.is_open():
		push_error("TOUR: the Start menu would not close")
	if find_button(AppShell.i, "community guidelines") == null:
		push_error("TOUR: closing the Start menu took sign-in with it")


static func _check_tutorial() -> void:
	var tree := AppShell.i.get_tree()
	Prefs.set_v("tutorial_seen", false)
	if Tutorial.seen():
		push_error("TOUR: the tutorial thinks it has been seen already")
	Tutorial.start()
	await tree.create_timer(0.6).timeout
	if not Tutorial.is_open():
		push_error("TOUR: the tutorial would not open")
		return
	if find_button(AppShell.i, "Skip") == null:
		push_error("TOUR: the tutorial cannot be skipped")
		return

	var steps := Tutorial.STEPS.size()
	for i in steps - 1:
		var nxt := find_button(AppShell.i, "Next")
		if nxt == null:
			nxt = find_button(AppShell.i, "Got it")
		if nxt == null:
			push_error("TOUR: the tutorial stalled on step %d of %d" % [i + 1, steps])
			return
		await click(nxt)
		await tree.create_timer(0.35).timeout

	var last := find_button(AppShell.i, "Got it")
	if last == null:
		push_error("TOUR: the last tutorial step has no way out")
		return
	await click(last)
	await tree.create_timer(0.4).timeout
	if Tutorial.is_open():
		push_error("TOUR: the tutorial would not close")
		return
	if not Tutorial.seen():
		push_error("TOUR: finishing the tutorial did not remember it")
		return
	print("TOUR: the tutorial walks %d steps and remembers it is done" % steps)


static func _check_fonts() -> void:
	var was := Style.face
	var nxt := Style.next_face()
	if nxt == was:
		push_error("TOUR: there is only one font to switch between")
		return
	Style.set_face(nxt)
	if Style.face != nxt or Style.ui_r == null:
		push_error("TOUR: switching to %s did not take" % nxt)
	else:
		print("TOUR: font switches to '%s'" % Style.face_name())
	Style.set_face(was)


static func _check_save() -> void:
	Save.write()
	if not Save.has_save():
		push_error("TOUR: nothing was written to %s" % Save.PATH)
		return

	var want := {
		"handle": Game.handle,
		"followers": Game.followers,
		"payout": int(Game.payout),
		"day": Game.day,
		"posts": Game.my_posts.size(),
		"burners": Game.asset_count("burner"),
		"owned": Game.owned.size(),
		"store": Game.store_unlocked,
		"shelf": Game.assets_unlocked,
	}

	Game.handle = "wiped"
	Game.followers = 0
	Game.payout = 0.0
	Game.day = 99
	Game.my_posts = []
	Game.assets = {}
	Game.owned = {}
	Game.store_unlocked = false
	Game.assets_unlocked = false

	if not Save.load_game():
		push_error("TOUR: the save would not load back")
		return

	var got := {
		"handle": Game.handle,
		"followers": Game.followers,
		"payout": int(Game.payout),
		"day": Game.day,
		"posts": Game.my_posts.size(),
		"burners": Game.asset_count("burner"),
		"owned": Game.owned.size(),
		"store": Game.store_unlocked,
		"shelf": Game.assets_unlocked,
	}
	for k: String in want.keys():
		if want[k] != got[k]:
			push_error("TOUR: save lost %s - wrote %s, read %s" % [k, want[k], got[k]])
			return
	if Game.my_posts.size() > 0 and not Game.my_posts[0].has("text"):
		push_error("TOUR: restored posts are malformed")
		return
	for post: Dictionary in Game.feed:
		if not post.has("acc"):
			push_error("TOUR: a restored feed post lost its account")
			return
	print("TOUR: save survives a round trip (persistent=%s)" % Save.persistent)


static func _check_prologue() -> void:
	var tree := AppShell.i.get_tree()
	Game.begin_prologue()
	await tree.create_timer(0.8).timeout

	if not Game.prologue:
		push_error("TOUR: the prologue did not start")
		return
	if Game.strikes != Data.STRIKES_ALLOWED - 1:
		push_error("TOUR: act zero starts on %d strikes, wanted %d" % [
			Game.strikes, Data.STRIKES_ALLOWED - 1
		])
	if Game.suspicion < Data.SUSPICION_LIMIT * 0.8:
		push_error("TOUR: act zero starts too cold at %.0f" % Game.suspicion)
	if Game.feed.size() < 3:
		push_error("TOUR: act zero has no feed turning on you")
	if not Game.can_post():
		push_error("TOUR: act zero gives you no post to spend")

	Game.publish()
	await tree.create_timer(3.2).timeout
	if Game.screen != "over":
		push_error("TOUR: act zero survived a post - it is meant to be unwinnable")
		return
	if GameOverScreen.outcome != "ousted":
		push_error("TOUR: act zero ended as '%s'" % GameOverScreen.outcome)
		return
	print("TOUR: act zero ends the politician in one post")

	var out := find_button(AppShell.i, "Start again as nobody")
	if out == null:
		push_error("TOUR: no way out of act zero")
		return
	await click(out)
	await tree.create_timer(0.8).timeout
	if Game.prologue or Game.followers != 0:
		push_error("TOUR: rebirth kept the politician (%d followers)" % Game.followers)
	elif find_button(AppShell.i, "accept these terms") == null:
		push_error("TOUR: act zero did not hand over to the terms")
	else:
		print("TOUR: reborn as nobody, handed to the terms")
	Dialog.close()


static func _check_tos_flow() -> void:
	var tree := AppShell.i.get_tree()
	TosScreen._read = false
	TosScreen.show_tos()
	await tree.create_timer(0.6).timeout

	var vp := AppShell.i.get_viewport_rect()
	var agree := find_button(AppShell.i, "I Agree")
	if agree == null:
		push_error("TOUR: the terms have no I Agree button")
		return
	if not vp.encloses(agree.get_global_rect()):
		push_error("TOUR: I Agree is off-screen - the terms do not fit")
	if agree is Tappable and agree.is_enabled():
		push_error("TOUR: I Agree is live before the box is ticked")

	var box := find_button(AppShell.i, "accept these terms")
	if box == null:
		push_error("TOUR: the terms have no tick box")
		return
	if not vp.encloses(box.get_global_rect()):
		push_error("TOUR: the tick box is off-screen behind the document scroll")
	await click(box)
	await tree.create_timer(0.4).timeout
	if not TosScreen._read:
		push_error("TOUR: ticking the box did nothing")
		return

	var agree2 := find_button(AppShell.i, "I Agree")
	if agree2 == null:
		push_error("TOUR: I Agree vanished after ticking the box")
		return
	if agree2 is Tappable and not agree2.is_enabled():
		push_error("TOUR: I Agree is still dead after ticking the box")
	await click(agree2)
	await tree.create_timer(0.6).timeout
	if find_button(AppShell.i, "community guidelines") == null:
		push_error("TOUR: I Agree did not lead to sign-in")
	else:
		print("TOUR: the terms tick through to sign-in")


static func _check_tos() -> void:
	if not FileAccess.file_exists(TosScreen.PATH):
		push_error("TOUR: %s is not in the build" % TosScreen.PATH)
		return
	var doc := TosScreen._document()
	if doc == TosScreen.FALLBACK:
		push_error("TOUR: the terms fell back to the built-in text")
		return
	var page := Md.render(doc)
	if page.get_child_count() < 4:
		push_error("TOUR: the terms rendered to %d blocks" % page.get_child_count())
	else:
		print("TOUR: terms of service render to %d blocks" % page.get_child_count())
	page.queue_free()


static func _check_toast() -> void:
	var tree := AppShell.i.get_tree()
	Game.toast_requested.emit(
		"Following @morning_kate", "you spent 1h 50m doomscrolling through @morning_kate's posts", false
	)
	await tree.process_frame
	await tree.process_frame
	var layer := AppShell.i.toast_layer
	if layer.get_child_count() == 0:
		push_error("TOUR: the toast did not appear")
		return
	var box := layer.get_child(layer.get_child_count() - 1) as Control
	var vp := AppShell.i.get_viewport_rect()
	var r := box.get_global_rect()
	if not vp.encloses(r):
		push_error("TOUR: a toast at %.2fx spills outside the screen - %s in %s" % [
			AppShell.TOAST_SCALE, r, vp
		])
	else:
		print("TOUR: toasts fit on screen at %.2fx (%.0fx%.0f)" % [
			AppShell.TOAST_SCALE, r.size.x, r.size.y
		])


static func _check_menu() -> void:
	var tree := AppShell.i.get_tree()
	Dialog.close()
	SignInScreen._start()
	await tree.create_timer(0.6).timeout
	Save.write()
	if not Save.has_save():
		push_error("TOUR: no save to nuke")
		return

	var start := find_button(AppShell.i, "Start")
	if start == null:
		push_error("TOUR: no Start button on the taskbar")
		return
	await click(start)
	await tree.create_timer(0.5).timeout
	if not StartMenu.is_open():
		push_error("TOUR: clicking Start did not open the menu")
		return

	var was := Sfx.muted
	var sound := find_button(AppShell.i, "Sound:")
	var had_sound := sound != null
	if sound == null:
		push_error("TOUR: the menu has no sound toggle")
	else:
		await click(sound)
		await tree.create_timer(0.4).timeout
		if Sfx.muted == was:
			push_error("TOUR: the sound toggle did not flip")
		elif not FileAccess.file_exists(Sfx.PREFS):
			push_error("TOUR: the sound setting was not written to %s" % Sfx.PREFS)
		else:
			print("TOUR: sound toggles to %s and is remembered" % ("off" if Sfx.muted else "on"))

	Sfx.set_muted(was)

	if had_sound:
		if find_button(AppShell.i, "Quit") == null:
			push_error("TOUR: the menu has no quit button")
		var nuke := find_button(AppShell.i, "Nuke account")
		if nuke == null:
			push_error("TOUR: the menu has no nuke")
			return
		await click(nuke)

	await tree.create_timer(0.6).timeout
	var go := find_button(AppShell.i, "Nuke it")
	if go == null:
		push_error("TOUR: the nuke did not ask before firing")
		return
	await click(go)
	await tree.create_timer(0.8).timeout
	if not NukeScreen.running():
		push_error("TOUR: the nuke animation never started")
		return
	print("TOUR: the bomb is falling")

	var waited := 0.0
	while NukeScreen.running() and waited < 14.0:
		await tree.create_timer(0.25).timeout
		waited += 0.25
	if NukeScreen.running():
		push_error("TOUR: the nuke never finished")
	elif Save.has_save():
		push_error("TOUR: the nuke did not wipe the save")
	elif Game.screen != "signin":
		push_error("TOUR: the nuke left the game on screen %s" % Game.screen)
	else:
		print("TOUR: the nuke wipes the save in %.1fs and drops you at sign-in" % waited)
	if Sfx.muted != was:
		push_error("TOUR: the tour left the player's audio muted")


static func _check_warmup() -> void:
	var tree := AppShell.i.get_tree()
	if not NukeScreen._warming:
		push_error("TOUR: nothing asked for the heavy assets at boot")
		return
	var waited := 0.0
	while not NukeScreen.warmed() and waited < 25.0:
		await tree.process_frame
		waited += tree.root.get_process_delta_time()
	if not NukeScreen.warmed():
		push_error("TOUR: heavy assets still not resident after %.0fs (%.0f%%)" % [
			waited, NukeScreen.warm_progress() * 100.0
		])
	else:
		print("TOUR: heavy assets warmed in %.1fs, before anything needs them" % waited)


static func _check_sprites() -> void:
	for kind: String in SpriteAnim.SHEETS.keys():
		var spec: Dictionary = SpriteAnim.SHEETS[kind]
		var tex: Texture2D = load(String(spec["path"]))
		if tex == null:
			push_error("TOUR: %s sheet is missing" % kind)
			continue
		var cell: Vector2i = spec["cell"]
		var cols := int(spec["cols"])
		var rows := int(ceil(float(spec["frames"]) / float(cols)))
		if tex.get_width() < cell.x * cols or tex.get_height() < cell.y * rows:
			push_error("TOUR: %s is %dx%d, too small for %d frames of %dx%d" % [
				kind, tex.get_width(), tex.get_height(), int(spec["frames"]), cell.x, cell.y
			])
	for path: String in Avatar.PERSONAS:
		if load(path) == null:
			push_error("TOUR: persona %s is missing" % path)
	if not SpriteAnim.SHEETS.has("loading"):
		push_error("TOUR: no loading sheet registered")
	print("TOUR: %d sheets and %d personas load at the sizes claimed" % [
		SpriteAnim.SHEETS.size(), Avatar.PERSONAS.size()
	])


static func _check_people() -> void:
	var n := Game.suggestions.size()
	if n < Data.RECOMMEND_MIN or n > Data.RECOMMEND_MAX:
		push_error("TOUR: %d suggestions, wanted %d-%d" % [
			n, Data.RECOMMEND_MIN, Data.RECOMMEND_MAX
		])
	var handles := {}
	for acc: Dictionary in Game.suggestions:
		var h := String(acc["h"])
		if handles.has(h):
			push_error("TOUR: %s suggested twice" % h)
		handles[h] = true
		if not Data.TOPICS.has(String(acc["topic"])):
			push_error("TOUR: %s has no real topic" % h)
	for acc: Dictionary in RightColumn._suggestions():
		if Game.is_following(String(acc["h"])):
			push_error("TOUR: %s is still on offer after being followed" % acc["h"])
	if Game.people.is_empty():
		push_error("TOUR: the generator made nobody")
	else:
		print("TOUR: %d people offered today, %d generated so far" % [n, Game.people.size()])

	var a1 := People.recommend(Game.run_id, Game.day, Game.following)
	var a2 := People.recommend(Game.run_id, Game.day, Game.following)
	var stable := a1.size() == a2.size()
	if stable:
		for i in a1.size():
			if String(a1[i]["h"]) != String(a2[i]["h"]):
				stable = false
				break
	if not stable:
		push_error("TOUR: the generator is not stable for one run and day")
	elif People.recommend(Game.run_id, Game.day + 1, Game.following).is_empty():
		push_error("TOUR: the generator produced nobody for tomorrow")
	else:
		print("TOUR: the same day always generates the same people")

	var window := Data.FEED_FOLLOW_WINDOW
	var oldest := String(Game.following[0])
	var guard := 0
	while Game.following.size() <= window and guard < 40:
		guard += 1
		var pool: Array = Game.suggestions.filter(
			func(a: Dictionary) -> bool: return not Game.is_following(String(a["h"]))
		)
		if pool.is_empty():
			Game.day += 1
			Game.roll_suggestions()
			continue
		Game.follow(String(pool[0]["h"]))
	await AppShell.i.get_tree().process_frame

	var sources := Game.feed_sources()
	if sources.size() > window:
		push_error("TOUR: %d feed sources, window is %d" % [sources.size(), window])
	for acc: Dictionary in sources:
		if String(acc["h"]) == oldest:
			push_error("TOUR: %s is still a feed source after %d follows" % [oldest, window])
	for post: Dictionary in Game.feed:
		if String(post["acc"]["h"]) == oldest:
			push_error("TOUR: a post from %s survived falling out of the window" % oldest)
	print("TOUR: the feed is the last %d people followed, older ones drop out" % window)


static func _check_reactions() -> void:
	var tree := AppShell.i.get_tree()
	if Game.feed.is_empty():
		push_error("TOUR: nothing in the feed to react to")
		return
	var post: Dictionary = Game.feed[0]

	var likes := int(post.get("likes", 0))
	Game.like_post(post)
	Game.like_post(post)
	if not Game.has_liked(post) or int(post["likes"]) != likes + 1:
		push_error("TOUR: liking twice counted twice")

	var fire := int(post.get("fire", 0))
	Game.fire_post(post)
	Game.fire_post(post)
	if not Game.has_fired(post) or int(post["fire"]) != fire + 1:
		push_error("TOUR: firing twice counted twice")
	if Game.my_reactions.size() != 2:
		push_error("TOUR: a like and a fire made %d earners" % Game.my_reactions.size())
	else:
		var like_reach := int(Game.my_reactions[0]["reach"])
		var fire_reach := int(Game.my_reactions[1]["reach"])
		if Data.FIRE_IMPACT <= Data.LIKE_IMPACT:
			push_error("TOUR: a fire is not worth more than a like")
		elif fire_reach < like_reach:
			push_error("TOUR: a fire (%d) came in under a like (%d)" % [fire_reach, like_reach])
		else:
			print("TOUR: like %d, fire %d, reply %d - 1/25, 1/20, 1/8 of a post" % [
				like_reach, fire_reach, Game.comment_reach()
			])

	if Game.comments_open():
		push_error("TOUR: replies were open before %d followers" % Data.COMMENT_UNLOCK)
	var kept := Game.followers
	Game.followers = Data.COMMENT_UNLOCK
	Game._check_comments()
	if not Game.comments_open():
		push_error("TOUR: replies did not open at %d followers" % Data.COMMENT_UNLOCK)
	else:
		print("TOUR: replies unlock at %d followers" % Data.COMMENT_UNLOCK)
	Game.followers = kept

	var tree2 := AppShell.i.get_tree()
	Game.followers = Data.COMMENT_UNLOCK
	Game._check_comments()
	Game.view_dirty.emit()
	await tree2.create_timer(0.6).timeout
	var target: Dictionary = Game.feed[1] if Game.feed.size() > 1 else Game.feed[0]
	var reply_btn := find_named(AppShell.i, "act_comment")
	if reply_btn == null:
		push_error("TOUR: no reply button on a feed post after unlocking")
	else:
		await click(reply_btn)
		await tree2.create_timer(0.6).timeout
		if not Composer.is_open():
			push_error("TOUR: clicking reply did not open the composer")
		elif not Composer.is_reply():
			push_error("TOUR: the composer opened as a post, not a reply")
		else:
			var send := find_button(AppShell.i, "Reply")
			if send == null:
				push_error("TOUR: the reply composer has no Reply button")
			else:
				await click(send)
				await tree2.create_timer(0.6).timeout
				if Composer.is_open():
					push_error("TOUR: clicking Reply left the composer open")
				else:
					print("TOUR: replying by clicking works end to end")
		Composer.close()

	var beat := find_named(AppShell.i, "act_heart")
	if beat == null:
		push_error("TOUR: no like button to check for movement")
	else:
		var art: SpriteAnim = null
		for n in beat.find_children("*", "TextureRect", true, false):
			if n is SpriteAnim:
				art = n
				break
		if art == null:
			push_error("TOUR: the like button has no sprite")
		else:
			var first: Rect2 = (art.texture as AtlasTexture).region
			var moved := false
			for i in 20:
				await tree2.process_frame
				if (art.texture as AtlasTexture).region != first:
					moved = true
					break
			if not moved:
				push_error("TOUR: the like sprite on a feed post never advances a frame")
			else:
				print("TOUR: the action sprites animate on other people's posts")

	var full := Game.projected_reach()
	var third := Game.comment_reach()
	if absi(third - int(round(full * Data.COMMENT_IMPACT))) > 1:
		push_error("TOUR: a reply reaches %d, a third of %d is %d" % [
			third, full, int(round(full * Data.COMMENT_IMPACT))
		])

	var posts_before := Game.posts_today
	Game.publish_comment(post)
	await tree.create_timer(1.5).timeout
	if post.get("comments", []).size() != 1:
		push_error("TOUR: the reply did not land on the post")
	elif not Game.has_commented(post):
		push_error("TOUR: the post does not know it was replied to")
	elif Game.posts_today != posts_before:
		push_error("TOUR: a reply spent the daily post")
	elif Game.my_reactions.is_empty():
		push_error("TOUR: the reply is not being ticked")
	elif int(Game.my_reactions[-1].get("t_gained", 0)) <= 0:
		push_error("TOUR: the reply is worth no followers at all")
	elif float(Game.my_reactions[-1].get("progress", 0.0)) <= 0.0:
		push_error("TOUR: the reply is not travelling - it never entered the curve")
	else:
		print("TOUR: a reply is a third of a post and earns on its own curve")
	Game.publish_comment(post)
	if post.get("comments", []).size() != 1:
		push_error("TOUR: replied to the same post twice")


static func _check_stock() -> void:
	var seen := {}
	for f: Dictionary in Data.all_stock():
		var id := String(f["id"])
		if seen.has(id):
			push_error("TOUR: duplicate fragment id %s" % id)
		seen[id] = true
		if Data.price_of(f) <= 0:
			push_error("TOUR: %s is in the store for free" % id)
		var a := Data.ability_of(f)
		if a != "" and not Store.ABILITY_TEXT.has(a):
			push_error("TOUR: ability %s has no description" % a)
	print("TOUR: %d speech fragments in the store, all priced" % seen.size())


static func _check_trends() -> void:
	if Game.trending.size() != 3:
		push_error("TOUR: expected 3 trending tags, got %d" % Game.trending.size())
	var seen := {}
	for t: String in Game.trending:
		if seen.has(t):
			push_error("TOUR: duplicate trending tag %s" % t)
		seen[t] = true
		if not Data.TAGS.has(t):
			push_error("TOUR: trending tag %s is not in Data.TAGS" % t)
	if not ["offline", "fetching", "live"].has(Trends.status):
		push_error("TOUR: bad Trends.status %s" % Trends.status)
	print("TOUR: trends %s status=%s" % [Game.trending, Trends.status])


static func run() -> void:
	var tree := AppShell.i.get_tree()
	Prefs.set_v("tutorial_seen", true)

	await tree.create_timer(1.8).timeout
	_check_trends()
	_check_stock()
	_check_tos()
	_check_sprites()
	await _check_warmup()
	await _check_toast()
	print("TOUR: logical viewport %s" % AppShell.i.get_viewport_rect().size)

	await _check_prologue()
	await _check_tos_flow()

	var tick := find_button(AppShell.i, "community guidelines")
	if tick == null:
		push_error("TOUR: guidelines checkbox not found")
	else:
		await click(tick)
	await tree.create_timer(0.6).timeout

	var ok := find_button(AppShell.i, "OK")
	if ok == null:
		push_error("TOUR: sign-in OK button not found")
	else:
		await click(ok)
	await tree.create_timer(0.8).timeout
	if Game.screen != "app":
		push_error("TOUR: clicking OK did not sign in (screen=%s)" % Game.screen)
	else:
		print("TOUR: signed in by clicking OK")

	await tree.create_timer(2.0).timeout
	var new_post := find_button(AppShell.i, "New Post")
	if new_post == null:
		push_error("TOUR: New Post button not found")
	else:
		await click(new_post)
		await tree.create_timer(0.4).timeout
		if not Composer.is_open():
			push_error("TOUR: clicking New Post did not open the composer")
		else:
			print("TOUR: New Post opens the composer")

	await tree.create_timer(1.0).timeout
	var post_btn := find_button(AppShell.i, "Post it")
	if post_btn == null:
		push_error("TOUR: Post it button not found")
	else:
		var vp := AppShell.i.get_viewport_rect()
		var r := post_btn.get_global_rect()
		var reachable := vp.encloses(r)
		if not reachable:
			push_error("TOUR: the Post it button is off-screen - the dialog does not fit")
		await click(post_btn)
		await tree.create_timer(0.5).timeout
		if Game.my_posts.size() != 1:
			push_error(("TOUR: clicking Post it did not publish anything "
				+ "(posts=%d screen=%s posts_today=%d/%d day=%d composer_open=%s)") % [
				Game.my_posts.size(), Game.screen, Game.posts_today,
				Game.posts_per_day(), Game.day, Composer.is_open()
			])
		else:
			print("TOUR: posting works end to end")

	await tree.create_timer(1.6).timeout
	Game.set_fragment("start", String(Game.hand_for("start")[1]["id"]))
	Composer.refresh()
	await tree.create_timer(1.4).timeout
	Game.set_fragment("end", String(Game.hand_for("end")[2]["id"]))
	Composer.refresh()
	await tree.create_timer(1.4).timeout
	Game.reroll_hand()
	Composer.refresh()
	await tree.create_timer(1.8).timeout
	Composer.close()
	Game.publish()

	await tree.create_timer(2.0).timeout
	if not Game.feed.is_empty():
		push_error("TOUR: the feed has posts in it before anybody is followed")

	var day_before := Game.day_length()
	Game.follow(String(Data.ACCOUNTS[0]["h"]))
	await tree.create_timer(1.2).timeout
	if Game.feed.is_empty():
		push_error("TOUR: following somebody did not fill the feed")
	else:
		var stray := 0
		for post: Dictionary in Game.feed:
			if not Game.is_following(String(post["acc"]["h"])):
				stray += 1
		if stray > 0:
			push_error("TOUR: %d feed posts are from accounts nobody follows" % stray)
		else:
			print("TOUR: the feed only carries accounts you follow")

	var spent := day_before - Game.day_length()
	if spent < Data.FOLLOW_SECONDS_MIN - 0.001 or spent > Data.FOLLOW_SECONDS_MAX + 0.001:
		push_error("TOUR: a follow cost %.2fs, outside %.2f-%.2f" % [
			spent, Data.FOLLOW_SECONDS_MIN, Data.FOLLOW_SECONDS_MAX
		])
	else:
		print("TOUR: a follow cost %s of the day (%.2fs)" % [Game.duration(spent), spent])

	Game.follow(String(Data.ACCOUNTS[1]["h"]))
	await tree.create_timer(1.2).timeout
	await _check_people()
	await _check_reactions()

	await tree.create_timer(2.0).timeout
	Game.store_unlocked = false
	Game.followers = Data.STORE_UNLOCK - 1
	Game._check_store()
	if Game.store_open():
		push_error("TOUR: store opened one follower early")
	Game.followers = 400
	Game._check_store()
	if not Game.store_open():
		push_error("TOUR: store did not open on crossing the threshold")
	Game.followers = 10
	if not Game.store_open():
		push_error("TOUR: store re-locked after followers fell")
	Game.followers = 400
	Game.payout = 600.0
	Game.view_dirty.emit()
	await tree.create_timer(1.6).timeout
	var shop := find_button(AppShell.i, "Store")
	if shop == null:
		push_error("TOUR: store button not found at %d followers" % Game.followers)
	else:
		await click(shop)
		await tree.create_timer(0.8).timeout
		var buy := find_button(AppShell.i, "the algorithm")
		if buy == null:
			push_error("TOUR: store stock not listed")
		else:
			await click(buy)
			await tree.create_timer(0.5).timeout
			if not Game.owned.has("algorithm"):
				push_error("TOUR: buying a speech fragment did nothing")
			else:
				print("TOUR: store sells speech fragments")
		Dialog.close()

	await tree.create_timer(1.0).timeout
	Game._tick = false
	Game.assets_unlocked = false
	Game.assets = {}
	Game.followers = Data.ASSETS_UNLOCK - 1
	Game.view_dirty.emit()
	await tree.process_frame
	await tree.process_frame
	if Game.assets_open():
		push_error("TOUR: assets opened before %d followers" % Data.ASSETS_UNLOCK)
	Game.buy_asset(Data.ASSETS[0])
	if Game.asset_count("burner") != 0:
		push_error("TOUR: an asset was bought while the shelf was still locked")
	if find_button(AppShell.i, "Burner account") != null:
		push_error("TOUR: the assets panel is on screen before it unlocks")

	Game.followers = Data.ASSETS_UNLOCK
	Game._check_assets()
	if not Game.assets_open():
		push_error("TOUR: assets did not open on crossing the threshold")
	else:
		print("TOUR: assets unlock at %d followers" % Data.ASSETS_UNLOCK)
	Game.view_dirty.emit()
	await tree.process_frame
	await tree.process_frame
	if find_button(AppShell.i, "Burner account") == null:
		push_error("TOUR: the assets panel did not appear after unlocking")
	Game._tick = true

	var before := Game.followers
	Game.buy_asset(Data.ASSETS[0])
	Game.buy_asset(Data.ASSETS[1])
	if Game.asset_count("burner") != 1 or Game.asset_count("farm") != 1:
		push_error("TOUR: buying an asset did nothing")
	elif Game.asset_cost(Data.ASSETS[0]) <= int(Data.ASSETS[0]["cost"]):
		push_error("TOUR: asset price did not rise after buying one")
	else:
		print("TOUR: assets bought, next one costs more")
	await tree.create_timer(2.0).timeout
	if Game.followers <= before:
		push_error("TOUR: assets are not producing followers")
	else:
		print("TOUR: assets produce followers idly")

	Game.payout = 500_000.0
	var burner: Dictionary = Data.ASSETS[0]
	var one := Game.bulk_cost(burner, 1)
	var ten := Game.bulk_cost(burner, 10)
	if ten <= one * 10 or ten <= one:
		push_error("TOUR: ten cost %d, one costs %d - not compounding" % [ten, one])
	var before_n := Game.asset_count("burner")
	Game.buy_asset(burner, 10)
	if Game.asset_count("burner") != before_n + 10:
		push_error("TOUR: buying x10 gave %d" % (Game.asset_count("burner") - before_n))
	else:
		print("TOUR: x10 buys ten and costs £%s, not £%s" % [
			Game.commas(ten), Game.commas(one * 10)
		])

	var fps_on := Game.followers_per_second()
	var heat_on := Game.heat_per_second()
	Game.toggle_paused("burner")
	if Game.followers_per_second() >= fps_on or Game.heat_per_second() >= heat_on:
		push_error("TOUR: pausing did not stop the burners")
	elif Game.asset_count("burner") != before_n + 10:
		push_error("TOUR: pausing sold the burners")
	else:
		print("TOUR: pausing stops production and heat, keeps what you bought")
	Game.toggle_paused("burner")

	Game.followers = 100
	var small := Game.daily_cooling()
	Game.followers = 1_000_000
	var large := Game.daily_cooling()
	if large <= small:
		push_error("TOUR: cooling does not scale with audience (%.1f vs %.1f)" % [small, large])
	else:
		print("TOUR: cooling grows %.0f/day to %.0f/day across the run" % [small, large])

	Game.followers = Data.AGENTS_UNLOCK - 1
	Game._check_agents()
	if Game.agents_open():
		push_error("TOUR: people were hireable before %d followers" % Data.AGENTS_UNLOCK)
	Game.followers = Data.AGENTS_UNLOCK
	Game._check_agents()
	if not Game.agents_open():
		push_error("TOUR: people never became hireable")
	else:
		var first: Dictionary = Data.AGENTS[0]
		Game.payout = 3_000.0
		var was_agents := Game.agent_count(String(first["id"]))
		Game.buy_agent(first, 1)
		if Game.agent_count(String(first["id"])) != was_agents + 1:
			push_error("TOUR: hiring the first agent failed at £%d" % int(first["cost"]))
		else:
			print("TOUR: people unlock at %s followers, first hire £%s" % [
				Game.compact(Data.AGENTS_UNLOCK), Game.commas(int(first["cost"]))
			])
	Game.payout = 600.0

	var sched: Dictionary = {}
	for a: Dictionary in Data.ASSETS:
		if int(a.get("posts", 0)) > 0:
			sched = a
			break
	if sched.is_empty():
		push_error("TOUR: nothing in the shelf sells an extra post")
	else:
		var was := Game.posts_per_day()
		Game.payout = float(Game.asset_cost(sched)) + 10.0
		Game.buy_asset(sched)
		if Game.posts_per_day() != was + int(sched["posts"]):
			push_error("TOUR: %s did not add a post to the day" % sched["id"])
		elif Game.asset_cost(sched) <= int(sched["cost"]):
			push_error("TOUR: the second one is not dearer than the first")
		elif not Game.can_post():
			push_error("TOUR: the extra post is not available after buying it")
		else:
			print("TOUR: %s raises the day to %d posts" % [sched["id"], Game.posts_per_day()])
			var used := Game.posts_today
			Game.publish()
			await tree.process_frame
			if Game.posts_today != used + 1:
				push_error("TOUR: the extra post did not publish")
			elif Game.posts_today < Game.posts_per_day() and not Game.can_post():
				push_error("TOUR: posts remain but the day refuses them")
			else:
				print("TOUR: both posts spent, the day is closed again")

	await tree.create_timer(1.0).timeout
	_check_save()
	await _check_menu_at_signin()
	await _check_tutorial()
	_check_fonts()

	Composer.open()
	await tree.create_timer(1.6).timeout
	Game.set_fragment("middle", String(Game.hand_for("middle")[3]["id"]))
	Composer.refresh()
	await tree.create_timer(1.6).timeout
	Game.set_fragment("end", String(Game.hand_for("end")[3]["id"]))
	Composer.refresh()

	await tree.create_timer(2.6).timeout
	Composer.close()

	await _check_titles_and_win()
	await tree.create_timer(0.6).timeout
	_check_offline()

	await tree.create_timer(1.0).timeout
	Game.followers = 240_000
	Game.suspicion = 74.0
	Game.view_dirty.emit()

	await tree.create_timer(3.0).timeout
	Game.strikes = Data.STRIKES_ALLOWED - 1
	Game.suspicion = Data.SUSPICION_LIMIT
	Game._strike()
	await tree.create_timer(1.0).timeout
	if Game.screen != "over":
		push_error("TOUR: the third strike did not end the run")
	else:
		print("TOUR: three strikes ends the run")

	await tree.create_timer(2.0).timeout
	var again := find_button(AppShell.i, "New account")
	if again == null:
		push_error("TOUR: no way out of the ending screen")
	else:
		await click(again)
		await tree.create_timer(0.8).timeout
		if Game.store_open() or not Game.owned.is_empty() or Game.payout != 0.0:
			push_error("TOUR: restart did not clear the store state")
		else:
			print("TOUR: restart resets cleanly")

	await tree.create_timer(1.0).timeout
	await _check_menu()
