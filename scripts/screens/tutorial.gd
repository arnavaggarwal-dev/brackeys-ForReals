class_name Tutorial
extends RefCounted

const STEPS := [
	{
		"find": "New Post",
		"where": "left",
		"title": "One post a day",
		"body": "A day is thirty seconds. You get one post in it, built from three "
			+ "fragments you are dealt. That is the whole game.",
	},
	{
		"find": "",
		"where": "left",
		"title": "This is you",
		"body": "Two followers and a handle you cannot change. Followers, likes and "
			+ "your payout live here. Nothing else earns you anything.",
	},
	{
		"find": "",
		"where": "centre",
		"title": "The feed",
		"body": "Only the last seven people you followed reach you. Follow an eighth "
			+ "and the first one drops out. Liking and replying to them earns a "
			+ "fraction of a post.",
	},
	{
		"find": "",
		"where": "right",
		"title": "Today",
		"body": "Three hashtags trend each day, decided by what the real world is "
			+ "actually reading. Catching one is worth more reach than anything you "
			+ "have to say.",
	},
	{
		"find": "Suspicion",
		"where": "left",
		"title": "Suspicion",
		"body": "Claims nobody can check fill this bar. Fill it and you take a "
			+ "strike: followers gone, reach limited. Three strikes and the account "
			+ "stops existing - you watched that happen already.",
	},
	{
		"find": "",
		"where": "taskbar",
		"title": "Start",
		"body": "Sound, the tutorial again, and quitting all live down here. The "
			+ "clock on the right is the day running out.",
	},
]

static var _open := false
static var _step := 0
static var _root: Control = null


static func is_open() -> bool:
	return _open


static func seen() -> bool:
	return bool(Prefs.get_v("tutorial_seen", false))


static func mark_seen() -> void:
	Prefs.set_v("tutorial_seen", true)


static func maybe_start() -> void:
	if seen() or Game.prologue or Game.screen != "app":
		return
	start()


static func start() -> void:
	_step = 0
	_open = true
	_render()


static func stop() -> void:
	_open = false
	_root = null
	mark_seen()
	AppShell.i.clear_menu()


static func _next() -> void:
	_step += 1
	if _step >= STEPS.size():
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
	var step: Dictionary = STEPS[_step]
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
	_root = root
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
		"%d of %d" % [_step + 1, STEPS.size()], 11, Style.TITLE_TEXT
	))
	bar.add_child(Style.margins(bar_row, 6, 3, 6, 3))
	col.add_child(bar)

	var body := Style.vbox(10)
	body.add_child(Style.body(String(step["body"]), Style.ui_r, 13, Style.INK, 4))

	var row := Style.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_END
	var skip := Dialog.button("Skip")
	skip.pressed.connect(stop)
	row.add_child(skip)
	var next := Dialog.button(
		"Got it" if _step == STEPS.size() - 1 else "Next", true
	)
	next.pressed.connect(_next)
	row.add_child(next)
	body.add_child(row)

	col.add_child(Style.margins(body, 12, 10, 12, 12))
	return frame
