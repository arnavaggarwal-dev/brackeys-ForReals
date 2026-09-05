class_name Tutorial
extends RefCounted

# The tutorial is a list of chapters rather than one run of steps. "basics" plays
# once, when the account is new. The rest are held back until the thing they are
# about actually exists, and each one plays the moment it unlocks. Everything a
# player has been shown stays on the list, so replaying from the Start menu walks
# the whole tutorial as it stands, not only the part they started with.
const CHAPTERS := {
	"basics": {
		"name": "The basics",
		"steps": [
			{
				"find": "New Post",
				"where": "left",
				"title": "One post a day",
				"body": "A day is thirty seconds. You get one post in it, built from "
					+ "three fragments you are dealt. That is the whole game.",
			},
			{
				"find": "",
				"where": "left",
				"title": "This is you",
				"body": "Two followers and a handle you cannot change. Followers, "
					+ "likes and your payout live here. Nothing else earns you "
					+ "anything.",
			},
			{
				"find": "",
				"where": "centre",
				"title": "The feed",
				"body": "Only the last seven people you followed reach you. Follow an "
					+ "eighth and the first one drops out. Liking and replying to them "
					+ "earns a fraction of a post.",
			},
			{
				"find": "",
				"where": "right",
				"title": "Today",
				"body": "Three hashtags trend each day, decided by what the real world "
					+ "is actually reading. Catching one is worth more reach than "
					+ "anything you have to say.",
			},
			{
				"find": "Suspicion",
				"where": "left",
				"title": "Suspicion",
				"body": "Anything nobody can check fills this bar. Say something that "
					+ "can be looked up and it costs you much less. It falls on its own "
					+ "overnight, and faster the bigger you are.",
			},
			{
				"find": "Suspicion",
				"where": "left",
				"title": "Strikes",
				"body": "Fill the bar and you take a strike: {strike_loss} of your "
					+ "followers gone and your reach quietly limited until it cools. "
					+ "{strikes} strikes and the account stops existing. Nobody warns "
					+ "you first.",
			},
			{
				"find": "",
				"where": "taskbar",
				"title": "Start",
				"body": "Sound, the tutorial again, and quitting all live down here. "
					+ "The clock on the right is the day running out.",
			},
		],
	},
	"store": {
		"name": "The store",
		"steps": [
			{
				"find": "Speech Fragment Store",
				"where": "left",
				"title": "The store is open",
				"body": "Your payout buys fragments the free deck will not give you. "
					+ "Once bought, one is dealt to you like any other.",
			},
			{
				"find": "Speech Fragment Store",
				"where": "left",
				"title": "They cost more than money",
				"body": "Everything in there travels further and none of it can be "
					+ "checked, so every one of them fills suspicion faster. That is "
					+ "what you are paying for.",
			},
		],
	},
	"comments": {
		"name": "Replies",
		"steps": [
			{
				"find": "",
				"where": "centre",
				"title": "You can reply now",
				"body": "Every post in the feed takes a reply. A reply is worth about a "
					+ "third of a post, costs you nothing but the day, and the people "
					+ "you reply to remember it.",
			},
		],
	},
	"assets": {
		"name": "Assets",
		"steps": [
			{
				"find": "ASSETS",
				"where": "right",
				"title": "You can buy an audience",
				"body": "Assets run on their own and keep earning while the day does. "
					+ "Buying the same one again makes it cost more and work harder.",
			},
			{
				"find": "ASSETS",
				"where": "right",
				"title": "None of it is quiet",
				"body": "Every asset adds suspicion the whole time it is running. You "
					+ "can pause one without selling it when the bar gets close.",
			},
		],
	},
	"agents": {
		"name": "People",
		"steps": [
			{
				"find": "PEOPLE",
				"where": "right",
				"title": "You can hire people now",
				"body": "People like and reply on your behalf. They are slower than an "
					+ "asset and far quieter, and they keep working while the game is "
					+ "closed.",
			},
		],
	},
}

const ORDER := ["basics", "store", "comments", "assets", "agents"]

const SEEN_KEY := "tutorial_chapters"
const LEGACY_KEY := "tutorial_seen"

static var _open := false
static var _step := 0
static var _steps: Array = []
static var _playing: Array = []
static var _pending: Array = []
static var _draining := false


static func is_open() -> bool:
	return _open


static func seen_chapters() -> Array:
	var raw: Variant = Prefs.get_v(SEEN_KEY, null)
	if raw is Array:
		return (raw as Array).filter(func(id: Variant) -> bool: return CHAPTERS.has(id))
	# Older builds stored one flag for the only tutorial there was.
	if bool(Prefs.get_v(LEGACY_KEY, false)):
		Prefs.set_v(SEEN_KEY, ["basics"])
		return ["basics"]
	return []


static func seen(id: String) -> bool:
	return seen_chapters().has(id)


static func mark_seen(id: String) -> void:
	var list := seen_chapters()
	if list.has(id):
		return
	list.append(id)
	Prefs.set_v(SEEN_KEY, list)


static func maybe_start() -> void:
	if seen("basics") or Game.screen != "app":
		return
	play(["basics"])


# Called when the thing a chapter is about unlocks. It waits for the player to be
# looking at the shell before it interrupts them, and never plays twice.
static func unlocked(id: String) -> void:
	if not CHAPTERS.has(id) or seen(id) or _pending.has(id):
		return
	_pending.append(id)
	_drain()


