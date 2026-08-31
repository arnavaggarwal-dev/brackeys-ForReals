class_name Composer
extends RefCounted

static var _open := false
static var _target: Dictionary = {}


static func is_open() -> bool:
	return _open


static func open() -> void:
	if not Game.can_post():
		Game.toast_requested.emit("No post left today", "one a day. that is the whole game", true)
		return
	_target = {}
	_open = true
	_render()


static func reply_to(post: Dictionary) -> void:
	if not Game.comments_open():
		return
	if Game.has_commented(post):
		Game.toast_requested.emit("You already replied to that", "once each", true)
		return
	_target = post
	_open = true
	_render()


static func is_reply() -> bool:
	return not _target.is_empty()


static func close() -> void:
	_open = false
	_target = {}
	Dialog.close()


static func refresh() -> void:
	if _open:
		_render()


static func _render() -> void:
	var title := "New Post"
	if is_reply():
		title = "Reply to @%s" % String(_target.get("acc", {}).get("h", "someone"))
	var body := Dialog.open(title, minf(900.0, AppShell.i.size.x - 100.0), close)

	body.add_child(_sentence_well())
	body.add_child(Style.spacer(14))

	body.add_child(_slots())
	body.add_child(Style.spacer(10))
	body.add_child(_deal_row())
	body.add_child(Style.spacer(14))

	var split: Control = Style.vbox(12) if AppShell.narrow else Style.hbox(14)
	split.add_child(Style.group("Verdict", _verdict()))
	var right := Style.vbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(Style.group("Projection", _projection()))
	split.add_child(right)
	body.add_child(split)
	body.add_child(Style.spacer(16))

	var row := Dialog.buttons()
	var post := Dialog.button(
		"Reply" if is_reply() else "Post it", true,
		Style.ALARM if Game.draft_is_charged() else Style.INK
	)
	var target := _target
	post.pressed.connect(func() -> void:
		close()
		if target.is_empty():
			Game.publish()
		else:
			Game.publish_comment(target))
	row.add_child(post)
	var cancel := Dialog.button("Cancel")
	cancel.pressed.connect(close)
	row.add_child(cancel)
	Dialog.actions(row)


static func _sentence_well() -> Control:
	var well := Dialog.well(12)
	var charged := Game.draft_is_charged()
	var col := Style.vbox(6)
	col.add_child(Style.body(
		Game.draft_line(), Style.ui_b, 22, Style.ALARM if charged else Style.INK, 6
	))

	var tags := Style.hbox(10)
	for t: String in Game.draft_tags():
		var hot := Game.is_trending(t)
		var chip := Style.hbox(4)
		if hot:
			var f := SpriteAnim.make("fire", 14.0)
			f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			chip.add_child(f)
		chip.add_child(Style.label(t, Style.ui_m, 13, Style.ALARM if hot else Style.HOT))
		tags.add_child(chip)
	col.add_child(tags)
	well.add_child(col)
	return well


# Three columns abreast need more width than a phone has in either orientation.
# A PanelContainer is never smaller than what it holds, so left as a row this
# overrides the dialog's own width clamp and hangs off the side of the screen.
static func _slots() -> Control:
	var row: Control = Style.vbox(10) if AppShell.narrow else Style.hbox(12)
	row.add_child(_slot("start", "Who", Game.draft_start))
	row.add_child(_slot("middle", "Did what", Game.draft_middle))
	row.add_child(_slot("end", "To what", Game.draft_end))
	return row


static func _slot(id: String, heading: String, chosen: String) -> Control:
	var list := PanelContainer.new()
	list.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	var items := Style.vbox(0)
	for f: Dictionary in Game.hand_for(id):
		items.add_child(_chip(id, f, f["id"] == chosen))
	list.add_child(items)

	var wrap := Style.vbox(0)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(Style.group(heading, list))
	return wrap


