class_name PostCard
extends RefCounted

static func build(post: Dictionary, mine: bool, preview: bool = false) -> Control:
	var charged: bool = bool(post.get("charged", false))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 0, 0, 0, 0)
	)

	var outer := Style.hbox(0)
	panel.add_child(outer)

	var stripe := ColorRect.new()
	stripe.color = Style.ALARM if charged else (Style.HOT if mine else Style.SURFACE)
	stripe.custom_minimum_size.x = 4
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(stripe)

	var col := Style.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(Style.margins(col, 11, 10, 11, 11))

	col.add_child(_byline(post, mine, preview))
	col.add_child(Style.spacer(9))
	col.add_child(Style.body(
		String(post["text"]), Style.ui_m, 16, Style.ALARM if charged else Style.INK, 5
	))

	var tags: Array = post.get("tags", [])
	if tags.size() > 0:
		col.add_child(Style.spacer(8))
		col.add_child(_tag_row(tags))

	col.add_child(Style.spacer(10))
	col.add_child(Style.hline())
	col.add_child(Style.spacer(7))
	col.add_child(_stats(post, mine, preview))

	for c: Dictionary in post.get("comments", []):
		col.add_child(Style.spacer(8))
		col.add_child(_comment(c))
	return panel


static func _byline(post: Dictionary, mine: bool, preview: bool) -> Control:
	var row := Style.hbox(9)
	var name := ""
	var handle := ""
	if mine:
		row.add_child(Avatar.player(30))
		name = Game.handle
		handle = Game.handle
	else:
		var acc: Dictionary = post["acc"]
		row.add_child(Avatar.for_account(acc, 30))
		name = String(acc["n"])
		handle = String(acc["h"])

	var meta := Style.vbox(1)
	meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(Style.label(name, Style.ui_b, 15, Style.INK))
	meta.add_child(Style.label("@" + handle, Style.ui_r, 13, Style.INK_FAINT))
	row.add_child(meta)

	var stamp: Label = Style.label("preview", Style.ui_r, 12, Style.INK_FAINT) if preview 		else Style.live(
			func() -> String: return Game.stamp(float(post.get("at", Game.elapsed))),
			Style.ui_r, 12, Style.INK_FAINT
		)
	stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(stamp)
	return row


static func _tag_row(tags: Array) -> Control:
	var row := Style.hbox(9)
	for t: String in tags:
		var hot := Game.is_trending(t)
		var chip := Style.hbox(4)
		if hot:
			var f := SpriteAnim.make("fire", 14.0)
			f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			chip.add_child(f)
		chip.add_child(Style.label(t, Style.ui_m, 13, Style.ALARM if hot else Style.HOT))
		row.add_child(chip)
	return row


static func _stats(post: Dictionary, mine: bool, preview: bool) -> Control:
	var row := Style.hbox(14)
	if mine or preview:
		row.add_child(_stat("heart", post, "likes"))
		row.add_child(_stat("comment", post, "replies"))
		row.add_child(_stat("fire", post, "fire"))
	else:
		row.add_child(_act(post, "heart", "likes", Game.has_liked(post), Game.like_post))
		if Game.comments_open():
			row.add_child(_act(post, "comment", "replies", Game.has_commented(post), Composer.reply_to))
		else:
			row.add_child(_stat("comment", post, "replies"))
		row.add_child(_act(post, "fire", "fire", Game.has_fired(post), Game.fire_post))

	row.add_child(Style.grow())

	if post.has("t_gained") and not preview:
		row.add_child(Style.live_num(
			func() -> String: return "+%s" % Game.compact(int(post["gained"])),
			12, Style.OK_GREEN
		))
		row.add_child(Style.live(
			func() -> String:
				return "" if float(post.get("progress", 0.0)) >= Data.ENGAGEMENT_DONE 					else "still going",
			Style.ui_r, 11, Style.INK_FAINT
		))
	return row


static func _comment(c: Dictionary) -> Control:
	var well := Dialog.well(9)
	var col := Style.vbox(5)

	var head := Style.hbox(7)
	head.add_child(Avatar.player(20))
	head.add_child(Style.label("@" + Game.handle, Style.ui_b, 12, Style.HOT))
	head.add_child(Style.grow())
	head.add_child(Style.num("reply", 9, Style.INK_FAINT))
	col.add_child(head)

	col.add_child(Style.body(String(c["text"]), Style.ui_r, 13, Style.INK, 3))

	var stats := Style.hbox(12)
	stats.add_child(_stat("heart", c, "likes"))
	stats.add_child(_stat("fire", c, "fire"))
	stats.add_child(Style.grow())
	stats.add_child(Style.live_num(
		func() -> String: return "+%s" % Game.compact(int(c.get("gained", 0))),
		11, Style.OK_GREEN
	))
	col.add_child(stats)

	well.add_child(col)
	return Style.margins(well, 26, 0, 0, 0)


static func _act(
	post: Dictionary, kind: String, key: String, done: bool, action: Callable
) -> Control:
	var t := Tappable.new(Vector4(6, 3, 8, 4), Tappable.Look.ACTION)
	t.name = "act_" + kind
	t.set_enabled(not done)

	var row := Style.hbox(5)
	var art := SpriteAnim.make(kind, 14.0)
	row.add_child(art)
	row.add_child(Style.live_num(
		func() -> String: return Game.compact(int(post.get(key, 0))), 10,
		Style.ALARM if done else Style.INK_SOFT
	))
	t.add_content(row)
	if not done:
		t.pressed.connect(func() -> void:
			art.pop()
			action.call(post))
	return t


static func _stat(kind: String, post: Dictionary, key: String) -> Control:
	var box := Style.hbox(5)
	var running := float(post.get("progress", 1.0)) < Data.ENGAGEMENT_DONE
	box.add_child(SpriteAnim.make(kind, 14.0, running))
	box.add_child(Style.live_num(
		func() -> String: return Game.compact(int(post.get(key, 0))), 10, Style.INK_SOFT
	))
	return box
