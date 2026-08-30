class_name LeftColumn
extends RefCounted

static func build() -> Control:
	var col := Style.vbox(0)
	col.add_child(_identity())
	col.add_child(Style.spacer(12))
	col.add_child(Style.hline())
	col.add_child(Style.spacer(10))
	col.add_child(_stats())
	col.add_child(Style.spacer(16))

	col.add_child(_new_post_button())
	if Game.store_open():
		col.add_child(Style.spacer(6))
		col.add_child(_store_button())
	col.add_child(Style.spacer(8))
	var used := Style.num(
		"%d of %d posts used today" % [Game.posts_today, Game.posts_per_day()], 10, Style.INK_SOFT
	)
	used.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	used.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(used)
	col.add_child(Style.spacer(20))

	col.add_child(Style.group(
		"Under review" if Game.prologue else "Objective",
		_ousting() if Game.prologue else _objective()
	))
	col.add_child(Style.spacer(18))
	col.add_child(Style.group("Active Posts", _topic_board()))
	col.add_child(Style.spacer(18))
	col.add_child(Style.group("Standing", _standing()))
	col.add_child(Style.spacer(10))
	return col


static func _identity() -> Control:
	var row := Style.hbox(10)
	row.add_child(Avatar.player(44))
	var meta := Style.vbox(1)
	meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta.add_child(Style.label(Game.handle, Style.ui_b, 18, Style.INK))
	meta.add_child(Style.label("@" + Game.handle, Style.ui_r, 13, Style.INK_FAINT))
	meta.add_child(Style.label(Game.title(), Style.ui_m, 12, Style.HOT))
	row.add_child(meta)
	return row


static func _stats() -> Control:
	var col := Style.vbox(5)
	col.add_child(_sprite_line(
		"follower", func() -> String: return Game.commas(Game.followers), "followers"
	))
	col.add_child(_stat_line(
		Icon.Kind.CHECK, func() -> String: return str(Game.following.size()), "following"
	))
	col.add_child(_sprite_line(
		"heart", func() -> String: return Game.commas(_total_likes()), "likes"
	))
	col.add_child(_sprite_line(
		"money", func() -> String: return "£%s" % Game.commas(int(Game.payout)), "payout"
	))
	return col


static func _store_button() -> Control:
	var t := Tappable.new(Vector4(14, 8, 14, 9))
	var l := Style.label("Speech Fragment Store", Style.ui_m, 14, Style.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_content(l)
	t.pressed.connect(Store.open)
	return t


static func _sprite_line(kind: String, value: Callable, label: String) -> Control:
	var row := Style.hbox(8)
	row.add_child(SpriteAnim.make(kind, 17.0))
	row.add_child(Style.live_num(value, 14, Style.INK))
	row.add_child(Style.label(label, Style.ui_r, 15, Style.INK_SOFT))
	return row


static func _stat_line(kind: Icon.Kind, value: Callable, label: String) -> Control:
	var row := Style.hbox(8)
	var ic := Icon.new(kind, 15, Style.HOT)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	row.add_child(Style.live_num(value, 14, Style.INK))
	row.add_child(Style.label(label, Style.ui_r, 15, Style.INK_SOFT))
	return row


static func _total_likes() -> int:
	var n := 0
	for p: Dictionary in Game.my_posts:
		n += int(p.get("likes", 0))
	return n


static func _topic_board() -> Control:
	var col := Style.vbox(6)
	var most := 1
	for id: String in Data.TOPIC_ORDER:
		most = maxi(most, _count(id))

	for id: String in Data.TOPIC_ORDER:
		var mine := _count(id)
		var row := Style.hbox(8)

		var name := Style.label(String(Data.TOPICS[id]["tag"]), Style.ui_r, 14, Style.INK_SOFT)
		name.custom_minimum_size.x = 104
		row.add_child(name)

		var share := float(mine) / float(most)
		var heat: float = maxf(
			share, 0.95 if Game.is_trending(String(Data.TOPICS[id]["tag"])) else 0.22
		)
		row.add_child(Meter.new(clampf(heat, 0.0, 1.0), Style.topic_color(id), 0, 14))

		var count := Style.num(str(mine), 12, Style.INK)
		count.custom_minimum_size.x = 22
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count)
		col.add_child(row)
	return col