static func _chip(slot: String, f: Dictionary, selected: bool) -> Control:
	var charged := Data.is_locked(f)
	var wild: bool = f.get("wild", false)
	var t := Tappable.new(Vector4(8, 6, 8, 7), Tappable.Look.LIST)
	t.set_selected(selected)

	var text_ink: Color = Style.SELECT_FG if selected else (
		Style.ALARM if charged else Style.INK
	)
	var meta_ink: Color = Style.SELECT_FG if selected else Style.INK_SOFT

	var col := Style.vbox(3)
	col.add_child(Style.body(String(f["text"]), Style.ui_m, 14, text_ink, 2))

	var ability := Data.ability_of(f)
	if ability != "":
		col.add_child(Style.body(
			String(Store.ABILITY_TEXT.get(ability, "")), Style.ui_r, 11,
			Style.SELECT_FG if selected else Style.OK_GREEN, 2
		))

	var meta := Style.hbox(6)
	var tag := String(f["tag"])
	var hot := Game.is_trending(tag)
	if hot:
		var flame := SpriteAnim.make("fire", 13.0)
		flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meta.add_child(flame)
	meta.add_child(Style.label(
		tag, Style.ui_r, 11,
		meta_ink if not hot else (Style.SELECT_FG if selected else Style.ALARM)
	))
	meta.add_child(Style.grow())

	if f.has("base"):
		meta.add_child(Style.num("%d" % int(f["base"]), 11, meta_ink))
	else:
		meta.add_child(Style.num("x%.1f" % float(f["reach"]), 11, meta_ink))

	if float(f.get("susp", 0.0)) > 0.0:
		var eye := Icon.new(Icon.Kind.EYE, 11, Style.SELECT_FG if selected else Style.ALARM)
		eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meta.add_child(eye)
		meta.add_child(Style.num(
			"%d" % int(f["susp"]), 11, Style.SELECT_FG if selected else Style.ALARM
		))
	if wild:
		meta.add_child(Style.label("?", Style.ui_b, 12, Style.SELECT_FG if selected else Style.WARN))
	col.add_child(meta)

	t.add_content(col)
	t.pressed.connect(func() -> void:
		Game.set_fragment(slot, String(f["id"]))
		refresh())
	return t


static func _deal_row() -> Control:
	var row := Style.hbox(12)
	var note := Style.body(
		"Four speech fragments of each, dealt this morning. This is everything the "
		+ "platform is letting you say today.",
		Style.ui_r, 12, Style.INK_SOFT, 3
	)
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(note)

	var live := Game.rerolls_left > 0
	var deal := Dialog.button("Deal again (%d)" % Game.rerolls_left, true)
	deal.set_enabled(live)
	if live:
		deal.pressed.connect(func() -> void:
			Game.reroll_hand()
			refresh())
	row.add_child(deal)
	return row


static func _verdict() -> Control:
	var coherent := Game.draft_coherent()
	var ink: Color = Style.OK_GREEN if coherent else Style.WARN
	var well := Dialog.well(10)
	well.custom_minimum_size.x = 300

	var col := Style.vbox(6)
	var top := Style.hbox(8)
	var mark := Icon.new(Icon.Kind.CHECK if coherent else Icon.Kind.WARNING, 15, ink)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(mark)
	top.add_child(Style.label("Checkable" if coherent else "Uncheckable", Style.ui_b, 14, ink))
	col.add_child(top)

	col.add_child(Style.body(
		"Subject and object belong together, so somebody can look it up."
			if coherent else
		"Nothing connects these two, so nothing can disprove it.",
		Style.ui_r, 12, Style.INK_SOFT, 3
	))
	col.add_child(Style.hline())
	col.add_child(_readout(
		"reach", "x%.2f" % (Data.COHERENT_REACH if coherent else Data.ABSURD_REACH), ink
	))
	col.add_child(_readout(
		"eyes on you",
		"x%.2f" % (Data.COHERENT_SUSPICION if coherent else Data.ABSURD_SUSPICION),
		Style.INK_SOFT
	))
	well.add_child(col)
	return well


static func _projection() -> Control:
	var well := Dialog.well(10)
	var col := Style.vbox(6)
	col.add_child(_readout(
		"Projected reach",
		Game.commas(Game.comment_reach() if is_reply() else Game.projected_reach()),
		Style.HOT
	))
	col.add_child(_readout(
		"Payout",
		"+£%s" % Game.commas(int(round(
			Game.projected_payout() * (Data.COMMENT_IMPACT if is_reply() else 1.0)
		))),
		Style.OK_GREEN
	))

	var matched := Game.matched_trends()
	col.add_child(_readout(
		"Trends caught", "%d of %d" % [matched, Game.draft_tags().size()],
		Style.ALARM if matched > 0 else Style.INK_SOFT
	))

	if Game.goodwill() > 0.0:
		col.add_child(_readout(
			"Goodwill", "+%d%%" % int(round(Game.goodwill() * 100.0)), Style.OK_GREEN
		))

	var added := Game.projected_suspicion()
	var susp_text := "none"
	if added > 0.0:
		susp_text = "+%d" % int(round(added))
	elif added < 0.0:
		susp_text = "%d" % int(round(added))
	col.add_child(_readout(
		"Suspicion", susp_text,
		Style.ALARM if added > 0.0 else (Style.OK_GREEN if added < 0.0 else Style.INK_SOFT)
	))

	if Game.throttle() < 0.999:
		col.add_child(Style.body(
			"Reach limited to %d%% while the trust team is looking at you."
				% int(Game.throttle() * 100.0),
			Style.ui_r, 11, Style.ALARM, 3
		))
	well.add_child(col)
	return well


static func _readout(key: String, value: String, ink: Color) -> Control:
	var row := Style.hbox(10)
	row.add_child(Style.label(key, Style.ui_r, 14, Style.INK_SOFT))
	row.add_child(Style.grow())
	row.add_child(Style.num(value, 14, ink))
	return row
