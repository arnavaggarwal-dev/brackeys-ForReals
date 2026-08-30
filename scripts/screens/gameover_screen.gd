class_name GameOverScreen
extends RefCounted

static var outcome := "banned"


static func show_over() -> void:
	if outcome == "ousted":
		_show_ousted()
		return

	var won := outcome == "won"

	# Winning leaves the account open, so the title bar X drops you back into
	# the run. Losing has nowhere to go, so it does nothing.
	var on_close := func() -> void: pass
	if won:
		on_close = func() -> void:
			Dialog.close()
			Game.keep_going()

	var body := Dialog.open(
		"ForReals" if won else "ForReals - Account Suspended",
		620.0, on_close, true
	)

	body.add_child(Dialog.message(
		Icon.Kind.CHECK if won else Icon.Kind.STOP,
		_body_text(won),
		Style.OK_GREEN if won else Style.ALARM
	))
	body.add_child(Style.spacer(16))
	body.add_child(Style.group("Session summary", _scoreboard()))
	body.add_child(Style.spacer(14))

	if Game.my_posts.size() > 0:
		body.add_child(Style.group("What you said to get here", _log()))
		body.add_child(Style.spacer(14))

	body.add_child(Style.hline())
	body.add_child(Style.spacer(12))

	var row := Dialog.buttons()
	if won:
		var stay := Dialog.button("Keep the account", true)
		stay.pressed.connect(func() -> void:
			Dialog.close()
			Game.keep_going())
		row.add_child(stay)
	var again := Dialog.button("New account", true)
	again.pressed.connect(func() -> void: AppShell.i.restart())
	row.add_child(again)
	Dialog.actions(row)


static func _show_ousted() -> void:
	var body := Dialog.open("ForReals - Account Terminated", 640.0, Callable(), true)

	body.add_child(Dialog.message(
		Icon.Kind.STOP,
		"@%s has been removed for coordinated inauthentic behaviour." % Data.PROLOGUE_HANDLE,
		Style.ALARM
	))
	body.add_child(Style.spacer(16))

	var well := Dialog.well(12)
	var col := Style.vbox(9)
	col.add_child(Style.body(
		"Nine million people followed that account this morning. It took one post.",
		Style.ui_m, 15, Style.INK, 4
	))
	col.add_child(Style.body(
		"Nobody argued with you. Nobody corrected you. The reach was simply turned "
		+ "down until you were talking to an empty room, and then the room was "
		+ "closed. You never saw the number that did it.",
		Style.ui_r, 13, Style.INK_SOFT, 4
	))
	col.add_child(Style.body(
		"It is still there on the next account, and the one after that. It does not "
		+ "care whose name is on it.",
		Style.ui_r, 13, Style.INK_SOFT, 4
	))
	well.add_child(col)
	body.add_child(well)
	body.add_child(Style.spacer(14))
	body.add_child(Style.group("What it cost", _ousted_score()))
	body.add_child(Style.spacer(14))
	body.add_child(Style.hline())
	body.add_child(Style.spacer(12))

	var row := Dialog.buttons()
	var again := Dialog.button("Start again as nobody", true)
	again.pressed.connect(func() -> void:
		Game.reset()
		AppShell.i.clear_veil()
		AppShell.i.render_view()
		TosScreen.show_tos())
	row.add_child(again)
	Dialog.actions(row)


static func _ousted_score() -> Control:
	var well := Dialog.well(10)
	var col := Style.vbox(5)
	col.add_child(_row("Followers this morning", Game.commas(Data.PROLOGUE_FOLLOWERS)))
	col.add_child(_row("Followers now", "0"))
	col.add_child(_row("Posts it took", str(maxi(1, Game.my_posts.size()))))
	col.add_child(_row("Warnings you were given", "0"))
	well.add_child(col)
	return well


static func _body_text(won: bool) -> String:
	if won:
		return ("%s people read whatever you type next.\n\n"
			+ "You did not lie about everything. You lied in %d of the %d things "
			+ "you posted, and the rest was there to make those ones look normal.\n\n"
			+ "Nobody is coming to correct it. That was never how any of this "
			+ "worked. The account is still open, if you want it.") % [
				Game.commas(Game.followers), _charged_count(), Game.my_posts.size()
			]
	return ("This program has performed an illegal operation and will be shut down.\n\n"
		+ "Three strikes. The trust team has removed @%s and everything on it. "
		+ "What you started is not gone - it is on %d other accounts now, in "
		+ "slightly different words, and none of them will ever be traced back "
		+ "to you.") % [Game.handle, maxi(1, Game.followers / 900)]


static func _charged_count() -> int:
	var n := 0
	for p: Dictionary in Game.my_posts:
		if bool(p.get("charged", false)):
			n += 1
	return n


static func _scoreboard() -> Control:
	var well := Dialog.well(10)
	var col := Style.vbox(5)
	col.add_child(_row("Followers", Game.commas(Game.followers)))
	col.add_child(_row("They called you", Game.title()))
	col.add_child(_row("Days survived", str(Game.day)))
	col.add_child(_row("Posts", str(Game.my_posts.size())))
	col.add_child(_row("Of those, uncheckable", str(_charged_count())))
	col.add_child(_row("Accounts followed", str(Game.following.size())))
	col.add_child(_row("Shortest day", Game.duration(Game.day_length())))
	well.add_child(col)
	return well


static func _row(key: String, value: String) -> Control:
	var row := Style.hbox(10)
	row.add_child(Style.label(key, Style.ui_r, 13, Style.INK_SOFT))
	row.add_child(Style.grow())
	row.add_child(Style.num(value, 13, Style.INK))
	return row


static func _log() -> Control:
	var well := Dialog.well(6)
	var col := Style.vbox(2)
	for p: Dictionary in Game.my_posts.slice(0, 8):
		var row := Style.hbox(8)
		var stripe := ColorRect.new()
		stripe.color = Style.ALARM if bool(p.get("charged", false)) else Style.HOT
		stripe.custom_minimum_size.x = 3
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(stripe)

		var line := Style.vbox(1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(Style.body(
			String(p["text"]), Style.ui_r, 13,
			Style.ALARM if bool(p.get("charged", false)) else Style.INK, 3
		))
		line.add_child(Style.num(
			"day %d - +%s followers" % [int(p["day"]), Game.compact(int(p["gained"]))],
			9, Style.INK_FAINT
		))
		row.add_child(line)
		col.add_child(Style.margins(row, 0, 4, 0, 4))
	well.add_child(col)
	return well