static func _count(topic: String) -> int:
	var n := 0
	for p: Dictionary in Game.my_posts:
		if p.get("topic", "") == topic:
			n += 1
	return n


static func _new_post_button() -> Control:
	var live := Game.can_post()
	var t := Tappable.new(Vector4(16, 11, 16, 12))
	var l := Style.label(
		"New Post..." if live else "Come back tomorrow", Style.ui_b, 17 if live else 14,
		Style.INK if live else Style.INK_FAINT
	)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_content(l)
	t.set_enabled(live)
	if live:
		t.pressed.connect(Composer.open)
	return t


static func _objective() -> Control:
	var target: Dictionary = Game.objective()
	var col := Style.vbox(7)
	var head := Style.label(String(target["label"]), Style.ui_b, 15, Style.HOT)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(head)

	var rank := Style.label(String(target["title"]), Style.ui_r, 12, Style.INK_FAINT)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(rank)
	col.add_child(Meter.new(Game.objective_progress(), Style.BAR_FILL, 0, 18).follow(
		func() -> float: return Game.objective_progress()
	))
	var note := Style.body(String(target["note"]), Style.ui_r, 13, Style.INK_SOFT, 4)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	return col


static func _ousting() -> Control:
	var col := Style.vbox(6)
	col.add_child(Style.label("Two strikes", Style.ui_b, 16, Style.ALARM))
	col.add_child(Style.body(
		"There is no appeal, no notification and no number you were ever shown. "
		+ "You have one post left.",
		Style.ui_r, 12, Style.INK_SOFT, 4
	))
	return col


static func _standing() -> Control:
	var high := Game.suspicion >= 50.0
	var col := Style.vbox(7)

	var top := Style.hbox(8)
	var eye := Icon.new(Icon.Kind.EYE, 15, Style.ALARM if high else Style.INK_SOFT)
	eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(eye)
	top.add_child(Style.label("Suspicion", Style.ui_r, 15, Style.INK_SOFT))
	top.add_child(Style.grow())
	top.add_child(Style.live_num(
		func() -> String: return "%d / %d" % [int(Game.suspicion), int(Data.SUSPICION_LIMIT)],
		13, Style.ALARM if high else Style.INK
	))
	col.add_child(top)
	col.add_child(Meter.new(
		Game.suspicion / Data.SUSPICION_LIMIT, Style.ALARM if high else Style.BAR_FILL, 0, 18
	).follow(func() -> float: return Game.suspicion / Data.SUSPICION_LIMIT))
	col.add_child(Style.num(
		"strike %d of %d" % [Game.strikes, Data.STRIKES_ALLOWED], 10, Style.INK_SOFT
	))
	col.add_child(Style.spacer(2))
	col.add_child(Style.live(
		_read_the_room, Style.ui_r, 12, Style.INK_SOFT, 0
	))
	return col


static func _read_the_room() -> String:
	var s := Game.suspicion
	var limit := Data.SUSPICION_LIMIT

	if Game.strikes >= Data.STRIKES_ALLOWED - 1:
		return "one more and there is no account."
	if s >= limit * 0.85:
		return "somebody is reading your posts twice."
	if s >= limit * 0.6:
		return "your reach is being quietly limited."
	if s >= limit * 0.35:
		return "you have been added to a list somewhere."

	if Game.heat_per_second() > Game.cooling_per_second():
		return "whatever you have running is being noticed."
	if s > 0.0:
		return "it is going down faster than you are adding to it."
	return "nobody is looking at you yet."


static func _day_note() -> Control:
	return Style.label(
		"today runs %s" % Game.duration(Game.day_length()), Style.ui_r, 12, Style.INK_SOFT
	)
