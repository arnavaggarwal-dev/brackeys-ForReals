class_name CenterColumn
extends RefCounted

static func build() -> Control:
	var col := Style.vbox(11)

	if Game.feed.is_empty() and Game.my_posts.is_empty():
		col.add_child(Style.spacer(40))
		col.add_child(_waiting())
		return col

	var today := _mine_on(Game.day)
	if today.is_empty():
		col.add_child(_last_words() if Game.prologue else _nothing_yet())
		col.add_child(Style.spacer(6))
	else:
		col.add_child(Style.section("TODAY", Style.HOT))
		for post: Dictionary in today:
			col.add_child(PostCard.build(post, true))
		col.add_child(Style.spacer(8))

	col.add_child(Style.section("THE FEED"))
	if Game.feed.is_empty():
		col.add_child(_empty_feed())
	for post: Dictionary in Game.feed:
		col.add_child(PostCard.build(post, false))

	var yesterday := _mine_on(Game.day - 1)
	if not yesterday.is_empty():
		col.add_child(Style.spacer(10))
		col.add_child(Style.section("YESTERDAY", Style.HOT))
		for post: Dictionary in yesterday:
			col.add_child(PostCard.build(post, true))

	col.add_child(Style.spacer(10))
	return col


static func _mine_on(day: int) -> Array:
	return Game.my_posts.filter(func(p: Dictionary) -> bool: return int(p["day"]) == day)


const LOADER_PX := 96.0
const LOADER_BIG := 2.3 * 1.2

static func _waiting() -> Control:
	var col := Style.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_loader(LOADER_PX))
	col.add_child(_empty_feed())
	return col


static func _loader(px: float) -> Control:
	var art := SpriteAnim.make("loading", px)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return art


static func _empty_feed() -> Control:
	var out := Style.vbox(0)
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var well := Dialog.well(14)
	var col := Style.vbox(6)
	col.add_child(Style.label("You do not follow anybody.", Style.ui_b, 15, Style.INK))
	col.add_child(Style.body(
		"The feed is empty until you follow somebody. Suggestions are on the right - "
		+ "but every one of them costs you part of the day you were going to post in.",
		Style.ui_r, 13, Style.INK_SOFT, 4
	))
	well.add_child(col)
	out.add_child(well)

	out.add_child(Style.spacer(28))
	out.add_child(_loader(LOADER_PX * LOADER_BIG))
	return out


static func _last_words() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", Style.box(Style.ALARM_WASH, BevelBox.Style3D.RAISED, 16, 14, 16, 16)
	)
	var row := Style.hbox(14)
	var glyph := Icon.new(Icon.Kind.WARNING, 32, Style.ALARM)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)

	var col := Style.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(Style.label(
		"Everyone is already talking about you.", Style.ui_b, 17, Style.INK
	))
	col.add_child(Style.body(
		"Nine million people follow this account and not one of these posts is "
		+ "from somebody who does. Say something. It is the only move you have.",
		Style.ui_r, 14, Style.INK_SOFT, 5
	))
	row.add_child(col)
	panel.add_child(row)
	return panel


static func _nothing_yet() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 16, 14, 16, 16)
	)
	var row := Style.hbox(14)
	var glyph := Icon.new(Icon.Kind.SPEECH, 32, Style.HOT)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)

	var col := Style.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(Style.label("Nothing here yet.", Style.ui_b, 17, Style.INK))
	col.add_child(Style.body(
		"You get one post a day, and today runs %s. Following somebody costs you "
			% Game.duration(Game.day_length())
		+ "whatever you lose reading their posts, today and only today.",
		Style.ui_r, 14, Style.INK_SOFT, 5
	))
	row.add_child(col)
	panel.add_child(row)
	return panel