# The Start menu replays every chapter unlocked so far, in order.
static func start() -> void:
	var order := ORDER.filter(func(id: String) -> bool: return seen(id))
	if order.is_empty():
		order = ["basics"]
	play(order)


static func play(chapters: Array) -> void:
	_playing = chapters.duplicate()
	_steps = []
	for id: String in _playing:
		for step: Dictionary in CHAPTERS[id]["steps"]:
			_steps.append(step)
	if _steps.is_empty():
		return
	_step = 0
	_open = true
	_render()


static func stop() -> void:
	_open = false
	for id: String in _playing:
		mark_seen(id)
	_playing = []
	_steps = []
	AppShell.i.clear_menu()


static func _drain() -> void:
	if _draining:
		return
	_draining = true
	while not _pending.is_empty():
		await _wait_idle()
		var id := String(_pending.pop_front())
		if seen(id):
			continue
		play([id])
		while _open:
			await AppShell.i.get_tree().process_frame
	_draining = false


# A chapter fires off the back of a follower count changing, which can happen
# with the composer or the store still open on top of the shell.
static func _wait_idle() -> void:
	var tree := AppShell.i.get_tree()
	while true:
		if (
			not _open
			and Game.screen == "app"
			and AppShell.i.veil.get_child_count() == 0
			and AppShell.i.menu_layer.get_child_count() == 0
			and not NukeScreen.running()
		):
			return
		await tree.process_frame


static func _next() -> void:
	_step += 1
	if _step >= _steps.size():
		stop()
		return
	_render()


static func _target_rect(step: Dictionary) -> Rect2:
	var shell := AppShell.i
	var find := String(step.get("find", ""))
	if find != "":
		var hit := _find_text(shell, find)
		if hit != null:
			return hit.get_global_rect()
	match String(step.get("where", "")):
		"left":
			return shell.left_win.get_global_rect()
		"centre":
			return shell.centre_win.get_global_rect()
		"right":
			return shell.right_win.get_global_rect()
		"taskbar":
			return shell.taskbar.get_global_rect()
	return Rect2()


static func _find_text(root: Node, text: String) -> Control:
	if root is Label and String(root.text).findn(text) >= 0:
		var p := root.get_parent()
		while p != null and not (p is PanelContainer or p is VBoxContainer):
			p = p.get_parent()
		return (p if p is Control else root) as Control
	for c in root.get_children():
		var hit := _find_text(c, text)
		if hit != null:
			return hit
	return null


static func _render() -> void:
	var step: Dictionary = _steps[_step]
	# On a phone the window this step is about has to be brought forward first.
	if AppShell.narrow:
		AppShell.i.show_pane_for(String(step.get("where", "")))
		await AppShell.i.get_tree().process_frame
	var vp := AppShell.i.get_viewport_rect().size
	var target := _target_rect(step)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	if target.size.x > 1.0:
		var ring := Highlight.new()
		ring.set_anchors_preset(Control.PRESET_TOP_LEFT)
		ring.position = target.position - Vector2(4, 4)
		ring.size = target.size + Vector2(8, 8)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(ring)

	var card := _card(step)
	root.add_child(card)
	AppShell.i.mount_menu(root)
	Sfx.tick()
	_place(card, target, vp)


static func _place(card: Control, target: Rect2, vp: Vector2) -> void:
	await AppShell.i.get_tree().process_frame
	if not is_instance_valid(card):
		return
	var size := card.get_combined_minimum_size()
	size.x = maxf(size.x, 300.0)
	card.size = size

	var pos := Vector2(target.position.x, target.end.y + 14.0)
	if pos.y + size.y > vp.y - 12.0:
		pos.y = target.position.y - size.y - 14.0
	if pos.y < 12.0:
		pos.y = clampf(target.get_center().y - size.y * 0.5, 12.0, vp.y - size.y - 12.0)
	pos.x = clampf(pos.x, 12.0, maxf(12.0, vp.x - size.x - 12.0))
	card.position = pos.floor()


# Numbers a step quotes come from the tuning constants, so the tutorial cannot
# drift away from what the game actually does.
static func _fill(text: String) -> String:
	return (text
		.replace("{strike_loss}", "%d%%" % int(Data.STRIKE_LOSS * 100.0))
		.replace("{strikes}", str(Data.STRIKES_ALLOWED)))


static func _card(step: Dictionary) -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", Style.frame_box(3))
	frame.custom_minimum_size.x = 360.0

	var col := Style.vbox(0)
	frame.add_child(col)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", Style.title_box(true))
	var bar_row := Style.hbox(0)
	bar_row.add_child(Style.label(String(step["title"]), Style.ui_b, 14, Style.TITLE_TEXT))
	bar_row.add_child(Style.grow())
	bar_row.add_child(Style.num(
		"%d of %d" % [_step + 1, _steps.size()], 11, Style.TITLE_TEXT
	))
	bar.add_child(Style.margins(bar_row, 6, 3, 6, 3))
	col.add_child(bar)

	var body := Style.vbox(10)
	body.add_child(Style.body(_fill(String(step["body"])), Style.ui_r, 13, Style.INK, 4))

	var row := Style.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_END
	var skip := Dialog.button("Skip")
	skip.pressed.connect(stop)
	row.add_child(skip)
	var next := Dialog.button(
		"Got it" if _step == _steps.size() - 1 else "Next", true
	)
	next.pressed.connect(_next)
	row.add_child(next)
	body.add_child(row)

	col.add_child(Style.margins(body, 12, 10, 12, 12))
	return frame
